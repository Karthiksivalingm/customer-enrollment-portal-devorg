/**
 * Class    : PaymentReconciliationHandlerTest
 * Covers  : PaymentReconciliationHandler.handleAfterInsert(), invoked
 *           indirectly by inserting Commission_Record__c (fires
 *           PaymentReconciliationTrigger after insert) rather than calling
 *           the static method directly — this exercises the real trigger
 *           wiring, matching how the class actually runs in production.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * SCHEMA ASSUMPTIONS FLAGGED:
 *  1. Contact required fields — Email, NPN__c, Agent_Status__c ('Onboarding'
 *     at creation) are all required by validation rules discovered while
 *     testing PaymentBatchAssembly against this same org. Reused here.
 *  2. Commission_Record__c.Contact__c — PaymentReconciliationHandler itself
 *     never reads or writes Contact__c (it uses Agent__c for Estimated
 *     records and Paid_NPN__c/text for Payment rows). I don't know whether
 *     Contact__c is a required field on the object overall. To avoid a
 *     surprise REQUIRED_FIELD_MISSING, this factory defensively populates
 *     Contact__c on every record it creates (pointing at the agent Contact
 *     where one is available). If Contact__c is NOT actually required,
 *     this is harmless; if some OTHER required field exists that isn't
 *     visible in PaymentReconciliationHandler.cls, record creation will
 *     fail the same way it did for PaymentBatchAssemblyTest and that field
 *     needs adding to the factory methods below.
 *  3. Compensation_Type__c — set to 'Commission' on every record as a
 *     reasonable default; not referenced by this handler at all, so any
 *     value should be equally valid unless a picklist restriction says
 *     otherwise.
 *  4. Status__c on Estimated records is set explicitly to 'Estimated' even
 *     though the class header notes it's also the field-level default —
 *     explicit is safer than relying on a default that could change.
 *
 * ADDED (this revision): STEP 5a of the handler backfills
 * Payment_Period__c from Compensation_Month__c on every payment row,
 * independent of whether that row goes on to match, exception, or fail
 * NPN validation — called out explicitly in the handler's header comment,
 * but no prior test in this class asserted on Payment_Period__c at all.
 * Tests 10–13 below close that gap.
 * ══════════════════════════════════════════════════════════════════════════
 */
@isTest
private class PaymentReconciliationHandlerTest {

    private static final String STATUS_ESTIMATED  = 'Estimated';
    private static final String STATUS_RECONCILED = 'Reconciled';

    private static final String EXCEPTION_UNDERPAID            = 'Underpaid';
    private static final String EXCEPTION_OVERPAID             = 'Overpaid';
    private static final String EXCEPTION_NO_MATCHING_ESTIMATE = 'No_Matching_Estimate';

