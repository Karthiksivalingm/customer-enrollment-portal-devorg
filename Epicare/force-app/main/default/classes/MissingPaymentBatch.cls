/**
 * MissingPaymentBatch
 * ------------------------------------------------------------------
 * Handles the one exception type that can't be trigger-driven:
 * Active Upline_Policy__c records with NO carrier CSV row at all for
 * the given Payment_Period__c.
 *
 * FIXED (v2):
 * Previously only checked Commission_Record__c existence, which meant
 * a policy whose CSV row got REJECTED (Agent Mismatch, Cancelled
 * Still Paid, Unknown Policy, Blocked Unpaid Bill) would incorrectly
 * ALSO get flagged as Missing_Payment.
 *
 * FIXED (v3):
 * Exception_Type__c is a RESTRICTED picklist. Uses the actual API
 * names with underscores.
 *
 * FIXED (v4):
 * Prevents duplicate Missing_Payment exceptions for the same
 * Upline_Policy__c + Payment_Period__c.
 *
 * IMPORTANT:
 * The duplicate key uses Upline_Policy__c.Id rather than
 * Policy_Number__c because Policy_Number__c can be blank.
 *
 * Payment_Period__c is also stored explicitly in Payload__c for
 * newly created Missing_Payment exceptions.
 */
public with sharing class MissingPaymentBatch
    implements Database.Batchable<SObject> {

    private final String paymentPeriod;

    private static final Set<String> NON_PAYMENT_STATUSES =
        new Set<String>{
            'Estimated',
            'Draft'
        };

    public MissingPaymentBatch(String paymentPeriod) {
        this.paymentPeriod = paymentPeriod;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Policy_Number__c
            FROM Upline_Policy__c
            WHERE Status__c = 'Active'
        ]);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Upline_Policy__c> scope
    ) {

        Set<Id> policyIds = new Set<Id>();
        Set<String> policyNumbers = new Set<String>();

        for (Upline_Policy__c p : scope) {

            policyIds.add(p.Id);

            if (String.isNotBlank(p.Policy_Number__c)) {
                policyNumbers.add(p.Policy_Number__c);
            }
        }

        // ============================================================
        // SIGNAL 1:
        // A real Commission_Record__c exists for this policy + period.
        //
        // Covers:
        // - Successful payments
        // - Underpaid
        // - Overpaid
        //
        // Draft and Estimated do not count as real payments.
        // ============================================================

        Set<Id> policiesWithPayment = new Set<Id>();

        for (Commission_Record__c cr : [
            SELECT Upline_Policy__c
            FROM Commission_Record__c
            WHERE Upline_Policy__c IN :policyIds
            AND Payment_Period__c = :paymentPeriod
            AND Status__c NOT IN :NON_PAYMENT_STATUSES
        ]) {

            policiesWithPayment.add(cr.Upline_Policy__c);
        }


        // ============================================================
        // SIGNAL 2:
        // A CSV row WAS received but was rejected for another reason.
        //
        // These exceptions do not create Commission_Record__c:
        // - Unknown Policy
        // - Agent Mismatch
        // - Cancelled Still Paid
        // - Blocked Unpaid Bill
        //
        // Commission_Exception__c has no direct Payment_Period__c,
        // so the period is read from Payload__c.
        // ============================================================

        Set<String> policyNumbersWithRejectedRow =
            new Set<String>();

        for (Commission_Exception__c ex : [
            SELECT Policy_Number__c, Payload__c
            FROM Commission_Exception__c
            WHERE Policy_Number__c IN :policyNumbers
            AND Exception_Type__c IN (
                'Unknown_Policy',
                'Agent_Mismatch',
                'Cancelled_Still_Paid',
                'Blocked_Unpaid_Bill'
            )
        ]) {

            if (String.isBlank(ex.Payload__c)) {
                continue;
            }

            try {

                Map<String, Object> payload =
                    (Map<String, Object>)
                    JSON.deserializeUntyped(ex.Payload__c);

                if (payload.get('Payment_Period__c') == paymentPeriod) {

                    policyNumbersWithRejectedRow.add(
                        ex.Policy_Number__c
                    );
                }

            } catch (Exception e) {

                // Malformed payload:
                // skip rather than fail the entire batch.
            }
        }


        // ============================================================
        // SIGNAL 3 - NEW:
        //
        // Check whether a Missing_Payment already exists for the same
        // Upline_Policy__c + Payment_Period__c.
        //
        // IMPORTANT:
        // We use Upline_Policy_Id from Payload__c instead of
        // Policy_Number__c because Policy_Number__c can be blank.
        //
        // We also support OLD Missing_Payment records where the
        // payment period was only stored inside the Details text.
        // ============================================================

        Set<String> existingMissingPaymentKeys =
            new Set<String>();

        for (Commission_Exception__c ex : [
            SELECT Policy_Number__c, Payload__c
            FROM Commission_Exception__c
            WHERE Exception_Type__c = 'Missing_Payment'
        ]) {

            if (String.isBlank(ex.Payload__c)) {
                continue;
            }

            try {

                Map<String, Object> payload =
                    (Map<String, Object>)
                    JSON.deserializeUntyped(ex.Payload__c);

                Object policyIdValue =
                    payload.get('Upline_Policy_Id');

                Object periodValue =
                    payload.get('Payment_Period__c');

                String existingPolicyId = null;
                String existingPeriod = null;

                if (policyIdValue != null) {
                    existingPolicyId =
                        String.valueOf(policyIdValue);
                }

                if (periodValue != null) {
                    existingPeriod =
                        String.valueOf(periodValue);
                }

                // ----------------------------------------------------
                // NEW PAYLOAD FORMAT
                //
                // Payment_Period__c is explicitly stored.
                // ----------------------------------------------------

                if (String.isNotBlank(existingPolicyId) &&
                    existingPeriod == paymentPeriod) {

                    String key =
                        existingPolicyId +
                        '|' +
                        paymentPeriod;

                    existingMissingPaymentKeys.add(key);

                    continue;
                }


                // ----------------------------------------------------
                // OLD PAYLOAD FORMAT
                //
                // Existing records created before this fix may have:
                //
                // {
                //     "Upline_Policy_Id": "...",
                //     "Details":
                //       "... Payment_Period 2026-08."
                // }
                //
                // So check the Details value as a fallback.
                // ----------------------------------------------------

                if (String.isNotBlank(existingPolicyId)) {

                    Object detailsValue =
                        payload.get('Details');

                    if (detailsValue != null) {

                        String details =
                            String.valueOf(detailsValue);

                        String expectedText =
                            'Payment_Period ' +
                            paymentPeriod +
                            '.';

                        if (details.contains(expectedText)) {

                            String key =
                                existingPolicyId +
                                '|' +
                                paymentPeriod;

                            existingMissingPaymentKeys.add(key);
                        }
                    }
                }

            } catch (Exception e) {

                // Malformed payload:
                // skip rather than fail the entire batch.
            }
        }


        // ============================================================
        // CREATE NEW MISSING_PAYMENT EXCEPTIONS
        // ============================================================

        List<Commission_Exception__c> toInsert =
            new List<Commission_Exception__c>();

        for (Upline_Policy__c p : scope) {

            Boolean hasPayment =
                policiesWithPayment.contains(p.Id);

            Boolean hasRejectedRow = false;

            if (String.isNotBlank(p.Policy_Number__c)) {

                hasRejectedRow =
                    policyNumbersWithRejectedRow.contains(
                        p.Policy_Number__c
                    );
            }


            // --------------------------------------------------------
            // IMPORTANT:
            //
            // Duplicate key is:
            //
            // Upline_Policy__c.Id + Payment Period
            //
            // NOT Policy_Number__c + Payment Period.
            //
            // This handles policies where Policy_Number__c is blank.
            // --------------------------------------------------------

            String key =
                String.valueOf(p.Id) +
                '|' +
                paymentPeriod;

            Boolean alreadyHasMissingPayment =
                existingMissingPaymentKeys.contains(key);


            // --------------------------------------------------------
            // Existing business rules remain unchanged:
            //
            // 1. No real Commission_Record__c
            // 2. No rejected CSV row
            // 3. No existing Missing_Payment
            // --------------------------------------------------------

            if (!hasPayment &&
                !hasRejectedRow &&
                !alreadyHasMissingPayment) {

                Map<String, Object> payload =
                    new Map<String, Object>{
                        'Upline_Policy_Id' => p.Id,

                        // Store the period explicitly for future
                        // duplicate detection.
                        'Payment_Period__c' => paymentPeriod,

                        'Details' =>
                            'No Commission_Record__c or CSV row of any kind found for Payment_Period '
                            + paymentPeriod
                            + '.'
                    };


                toInsert.add(
                    new Commission_Exception__c(
                        Exception_Type__c = 'Missing_Payment',
                        Policy_Number__c = p.Policy_Number__c,
                        Status__c = 'Open',
                        Payload__c = JSON.serialize(payload)
                    )
                );


                // ----------------------------------------------------
                // IMPORTANT:
                //
                // Immediately add the key so that another record in
                // the same execute() cannot create another exception
                // for the same Policy + Payment Period.
                // ----------------------------------------------------

                existingMissingPaymentKeys.add(key);
            }
        }


        // ============================================================
        // INSERT
        // ============================================================

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }


    public void finish(Database.BatchableContext bc) {
        // No post-processing required.
    }
}