/**
 * Class    : PaymentReconciliationHandler
 * Called by: PaymentReconciliationTrigger on Commission_Record__c (after insert)
 *
 * Reconciliation Match Key:
 *   Policy Number + Payment Period + Agent NPN
 *
 * Agent NPN is stored on Contact.NPN__c.
 *
 * Estimated records:
 *   - Policy_Number__c
 *   - Payment_Period__c       -> YYYY-MM
 *   - Agent__c                -> Contact lookup
 *   - Contact.NPN__c          -> Agent NPN
 *   - Status__c = Estimated
 *   - Gross_Amount__c
 *
 * Payment records:
 *   - Policy_Number__c
 *   - Compensation_Month__c   -> source value such as Aug-26
 *   - Paid_NPN__c             -> paying Agent NPN
 *   - Gross_Amount__c
 *   - Status__c is blank on import, BUT Commission_Record__c.Status__c has a
 *     field-level default of 'Estimated' in this org, so it is never
 *     actually null by the time this trigger runs (field defaults apply
 *     before after-insert triggers fire). Payment rows must therefore be
 *     identified by Compensation_Month__c != null instead of Status__c ==
 *     null — confirmed via live test against real reimported payment
 *     records, which showed Status__c = 'Estimated' despite no Status
 *     column existing anywhere in the payment import mapping.
 *   - Payment_Period__c is derived and set by
 *     CommissionRecordTriggerHandler.beforeSave (before-insert, on
 *     Trigger.new directly) from Compensation_Month__c — this handler
 *     just reads it, it does not derive or write it.
 *
 * No-Estimated-found behavior (per client, 27-Aug): a standalone payment
 * with no matching Estimated record is treated as final on its own —
 * Status__c is set to Reconciled directly on the payment record, AND the
 * No_Matching_Estimate exception is still logged (both happen together,
 * not one or the other). This applies to every "no match" branch below:
 * NPN not found in Salesforce, blank Policy Number/Period, and no
 * Estimated record found for the resolved key.
 *
 * Reconciliation key:
 *
 *   Policy Number + normalized Payment Period + NPN
 *
 * Example:
 *
 *   Policy Number = POL123
 *   Payment Period = 2026-08
 *   NPN = 123456789
 *
 *   Key:
 *   POL123_2026-08_123456789
 */