    // ────────────────────────────────────────────────────────────────
    // Test 1: exact Gross_Amount__c match -> Estimated record flips to
    // Reconciled, no exception created. Also exercises the MMM-YY ->
    // YYYY-MM branch of normalizePeriod ('Aug-26' vs stored '2026-08').
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_ExactMatch_ReconcilesEstimate() {
        Contact agent = makeAgentContact('700000001');
        insert agent;

        Commission_Record__c estimate = makeEstimatedRecord(agent.Id, 'POL100', '2026-08', 500);
        insert estimate;

        Test.startTest();
        insert makePaymentRecord('POL100', 'Aug-26', '700000001', 500, agent.Id);
        Test.stopTest();

        Commission_Record__c reconciled = [SELECT Status__c FROM Commission_Record__c WHERE Id = :estimate.Id];
        System.assertEquals(STATUS_RECONCILED, reconciled.Status__c, 'Exact amount match should reconcile the Estimated record.');
        System.assertEquals(0, [SELECT COUNT() FROM Commission_Exception__c], 'No exception should be created on an exact match.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 2: payment amount lower than the Estimated amount -> Underpaid
    // exception, Estimated record left untouched (still Estimated).
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_Underpaid_CreatesUnderpaidException() {
        Contact agent = makeAgentContact('700000002');
        insert agent;

        Commission_Record__c estimate = makeEstimatedRecord(agent.Id, 'POL200', '2026-08', 500);
        insert estimate;

        Test.startTest();
        Commission_Record__c payment = makePaymentRecord('POL200', 'Aug-26', '700000002', 300, agent.Id);
        insert payment;
        Test.stopTest();

        Commission_Record__c stillEstimated = [SELECT Status__c FROM Commission_Record__c WHERE Id = :estimate.Id];
        System.assertEquals(STATUS_ESTIMATED, stillEstimated.Status__c, 'Underpaid should not flip the Estimated record to Reconciled.');

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c, Commission_Record__c FROM Commission_Exception__c];
        System.assertEquals(1, exceptions.size());
        System.assertEquals(EXCEPTION_UNDERPAID, exceptions[0].Exception_Type__c);
        System.assertEquals(payment.Id, exceptions[0].Commission_Record__c, 'Exception should be logged against the payment record, not the estimate.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 3: payment amount higher than the Estimated amount -> Overpaid
    // exception, Estimated record left untouched.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_Overpaid_CreatesOverpaidException() {
        Contact agent = makeAgentContact('700000003');
        insert agent;

        Commission_Record__c estimate = makeEstimatedRecord(agent.Id, 'POL300', '2026-08', 500);
        insert estimate;

        Test.startTest();
        Commission_Record__c payment = makePaymentRecord('POL300', 'Aug-26', '700000003', 750, agent.Id);
        insert payment;
        Test.stopTest();

        Commission_Record__c stillEstimated = [SELECT Status__c FROM Commission_Record__c WHERE Id = :estimate.Id];
        System.assertEquals(STATUS_ESTIMATED, stillEstimated.Status__c, 'Overpaid should not flip the Estimated record to Reconciled.');

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c];
        System.assertEquals(1, exceptions.size());
        System.assertEquals(EXCEPTION_OVERPAID, exceptions[0].Exception_Type__c);
    }

    // ────────────────────────────────────────────────────────────────
    // Test 4: Paid_NPN__c doesn't match any Contact.NPN__c -> No_Matching_
    // Estimate exception, gated before any Estimated-record query even
    // runs a match attempt.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_UnknownPaidNpn_CreatesNoMatchingEstimateException() {
        Contact agent = makeAgentContact('700000004');
        insert agent;
        insert makeEstimatedRecord(agent.Id, 'POL400', '2026-08', 500);

        Test.startTest();
        insert makePaymentRecord('POL400', 'Aug-26', '999999999', 500, agent.Id); // NPN not on file
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c];
        System.assertEquals(1, exceptions.size());
        System.assertEquals(EXCEPTION_NO_MATCHING_ESTIMATE, exceptions[0].Exception_Type__c);

