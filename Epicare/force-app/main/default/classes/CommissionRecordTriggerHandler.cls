/**
 * CommissionRecordTriggerHandler
 * ------------------------------------------------------------------
 * v4: Underpaid/Overpaid corrected back to a SOFT FLAG per the original
 * spec ("Create Commission_Exception__c. Still create Commission_Record__c
 * with actual amount.") - it does NOT call addError(), unlike every other
 * check in this class. This is the only exception type that lets the row
 * save while still logging an exception. Upline_Source__c = 'Platform' is
 * now a valid, real value in this org (confirmed by client) - test policies
 * must actually have that value set for this check to fire; the picklist
 * option existing is not the same as the record's field being set to it.
 *
 * v3 changes (per client spec):
 *   - Blocked_Unpaid_Bill: new first-pass guard, Amount Paid = 0 rejects
 *     the row before any policy lookup happens at all.
 *   - Agent_Mismatch: now compares NPN text (policy.Agent__r.NPN__c vs
 *     rec.Agent__r.NPN__c) instead of Agent__c lookup Ids.
 *   - Underpaid/Overpaid match key changed from Upline_Policy__c Id to
 *     the composite business key Policy_Number__c + Payment_Period__c +
 *     Agent_Code__c (Upline_Policy__c.Agent_Code__c), matched against the
 *     same three fields on the Estimated Commission_Record__c.
 *
 * v4.1: Exception_Type__c values on the published event now use the
 * underscored Commission_Exception__c picklist API names (Blocked_Unpaid_Bill,
 * Unknown_Policy, Agent_Mismatch, Cancelled_Still_Paid, Underpaid, Overpaid)
 * instead of the earlier space-separated display labels.
 *
 * v4.2: Payment_Period__c is now derived from Compensation_Month__c
 * ("Aug-26" -> "2026-08") directly on Trigger.new at the top of beforeSave,
 * for ANY row with Compensation_Month__c populated (not just Carepoint/
 * Claro Insurance CSV rows) - Compensation_Month__c is only ever populated
 * by the payment-transactions import, confirmed via the real Data Loader
 * mapping files, so it's a reliable signal regardless of Upline_Source__c.
 * This runs before-insert on Trigger.new directly, so no extra DML/update
 * is needed and the field is already correct by the time
 * PaymentReconciliationHandler's after-insert logic reads it.
 *
 * v4.3: Administrative Fee carve-out. Compensation_Type__c = 'Administrative_fee'
 * rows are agency-level fees with NO Policy Number by design (per client,
 * seen in Claro "commissions" tab). These must skip ALL policy-dependent
 * checks entirely — not just Unknown_Policy. Agent_Mismatch and
 * Cancelled_Still_Paid both dereference the resolved `policy` variable
 * (policy.Agent__r, policy.Status__c), which is always null for these rows
 * since there's no Policy Number to resolve against — skipping only
 * Unknown_Policy and letting the loop continue would NPE on the very next
 * check. These rows still pass through Blocked_Unpaid_Bill (a real $0
 * check still makes sense for a fee) and just skip everything from
 * Unknown_Policy onward, with no exception logged since a missing policy
 * here isn't an error.
 *
 * v4.4: Added 'Allstate' to the source gate below. Client reported (via
 * Round 6 re-test) that none of the business validation checks fire for
 * Allstate imports — confirmed root cause: the gate only ever checked for
 * 'Carepoint' or 'Claro Insurance', so every Allstate row skipped straight
 * past validation regardless of data quality (tested by client both with
 * and without matching Upline_Policy__c records loaded, same result both
 * times). Nothing else in this class is Carepoint/Claro-specific — every
 * check downstream (Unknown_Policy, Agent_Mismatch, Cancelled_Still_Paid,
 * Blocked_Unpaid_Bill, the Administrative Fee carve-out) works generically
 * off Policy_Number__c / Compensation_Type__c, so adding the source here
 * should be sufficient to bring Allstate in line with the other two.
 *
 * v4.5: Agent_Mismatch referral support. On referral policies the
 * Upline_Policy__c.Agent__c is the AOR and Agent_Code__c is the selling
 * agent, and carriers pay the selling agent. A row now passes when its
 * agent's NPN matches EITHER the policy's Agent__c NPN (unchanged rule) OR
 * the NPN of the Contact whose Agent_Code__c equals the policy's
 * Agent_Code__c. A row matching neither is still rejected as before.
 *
 * Check order: Blocked_Unpaid_Bill -> Unknown_Policy -> Agent_Mismatch
 *   -> Cancelled_Still_Paid -> Payment_Flow_Mismatch (disabled) -> Underpaid/Overpaid (soft)
 *
 * ASSUMPTIONS (adjust to match your actual schema):
 *  - Upline_Policy__c.Agent_Code__c (Text) exists — the new match-key field.
 *  - Upline_Policy__c.Agent__r.NPN__c and Commission_Record__c.Agent__r.NPN__c
 *    are both reachable (Agent__c lookup on both objects points to Contact,
 *    which has NPN__c).
 *  - Estimated Commission_Record__c rows carry their own Policy_Number__c
 *    and Agent_Code__c (Text) directly, not just a Upline_Policy__c lookup
 *    — needed since the new match key is business-key based, not Id based.
 *  - Commission_Record__c.Paid_NPN__c exists (Carepoint only; blank on Claro
 *    and Allstate — per the Allstate mapping manual, Agent__c resolves via
 *    Agent_Full_Name__c on Contact, not NPN, same pattern as Claro).
 *  - Commission_Exception__c has: Exception_Type__c, Agent__c, Carrier__c,
 *    Policy_Number__c, Status__c, Payload__c (Long Text Area, JSON blob).
 *  - "Payment type" column on the Claro commissions import maps to
 *    Compensation_Type__c, with restricted picklist value 'Administrative_fee'
 *    identifying an agency-level fee row — not yet independently confirmed
 *    beyond the sample file, flag if this is actually a different field.
 */