public without sharing class PaymentReconciliationHandler {

    private static final String STATUS_ESTIMATED  = 'Estimated';
    private static final String STATUS_RECONCILED = 'Reconciled';

    private static final String EXCEPTION_UNDERPAID            = 'Underpaid';
    private static final String EXCEPTION_OVERPAID             = 'Overpaid';
    private static final String EXCEPTION_NO_MATCHING_ESTIMATE = 'No_Matching_Estimate';


    public static void handleAfterInsert(List<Commission_Record__c> newRecords) {

        /*
         * Payment records are identified by Compensation_Month__c != null.
         *
         * NOT by Status__c == null — Status__c defaults to 'Estimated' at
         * the field level in this org, so it is never actually blank on
         * insert. Compensation_Month__c is only ever populated by the
         * payment-transactions import, confirmed via the real Data Loader
         * mapping files, so it's a reliable gate.
         */
        List<Commission_Record__c> paymentRows =
            new List<Commission_Record__c>();

        for (Commission_Record__c cr : newRecords) {
            if (cr.Compensation_Month__c != null) {
                paymentRows.add(cr);
            }
        }

        if (paymentRows.isEmpty()) {
            return;
        }


        /*
         * ---------------------------------------------------------------
         * STEP 1: Collect Payment NPNs
         *
         * Paid_NPN__c contains the NPN from the payment source file.
         * Contact.NPN__c is the Salesforce field that identifies the Agent.
         * ---------------------------------------------------------------
         */
        Set<String> paymentNpns = new Set<String>();

        for (Commission_Record__c payment : paymentRows) {

            String npn = normalizeNpn(payment.Paid_NPN__c);

            if (!String.isBlank(npn)) {
                paymentNpns.add(npn);
            }
        }


        /*
         * ---------------------------------------------------------------
         * STEP 2: Resolve Payment NPN -> Contact
         *
         * This validates that the incoming NPN exists in Salesforce.
         *
         * Contact.NPN__c is the authoritative NPN field.
         * ---------------------------------------------------------------
         */
        Map<String, Contact> contactByNpn =
            new Map<String, Contact>();

        if (!paymentNpns.isEmpty()) {

            for (Contact c : [
                SELECT Id, NPN__c
                FROM Contact
                WHERE NPN__c IN :paymentNpns
            ]) {

                String npn = normalizeNpn(c.NPN__c);

                if (!String.isBlank(npn)) {
                    contactByNpn.put(npn, c);
                }
            }
        }


        /*
         * ---------------------------------------------------------------
         * STEP 3: Collect Policy Numbers and Agent Contact IDs
         *
         * Agent__c on Estimated records is a Contact lookup.
         * We use the Contact only to retrieve Contact.NPN__c.
         * ---------------------------------------------------------------
         */
        Set<String> policyNumbers = new Set<String>();
        Set<Id> agentIds = new Set<Id>();

        for (Commission_Record__c payment : paymentRows) {

            if (!String.isBlank(payment.Policy_Number__c)) {
                policyNumbers.add(payment.Policy_Number__c);
            }

            String paymentNpn =
                normalizeNpn(payment.Paid_NPN__c);

            Contact agentContact =
                contactByNpn.get(paymentNpn);

            if (agentContact != null) {
                agentIds.add(agentContact.Id);
            }
        }


        /*
         * ---------------------------------------------------------------
         * STEP 4: Query Estimated Records
         *
         * We retrieve the Estimated records that could potentially match.
         *
         * The final matching key uses:
         *
         * Policy Number + Payment Period + Contact.NPN__c
         * ---------------------------------------------------------------
         */
        Map<String, Commission_Record__c> estimatedByKey =
            new Map<String, Commission_Record__c>();

        if (!policyNumbers.isEmpty() && !agentIds.isEmpty()) {

            List<Commission_Record__c> estimatedRecords = [
                SELECT
                    Id,
                    Policy_Number__c,
                    Payment_Period__c,
                    Agent__c,
                    Agent__r.NPN__c,
                    Gross_Amount__c
                FROM Commission_Record__c
                WHERE Status__c = :STATUS_ESTIMATED
                AND Policy_Number__c IN :policyNumbers
                AND Agent__c IN :agentIds
            ];


            /*
             * Build the Estimated record key using NPN,
             * NOT Contact Id.
             */
            for (Commission_Record__c est : estimatedRecords) {

                String estimatedNpn = null;

                if (est.Agent__r != null) {
                    estimatedNpn =
                        normalizeNpn(est.Agent__r.NPN__c);
                }

                if (String.isBlank(est.Policy_Number__c)
                    || String.isBlank(est.Payment_Period__c)
                    || String.isBlank(estimatedNpn)) {

                    continue;
                }

                String key = buildMatchKey(
                    est.Policy_Number__c,
                    est.Payment_Period__c,
                    estimatedNpn
                );

                /*
                 * If the same key appears more than once,
                 * keep the first record instead of silently replacing it.
                 *
                 * Ideally Policy + Period + NPN should uniquely identify
                 * an Estimated record.
                 */
                if (!estimatedByKey.containsKey(key)) {
                    estimatedByKey.put(key, est);
                }
            }
        }


        /*
         * ---------------------------------------------------------------
         * STEP 5: Match Payment Records
         * ---------------------------------------------------------------
         */
        List<Commission_Record__c> toReconcile =
            new List<Commission_Record__c>();

        List<Commission_Exception__c> exceptions =
            new List<Commission_Exception__c>();


        for (Commission_Record__c payment : paymentRows) {

            /*
             * Payment NPN comes from Paid_NPN__c.
             *
             * Validate it against Contact.NPN__c.
             */
            String paymentNpn =
                normalizeNpn(payment.Paid_NPN__c);

            if (String.isBlank(paymentNpn)
                || !contactByNpn.containsKey(paymentNpn)) {

                exceptions.add(
                    buildException(
                        payment.Id,
                        EXCEPTION_NO_MATCHING_ESTIMATE
                    )
                );

                toReconcile.add(
                    new Commission_Record__c(
                        Id = payment.Id,
                        Status__c = STATUS_RECONCILED
                    )
                );

                continue;
            }


            /*
             * Payment source contains Compensation_Month__c
             * such as:
             *
             * Aug-26
             *
             * Estimated record contains Payment_Period__c:
             *
             * 2026-08
             *
             * Normalize both before comparison.
             */
            String paymentPeriod =
                normalizePeriod(payment.Compensation_Month__c);


            if (String.isBlank(payment.Policy_Number__c)
                || String.isBlank(paymentPeriod)) {

                exceptions.add(
                    buildException(
                        payment.Id,
                        EXCEPTION_NO_MATCHING_ESTIMATE
                    )
                );

                toReconcile.add(
                    new Commission_Record__c(
                        Id = payment.Id,
                        Status__c = STATUS_RECONCILED
                    )
                );

                continue;
            }


            /*
             * IMPORTANT:
             *
             * Actual reconciliation key:
             *
             * Policy Number
             * +
             * Payment Period
             * +
             * NPN
             */
            String paymentKey = buildMatchKey(
                payment.Policy_Number__c,
                paymentPeriod,
                paymentNpn
            );


            Commission_Record__c matched =
                estimatedByKey.get(paymentKey);


            /*
             * No Estimated record found. Payment stands on its own —
             * set it to Reconciled directly, and still log the
             * exception per client decision (27-Aug): both happen
             * together, this isn't an either/or.
             */
            if (matched == null) {

                exceptions.add(
                    buildException(
                        payment.Id,
                        EXCEPTION_NO_MATCHING_ESTIMATE
                    )
                );

                toReconcile.add(
                    new Commission_Record__c(
                        Id = payment.Id,
                        Status__c = STATUS_RECONCILED
                    )
                );

                continue;
            }


            /*
             * -----------------------------------------------------------
             * STEP 6: Compare Gross Amount
             * -----------------------------------------------------------
             */
            Decimal estimatedAmount =
                matched.Gross_Amount__c;

            Decimal paymentAmount =
                payment.Gross_Amount__c;


            /*
             * Exact match
             */
            if (estimatedAmount == paymentAmount) {

                toReconcile.add(
                    new Commission_Record__c(
                        Id = matched.Id,
                        Status__c = STATUS_RECONCILED
                    )
                );
            }

            /*
             * Payment is lower than estimate
             */
            else if (paymentAmount < estimatedAmount) {

                exceptions.add(
                    buildException(
                        payment.Id,
                        EXCEPTION_UNDERPAID
                    )
                );
            }

            /*
             * Payment is higher than estimate
             */
            else {

                exceptions.add(
                    buildException(
                        payment.Id,
                        EXCEPTION_OVERPAID
                    )
                );
            }
        }


        /*
         * ---------------------------------------------------------------
         * STEP 7: DML
         * ---------------------------------------------------------------
         */
        if (!toReconcile.isEmpty()) {
            update toReconcile;
        }

        if (!exceptions.isEmpty()) {
            insert exceptions;
        }
    }


    /*
     * ====================================================================
     * MATCH KEY
     * ====================================================================
     *
     * Policy Number + Payment Period + NPN
     *
     * Example:
     *
     * POL123_2026-08_123456789
     */
    private static String buildMatchKey(
        String policyNumber,
        String paymentPeriod,
        String npn
    ) {

        return String.valueOf(policyNumber).trim()
            + '_'
            + String.valueOf(normalizePeriod(paymentPeriod)).trim()
            + '_'
            + String.valueOf(normalizeNpn(npn)).trim();
    }


    /*
     * ====================================================================
     * NPN NORMALIZATION
     * ====================================================================
     *
     * Contact.NPN__c is the authoritative Salesforce NPN field.
     *
     * Trim whitespace so values such as:
     *
     * "123456789"
     * " 123456789 "
     *
     * are treated as the same NPN.
     */
    private static String normalizeNpn(String rawNpn) {

        if (String.isBlank(rawNpn)) {
            return null;
        }

        return rawNpn.trim();
    }


    /*
     * ====================================================================
     * PAYMENT PERIOD NORMALIZATION
     * ====================================================================
     *
     * Supported formats:
     *
     * YYYY-MM
     * Aug-26
     * Aug      (no year - current year is applied automatically)
     *
     * Example:
     *
     * Aug-26 -> 2026-08
     * 2026-08 -> 2026-08
     * Aug     -> <current year>-08   (e.g. 2026-08 when run in 2026)
     */
    private static final Map<String, String> MONTH_ABBREV_TO_NUMBER =
        new Map<String, String>{
            'Jan' => '01',
            'Feb' => '02',
            'Mar' => '03',
            'Apr' => '04',
            'May' => '05',
            'Jun' => '06',
            'Jul' => '07',
            'Aug' => '08',
            'Sep' => '09',
            'Oct' => '10',
            'Nov' => '11',
            'Dec' => '12'
        };


    private static String normalizePeriod(String rawPeriod) {

        if (String.isBlank(rawPeriod)) {
            return null;
        }

        rawPeriod = rawPeriod.trim();


        /*
         * Already YYYY-MM
         */
        if (Pattern.matches(
            '^\\d{4}-\\d{2}$',
            rawPeriod
        )) {

            return rawPeriod;
        }


        /*
         * Convert MMM-YY -> YYYY-MM
         *
         * Example:
         * Aug-26 -> 2026-08
         */
        if (Pattern.matches(
            '^[A-Za-z]{3}-\\d{2}$',
            rawPeriod
        )) {

            String monthAbbrev =
                rawPeriod.substringBefore('-');

            String twoDigitYear =
                rawPeriod.substringAfter('-');

            String normalizedMonth =
                monthAbbrev.substring(0, 1).toUpperCase()
                + monthAbbrev.substring(1).toLowerCase();

            String monthNumber =
                MONTH_ABBREV_TO_NUMBER.get(normalizedMonth);

            if (monthNumber != null) {

                return '20'
                    + twoDigitYear
                    + '-'
                    + monthNumber;
            }
        }


        /*
         * Convert MMM -> YYYY-MM using the current year
         *
         * Example (run in 2026):
         * Aug -> 2026-08
         */
        if (Pattern.matches(
            '^[A-Za-z]{3}$',
            rawPeriod
        )) {

            String normalizedMonth =
                rawPeriod.substring(0, 1).toUpperCase()
                + rawPeriod.substring(1).toLowerCase();

            String monthNumber =
                MONTH_ABBREV_TO_NUMBER.get(normalizedMonth);

            if (monthNumber != null) {

                return Date.today().year()
                    + '-'
                    + monthNumber;
            }
        }


        /*
         * Unknown format.
         *
         * Do not guess.
         */
        return rawPeriod;
    }


    /*
     * ====================================================================
     * EXCEPTION BUILDER
     * ====================================================================
     */
    private static Commission_Exception__c buildException(
        Id commissionRecordId,
        String exceptionType
    ) {

        Commission_Exception__c ex =
            new Commission_Exception__c();

        ex.Exception_Type__c =
            exceptionType;

        ex.Commission_Record__c =
            commissionRecordId;

        return ex;
    }
}