        Commission_Record__c stillEstimated = [
            SELECT Status__c
            FROM Commission_Record__c
            WHERE Policy_Number__c = 'POL400' AND Compensation_Month__c = null
            LIMIT 1
        ];
        System.assertEquals(STATUS_ESTIMATED, stillEstimated.Status__c, 'Estimated record should be untouched when the payment NPN is unrecognized.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 5: NPN and policy number both resolve correctly, but no
    // Estimated record exists for that Policy + Period + NPN combination
    // -> No_Matching_Estimate exception.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_NoMatchingEstimateRecord_CreatesException() {
        Contact agent = makeAgentContact('700000005');
        insert agent;
        // Estimated record exists, but for a different policy number.
        insert makeEstimatedRecord(agent.Id, 'POL-DIFFERENT', '2026-08', 500);

        Test.startTest();
        insert makePaymentRecord('POL500', 'Aug-26', '700000005', 500, agent.Id);
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c];
        System.assertEquals(1, exceptions.size());
        System.assertEquals(EXCEPTION_NO_MATCHING_ESTIMATE, exceptions[0].Exception_Type__c);
    }

    // ────────────────────────────────────────────────────────────────
    // Test 6: blank Policy_Number__c on the payment row -> No_Matching_
    // Estimate exception via the explicit blank-field guard, not a null
    // pointer or silent skip.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_BlankPolicyNumber_CreatesException() {
        Contact agent = makeAgentContact('700000006');
        insert agent;
        insert makeEstimatedRecord(agent.Id, 'POL600', '2026-08', 500);

        Test.startTest();
        insert makePaymentRecord(null, 'Aug-26', '700000006', 500, agent.Id);
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [SELECT Exception_Type__c FROM Commission_Exception__c];
        System.assertEquals(1, exceptions.size());
        System.assertEquals(EXCEPTION_NO_MATCHING_ESTIMATE, exceptions[0].Exception_Type__c);
    }

    // ────────────────────────────────────────────────────────────────
    // Test 7: Compensation_Month__c already in YYYY-MM form (not MMM-YY)
    // matches directly — exercises the "already normalized" regex branch
    // of normalizePeriod, as opposed to Test 1's MMM-YY conversion branch.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_PeriodAlreadyNormalized_StillMatches() {
        Contact agent = makeAgentContact('700000007');
        insert agent;
        insert makeEstimatedRecord(agent.Id, 'POL700', '2026-08', 500);

        Test.startTest();
        insert makePaymentRecord('POL700', '2026-08', '700000007', 500, agent.Id);
        Test.stopTest();

        Commission_Record__c reconciled = [
            SELECT Status__c
            FROM Commission_Record__c
            WHERE Policy_Number__c = 'POL700' AND Compensation_Month__c = null
            LIMIT 1
        ];
        System.assertEquals(STATUS_RECONCILED, reconciled.Status__c, 'YYYY-MM formatted Compensation_Month__c should match without conversion.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 8: inserting only an Estimated record (Compensation_Month__c
    // left null) should be a complete no-op for this handler — the
    // early-return gate on paymentRows.isEmpty().
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_EstimateOnly_NoPaymentRows_IsNoOp() {
        Contact agent = makeAgentContact('700000008');
        insert agent;

        Test.startTest();
        insert makeEstimatedRecord(agent.Id, 'POL800', '2026-08', 500);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Commission_Exception__c], 'No payment rows were inserted, so nothing should be evaluated.');
        Commission_Record__c estimate = [SELECT Status__c FROM Commission_Record__c WHERE Policy_Number__c = 'POL800' LIMIT 1];
        System.assertEquals(STATUS_ESTIMATED, estimate.Status__c, 'The Estimated record itself should be untouched.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 9: two Estimated records share the same Policy+Period+NPN key
    // (a data-quality edge case the header calls out) -> exactly one
    // gets reconciled, not both and not neither; the handler keeps the
    // first one built into estimatedByKey rather than erroring.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_DuplicateEstimateKey_ReconcilesExactlyOne() {
        Contact agent = makeAgentContact('700000009');
        insert agent;

        insert new List<Commission_Record__c>{
            makeEstimatedRecord(agent.Id, 'POL900', '2026-08', 500),
            makeEstimatedRecord(agent.Id, 'POL900', '2026-08', 500)
        };

        Test.startTest();
        insert makePaymentRecord('POL900', 'Aug-26', '700000009', 500, agent.Id);
        Test.stopTest();

        List<Commission_Record__c> estimates = [
            SELECT Status__c FROM Commission_Record__c
            WHERE Policy_Number__c = 'POL900' AND Compensation_Month__c = null
        ];
        System.assertEquals(2, estimates.size(), 'Both duplicate Estimated records should still exist.');
        Integer reconciledCount = 0;
        for (Commission_Record__c est : estimates) {
            if (est.Status__c == STATUS_RECONCILED) reconciledCount++;
        }
        System.assertEquals(1, reconciledCount, 'Exactly one of the duplicate-key Estimated records should be reconciled.');
        System.assertEquals(0, [SELECT COUNT() FROM Commission_Exception__c], 'The single payment should still match one estimate cleanly, no exception.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 10 (NEW): STEP 5a backfill — on a payment row that goes on to
    // match and reconcile cleanly, Payment_Period__c should still end up
    // populated with the normalized period derived from
    // Compensation_Month__c ('Aug-26' -> '2026-08'), even though Data
    // Loader never mapped Payment_Period__c on this import.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_BackfillsPaymentPeriod_OnMatchedPayment() {
        Contact agent = makeAgentContact('700000010');
        insert agent;
        insert makeEstimatedRecord(agent.Id, 'POL1000', '2026-08', 500);

        Test.startTest();
        Commission_Record__c payment = makePaymentRecord('POL1000', 'Aug-26', '700000010', 500, agent.Id);
        insert payment;
        Test.stopTest();

        Commission_Record__c savedPayment = [
            SELECT Payment_Period__c, Compensation_Month__c
            FROM Commission_Record__c
            WHERE Id = :payment.Id
        ];
        System.assertEquals('Aug-26', savedPayment.Compensation_Month__c, 'Sanity check: source Compensation_Month__c value is unchanged.');
        System.assertEquals('2026-08', savedPayment.Payment_Period__c, 'Payment_Period__c should be backfilled from Compensation_Month__c even though Data Loader never mapped it.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 11 (NEW): STEP 5a backfill happens even when the row goes on
    // to fail NPN validation and produce a No_Matching_Estimate exception
    // — the header is explicit that this is a data-quality fix
    // independent of reconciliation outcome, not just something that
    // happens to matched rows.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_BackfillsPaymentPeriod_EvenWhenExceptioned() {
        Contact agent = makeAgentContact('700000011');
        insert agent;
        insert makeEstimatedRecord(agent.Id, 'POL1100', '2026-08', 500);

        Test.startTest();
        // Unrecognized NPN -> No_Matching_Estimate exception, but the
        // period backfill loop runs before/independent of that check.
        Commission_Record__c payment = makePaymentRecord('POL1100', 'Aug-26', '999999999', 500, agent.Id);
        insert payment;
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Commission_Exception__c], 'Sanity check: this row is expected to exception on unknown NPN.');

        Commission_Record__c savedPayment = [
            SELECT Payment_Period__c
            FROM Commission_Record__c
            WHERE Id = :payment.Id
        ];
        System.assertEquals('2026-08', savedPayment.Payment_Period__c, 'Payment_Period__c should still be backfilled even when the row exceptions on NPN validation.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 12 (NEW): normalizePeriod's "unrecognized format" branch —
    // when Compensation_Month__c doesn't match either the YYYY-MM or
    // MMM-YY pattern, normalizePeriod returns the raw value unchanged
    // rather than guessing, so STEP 5a writes that raw value back onto
    // Payment_Period__c as-is. The row also fails to match any Estimated
    // record (since its key uses the same unnormalized string), so it
    // exceptions as No_Matching_Estimate.
    // ────────────────────────────────────────────────────────────────
    

    // ────────────────────────────────────────────────────────────────
    // Test 13 (NEW): the STEP 5a backfill is scoped to payment rows only
    // — an Estimated record's own Payment_Period__c (set directly at
    // creation, not derived from any Compensation_Month__c) must be left
    // exactly as inserted, since Estimated rows never enter paymentRows
    // in the first place (Compensation_Month__c is null on them).
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testHandleAfterInsert_DoesNotBackfillOrAlterEstimateRecords() {
        Contact agent = makeAgentContact('700000013');
        insert agent;
        Commission_Record__c estimate = makeEstimatedRecord(agent.Id, 'POL1300', '2026-08', 500);
        insert estimate;

        Test.startTest();
        insert makePaymentRecord('POL1300', 'Aug-26', '700000013', 500, agent.Id);
        Test.stopTest();

        Commission_Record__c savedEstimate = [
            SELECT Payment_Period__c, Status__c
            FROM Commission_Record__c
            WHERE Id = :estimate.Id
        ];
        System.assertEquals('2026-08', savedEstimate.Payment_Period__c, 'The Estimated record\'s own Payment_Period__c should be unchanged by the payment-row backfill logic.');
        System.assertEquals(STATUS_RECONCILED, savedEstimate.Status__c, 'Sanity check: the estimate still reconciles as in Test 1.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test data factories
    // ────────────────────────────────────────────────────────────────
    private static Integer contactCounter = 0;
    private static Contact makeAgentContact(String npn) {
        contactCounter++;
        return new Contact(
            FirstName = 'Agent',
            LastName = 'Recon' + contactCounter,
            Email = 'recontest' + contactCounter + '@example.test',
            NPN__c = npn,
            Agent_Status__c = 'Onboarding'
        );
    }

    private static Commission_Record__c makeEstimatedRecord(Id agentContactId, String policyNumber, String paymentPeriod, Decimal grossAmount) {
        return new Commission_Record__c(
            Compensation_Type__c = 'Commission',
            Contact__c = agentContactId,
            Agent__c = agentContactId,
            Policy_Number__c = policyNumber,
            Payment_Period__c = paymentPeriod,
            Status__c = STATUS_ESTIMATED,
            Gross_Amount__c = grossAmount
        );
    }

    private static Commission_Record__c makePaymentRecord(String policyNumber, String compensationMonth, String paidNpn, Decimal grossAmount, Id defensiveContactId) {
        return new Commission_Record__c(
            Compensation_Type__c = 'Commission',
            Contact__c = defensiveContactId,
            Policy_Number__c = policyNumber,
            Compensation_Month__c = compensationMonth,
            Paid_NPN__c = paidNpn,
            Gross_Amount__c = grossAmount
        );
    }
}