public with sharing class CommissionRecordTriggerHandler {

    private static final String COMPENSATION_TYPE_ADMIN_FEE = 'Administrative_fee';

  public static void beforeSave(List<Commission_Record__c> newList) {

        // ---- Payment_Period__c derivation from Compensation_Month__c ----
        // Runs first, on every row, regardless of Upline_Source__c - this
        // is a before-context, so setting the field on Trigger.new here
        // is enough; no separate update DML is needed and no other
        // trigger context fires because of it.
        for (Commission_Record__c rec : newList) {
            String derivedPeriod = normalizePeriod(rec.Compensation_Month__c);
            if (!String.isBlank(derivedPeriod)) {
                rec.Payment_Period__c = derivedPeriod;
            }
        }

        // Only apply these checks to rows actually coming from the carrier
        // CSV imports. Estimated records, manual corrections, and anything
        // else created directly (not via Carepoint/Claro/Allstate Data
        // Loader import) skip validation entirely - these rules were never
        // meant for them.
        List<Commission_Record__c> csvRows = new List<Commission_Record__c>();
        for (Commission_Record__c rec : newList) {
            if (rec.Upline_Source__c == 'Carepoint'
                || rec.Upline_Source__c == 'Claro Insurance'
                || rec.Upline_Source__c == 'Allstate'
                || rec.Upline_Source__c == 'Carrier Direct') {
                csvRows.add(rec);
            }
        }
        if (csvRows.isEmpty()) return;

        // ---- Administrative Fee carve-out ----
        // These rows are agency-level fees with no Policy Number by
        // design - none of the policy-dependent checks below apply to
        // them. Split them out here so they skip Unknown_Policy,
        // Agent_Mismatch, Cancelled_Still_Paid, and Underpaid/Overpaid
        // entirely (all of which require a resolved policy). They still
        // go through Blocked_Unpaid_Bill below, since a $0 fee is still
        // worth catching.
        List<Commission_Record__c> policyRows = new List<Commission_Record__c>();
        for (Commission_Record__c rec : csvRows) {
            if (rec.Compensation_Type__c != COMPENSATION_TYPE_ADMIN_FEE) {
                policyRows.add(rec);
            }
            // Administrative Fee rows are simply left out of policyRows -
            // no addError(), no exception event, they just proceed to
            // insert normally.
        }
        if (policyRows.isEmpty()) return;

        // ---- Resolve policies for ALL csv rows first (including $0 ones) ----
        // so Blocked_Unpaid_Bill can link to Upline_Policy__c when the Policy
        // Number resolves, per spec: "Link to Upline_Policy__c if Policy_Number
        // resolves." Previously this check ran before any policy lookup, so
        // that link never happened even when the policy number was valid.
        Map<String, Upline_Policy__c> policyByNumber = queryPoliciesByNumber(policyRows);

        // ---- Blocked_Unpaid_Bill: checked first, but now with policy resolved ----
        List<Commission_Record__c> toEvaluate = new List<Commission_Record__c>();
        List<Commission_Exception_Event__e> eventsToPublish = new List<Commission_Exception_Event__e>();

        for (Commission_Record__c rec : policyRows) {
            if (rec.Gross_Amount__c == 0) {
                Upline_Policy__c matchedPolicy = policyByNumber.get(rec.Policy_Number__c);
                eventsToPublish.add(buildExceptionEvent(rec, 'Blocked_Unpaid_Bill',
                    matchedPolicy != null ? matchedPolicy.Id : null, null,
                    'Amount Paid = 0. Row rejected, no Commission_Record__c created.'));
                rec.addError('Blocked Unpaid Bill: row rejected, exception logged.');
            } else {
                toEvaluate.add(rec);
            }
        }

        Set<Id> agentIds = new Set<Id>();
        for (Upline_Policy__c p : policyByNumber.values()) {
            if (p.Agent__c != null) agentIds.add(p.Agent__c);
        }
        Map<Id, Appointment__c> appointmentByAgent = new Map<Id, Appointment__c>();
        for (Appointment__c a : [
            SELECT Id, Agent__c, Payment_Flow__c
            FROM Appointment__c
            WHERE Agent__c IN :agentIds
        ]) {
            appointmentByAgent.put(a.Agent__c, a);
        }

        Set<String> periods = new Set<String>();
        for (Commission_Record__c rec : toEvaluate) {
            if (String.isNotBlank(rec.Payment_Period__c)) periods.add(rec.Payment_Period__c);
        }
        // New composite match key: Policy_Number__c + Payment_Period__c + Agent_Code__c
        // FIXED: previously filtered this query by "Agent_Code__c IN :agentCodes",
        // built by skipping blank values - when Agent_Code__c is null on the
        // policy (as it is for policies with no linked Appointment/Agency),
        // that set ended up empty, and "IN ()" returns zero rows even when a
        // real null==null match exists. Policy_Number__c + Payment_Period__c
        // already narrows the query enough; Agent_Code__c only needs to be
        // part of the in-memory composite key below, not a hard SOQL filter.
        // NOTE: Commission_Record__c.Type__c has zero configured picklist values -
        // it's not actually used. Status__c is the real field; 'Estimated' is one
        // of its values (Draft/Estimated/Approved/Reconciled/Paid/Disputed/Written Off).
        Map<String, Commission_Record__c> estimatedByKey = new Map<String, Commission_Record__c>();
        for (Commission_Record__c est : [
            SELECT Id, Policy_Number__c, Payment_Period__c, Agent_Code__c, Expected_Amount__c
            FROM Commission_Record__c
            WHERE Policy_Number__c IN :policyByNumber.keySet()
              AND Payment_Period__c IN :periods
              AND Status__c = 'Estimated'
        ]) {
            estimatedByKey.put(est.Policy_Number__c + '|' + est.Payment_Period__c + '|' + est.Agent_Code__c, est);
        }

        // Query Contact NPNs explicitly for the incoming rows' Agent__c values.
        // rec.Agent__r.NPN__c is NOT reliable on Trigger.new records in a
        // before-insert context - it can silently return null even when
        // Agent__c is populated, which is what caused every row (including
        // correctly-matched ones) to fail Agent Mismatch.
        Set<Id> incomingAgentIds = new Set<Id>();
        for (Commission_Record__c rec : toEvaluate) {
            if (rec.Agent__c != null) incomingAgentIds.add(rec.Agent__c);
        }
        Map<Id, String> npnByContactId = new Map<Id, String>();
        for (Contact c : [SELECT Id, NPN__c FROM Contact WHERE Id IN :incomingAgentIds]) {
            npnByContactId.put(c.Id, c.NPN__c);
        }

        // Referral policies: Upline_Policy__c.Agent__c holds the AOR while
        // Agent_Code__c holds the selling agent's code. Resolve the selling
        // agent's NPN via Contact.Agent_Code__c (unique external Id) so
        // Agent_Mismatch can accept a row paid to either agent.
        Set<String> policyAgentCodes = new Set<String>();
        for (Commission_Record__c rec : toEvaluate) {
            Upline_Policy__c p = policyByNumber.get(rec.Policy_Number__c);
            if (p != null && String.isNotBlank(p.Agent_Code__c)) policyAgentCodes.add(p.Agent_Code__c);
        }
        Map<String, String> npnByAgentCode = new Map<String, String>();
        if (!policyAgentCodes.isEmpty()) {
            for (Contact c : [SELECT Agent_Code__c, NPN__c FROM Contact WHERE Agent_Code__c IN :policyAgentCodes]) {
                npnByAgentCode.put(c.Agent_Code__c.toUpperCase(), c.NPN__c);
            }
        }

        for (Commission_Record__c rec : toEvaluate) {
            Upline_Policy__c policy = policyByNumber.get(rec.Policy_Number__c);

            // Unknown_Policy ------------------------------------------------
            if (policy == null) {
                eventsToPublish.add(buildExceptionEvent(rec, 'Unknown_Policy', null, null,
                    'Policy_Number ' + rec.Policy_Number__c + ' not found in Upline_Policy__c.'));
                rec.addError('Unknown Policy: row rejected, exception logged.');
                continue;
            }

            // Agent_Mismatch — NPN comparison via explicit Contact query --------
            String policyNpn = policy.Agent__r != null ? policy.Agent__r.NPN__c : null;
            String rowNpn = rec.Agent__c != null ? npnByContactId.get(rec.Agent__c) : null;
            String sellingNpn = String.isNotBlank(policy.Agent_Code__c)
                ? npnByAgentCode.get(policy.Agent_Code__c.toUpperCase()) : null;
            Boolean matchesSellingAgent = rowNpn != null && rowNpn == sellingNpn;
            if (policyNpn != rowNpn && !matchesSellingAgent) {
                eventsToPublish.add(buildExceptionEvent(rec, 'Agent_Mismatch', policy.Id, null,
                    'NPN on CSV row (' + rowNpn + ') does not match NPN on Upline_Policy (' + policyNpn + ').'));
                rec.addError('Agent Mismatch: row rejected, exception logged.');
                continue;
            }

            // Cancelled_Still_Paid --------------------------------------------
            if (policy.Status__c == 'Cancelled') {
                eventsToPublish.add(buildExceptionEvent(rec, 'Cancelled_Still_Paid', policy.Id, null,
                    'Carrier paid on a policy with Status = Cancelled.'));
                rec.addError('Cancelled Still Paid: row rejected, exception logged.');
                continue;
            }

            // Payment_Flow_Mismatch --------------------------------------------
            // DISABLED. Appointment__c.Payment_Flow__c (Carrier_Direct/Pending/
            // Through_Epicare/Upline_Direct/Referral) is a routing CATEGORY,
            // not an NPN, so it can't be compared to Paid_NPN__c directly.
            // Commission_Record__c.ACA_Payment_Flow__c (Carrier Direct/
            // Through Epicare/Referral) looks like the intended comparison
            // field instead, per the original spec note "Paid NPN determines
            // ACA_Payment_Flow auto-derivation" — but confirm whether that
            // auto-derivation runs BEFORE this trigger fires (this is a
            // before-insert trigger; if ACA_Payment_Flow__c is set by a flow/
            // workflow that runs after insert, it won't be populated yet here).

            // Underpaid / Overpaid — Platform source ONLY, business-key match ---
            // SOFT FLAG per original spec: "Create Commission_Exception__c.
            // Still create Commission_Record__c with actual amount." This does
            // NOT call addError() - unlike every other check above, the row is
            // still allowed to save. Only the exception event is published.
            if (policy.Upline_Source__c == 'Platform') {
                String key = rec.Policy_Number__c + '|' + rec.Payment_Period__c + '|' + policy.Agent_Code__c;
                Commission_Record__c est = estimatedByKey.get(key);
                if (est != null && est.Expected_Amount__c != null && rec.Gross_Amount__c != null) {
                    if (rec.Gross_Amount__c < est.Expected_Amount__c) {
                        eventsToPublish.add(buildExceptionEvent(rec, 'Underpaid', policy.Id, est.Expected_Amount__c,
                            'Paid ' + rec.Gross_Amount__c + ' < Expected ' + est.Expected_Amount__c + '.'));
                        // no addError() - record still saves, per spec
                    } else if (rec.Gross_Amount__c > est.Expected_Amount__c) {
                        eventsToPublish.add(buildExceptionEvent(rec, 'Overpaid', policy.Id, est.Expected_Amount__c,
                            'Paid ' + rec.Gross_Amount__c + ' > Expected ' + est.Expected_Amount__c + '.'));
                        // no addError() - record still saves, per spec
                    }
                }
            }
            // Non-Platform sources: no amount comparison at all — binary
            // presence/absence only, and presence is already confirmed
            // since we're inside the loop processing this CSV row.
        }

        if (!eventsToPublish.isEmpty()) EventBus.publish(eventsToPublish);
    }

    // ---------------------------------------------------------------
    // shared helpers
    // ---------------------------------------------------------------
    private static Map<String, Upline_Policy__c> queryPoliciesByNumber(List<Commission_Record__c> recs) {
        Set<String> policyNumbers = new Set<String>();
        for (Commission_Record__c rec : recs) {
            if (String.isNotBlank(rec.Policy_Number__c)) policyNumbers.add(rec.Policy_Number__c);
        }
        Map<String, Upline_Policy__c> result = new Map<String, Upline_Policy__c>();
        for (Upline_Policy__c p : [
            SELECT Id, Policy_Number__c, Status__c, Upline_Source__c, Agent__c, Agent__r.NPN__c, Agent_Code__c
            FROM Upline_Policy__c
            WHERE Policy_Number__c IN :policyNumbers
        ]) {
            result.put(p.Policy_Number__c, p);
        }
        return result;
    }

    /**
     * Builds a Commission_Exception_Event__e instead of the Commission_Exception__c
     * record directly. The subscriber trigger (CommissionExceptionEventTrigger)
     * does the actual insert, in its own transaction, immune to this
     * transaction's rollback from addError().
     */
    private static Commission_Exception_Event__e buildExceptionEvent(
        Commission_Record__c rec, String exceptionType, Id policyId,
        Decimal expectedAmount, String details
    ) {
        Map<String, Object> payload = new Map<String, Object>{
            'Upline_Policy_Id'          => policyId,
            'Details'                   => details,
            'External_Id__c'            => rec.External_Id__c,
            'Compensation_Type__c'        => rec.Compensation_Type__c,
            'Commission_Rate__c'        => rec.Commission_Rate__c,
            'Payment_Period__c'         => rec.Payment_Period__c,
            'Payment_Date__c'           => rec.Payment_Date__c,
            'Carrier_Statement_Date__c' => rec.Carrier_Statement_Date__c,
            'Member_Count__c'           => rec.Member_Count__c,
            'Effective_Date__c'         => rec.Effective_Date__c,
            'Paid_NPN__c'               => rec.Paid_NPN__c,
            'Payee_Name__c'             => rec.Payee_Name__c,
            'Holder_Name__c'            => rec.Holder_Name__c,
            'MBI__c'                    => rec.MBI__c,
            'Activity_Type__c'          => rec.Activity_Type__c,
            'Admin_Fee__c'              => rec.Admin_Fee__c,
            'Net_Amount__c'             => rec.Net_Amount__c,
            'Notes__c'                  => rec.Notes__c,
            'Upline_Source__c'          => rec.Upline_Source__c,
            'Record_Status__c'          => rec.Status__c
        };

        return new Commission_Exception_Event__e(
            Exception_Type__c  = exceptionType,
            Policy_Number__c   = rec.Policy_Number__c,
            Agent_Id__c        = rec.Agent__c,
            Carrier_Id__c      = rec.Carrier__c,
            Expected_Amount__c = expectedAmount,
            Actual_Amount__c   = rec.Gross_Amount__c,
            Payload__c         = JSON.serialize(payload)
        );
    }

    /*
     * ====================================================================
     * PAYMENT PERIOD NORMALIZATION
     * ====================================================================
     * Same logic as PaymentReconciliationHandler.normalizePeriod — kept
     * here too since this is where it needs to run (before-insert, no
     * extra DML). Supported formats:
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

        // Already YYYY-MM
        if (Pattern.matches('^\\d{4}-\\d{2}$', rawPeriod)) {
            return rawPeriod;
        }

        // Convert MMM-YY -> YYYY-MM
        if (Pattern.matches('^[A-Za-z]{3}-\\d{2}$', rawPeriod)) {
            String monthAbbrev = rawPeriod.substringBefore('-');
            String twoDigitYear = rawPeriod.substringAfter('-');
            String normalizedMonth = monthAbbrev.substring(0, 1).toUpperCase()
                + monthAbbrev.substring(1).toLowerCase();
            String monthNumber = MONTH_ABBREV_TO_NUMBER.get(normalizedMonth);

            if (monthNumber != null) {
                return '20' + twoDigitYear + '-' + monthNumber;
            }
        }

        // Convert MMM -> YYYY-MM using the current year
        if (Pattern.matches('^[A-Za-z]{3}$', rawPeriod)) {
            String normalizedMonth = rawPeriod.substring(0, 1).toUpperCase()
                + rawPeriod.substring(1).toLowerCase();
            String monthNumber = MONTH_ABBREV_TO_NUMBER.get(normalizedMonth);

            if (monthNumber != null) {
                return Date.today().year() + '-' + monthNumber;
            }
        }

        // Unknown format. Do not guess.
        return null;
    }
}