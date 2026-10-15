/**
 * Test class for ReferralRollupHandler (trigger: ReferralRollupTrigger).
 *
 * NEEDS CONFIRMATION before this will run clean — carried over from the
 * CRAnaReconcileHandlerTest troubleshooting session, plus new items specific
 * to this handler:
 *
 *  CONFIRMED already (via live org checks this session):
 *   - Contact requires Email, NPN__c, and Agent_Status__c = 'Onboarding'
 *     on insert (validation rules).
 *   - Referral_Record__c.Payment_Model_Snapshot__c is a restricted picklist
 *     with confirmed active values: As_Earned_PMPM, As_Earned_PPPM,
 *     Advanced_Commission_6, Advanced_Commission_9, Partial_Advance_Annual,
 *     Manual. Referral_Record__c itself has no validation rules.
 *
 *  STILL UNCONFIRMED for this handler:
 *   - Net_Amount__c is assumed to be a FORMULA field (Gross_Amount__c -
 *     Admin_Fee__c), per this handler's own header comment, so this test
 *     does NOT set it directly — Salesforce will reject a direct write to
 *     a formula field at compile time. If it turns out to be a plain
 *     writable field instead, add `crAna.Net_Amount__c = grossAmount -
 *     adminFee;` inside createCrAna() below, or the Paid-amount assertions
 *     will fail (sum will read null/0 instead of the expected total).
 *   - Commission_Record__c.Payment_Model__c is assumed to accept the same
 *     restricted-picklist values as Referral_Record__c.Payment_Model_Snapshot__c
 *     (both use 'As_Earned_PMPM' etc. in the existing handler code), but
 *     this hasn't been independently confirmed as its own picklist in
 *     Object Manager.
 *   - This test inserts Commission_Record__c (CR-ana-shaped) rows directly,
 *     bypassing CRAnaReconcileHandler. Any validation rule scoped to that
 *     object that we haven't hit yet in the other test class will surface
 *     here for the first time — expect at least one more round of fixes.
 *   - Total_CR_Ana_Created__c, Total_CR_Ana_Amount_Paid__c, and
 *     Latest_CR_Ana_Period__c on Referral_Record__c are spec-named per the
 *     handler's own header and not yet checked against the org.
 *
 * Covers:
 *  1. Single insert — Total_CR_Ana_Created__c and Latest_CR_Ana_Period__c
 *     update from a lone linked CR-ana.
 *  2. Bulk insert across multiple periods — count and latest period are
 *     correct across the batch, in one trigger context.
 *  3. Status change to 'Paid' — Total_CR_Ana_Amount_Paid__c sums
 *     Net_Amount__c (Gross - Admin Fee) for Paid records only.
 *  4. Non-status update — updating an unrelated field doesn't corrupt the
 *     already-correct rollup (handler should simply skip recompute, but
 *     functionally the values must still be accurate either way).
 *  5. Multiple Referral_Record__c parents in one bulk DML — rollups stay
 *     scoped per-parent, not blended across referrals.
 *  6. No-op — a Commission_Record__c with no Referral_Record__c set
 *     (e.g. a CR-house row) doesn't error and doesn't affect any rollup.
 */
@isTest
private class ReferralRollupHandlerTest {

    private static final String STATUS_RECONCILED     = 'Reconciled';
    private static final String STATUS_PAID           = 'Paid';
    private static final String COMP_TYPE_COMMISSION  = 'Commission';
    private static final String REFERRAL_VERIFIED     = 'Verified';
    private static final String MODEL_AS_EARNED_PMPM  = 'As_Earned_PMPM';

    // ── Shared fixture builders (mirrors CRAnaReconcileHandlerTest) ──────

    private static Integer contactCounter = 0;

    private static Contact createContact(String lastName) {
        contactCounter++;
        Contact c = new Contact(
            LastName        = lastName,
            Email           = 'referralrollup.test.' + contactCounter + '@example.com', // validation rule requires Email
            NPN__c          = '99901' + String.valueOf(contactCounter).leftPad(4, '0'), // validation rule: NPN required for all agents
            Agent_Status__c = 'Onboarding' // validation rule: Agent Status must be Onboarding while creating Agent record
        );
        insert c;
        return c;
    }

    private static Referral_Record__c createReferral(Id writingAgentId, Id referringAgentId, String policyNumber,
            String paymentModel, Date effectiveDate) {
        Referral_Record__c r = new Referral_Record__c();
        r.Writing_Agent__c          = writingAgentId;
        r.Referring_Agent__c        = referringAgentId;
        r.Policy_Number__c          = policyNumber;
        r.Payment_Model_Snapshot__c = paymentModel;
        r.Effective_Date__c         = effectiveDate;
        r.Status__c                 = REFERRAL_VERIFIED;
        insert r;
        return r;
    }

    private static String period(Integer year, Integer month) {
        String mm = month < 10 ? '0' + month : String.valueOf(month);
        return year + '-' + mm;
    }

    // Builds a CR-ana-shaped Commission_Record__c (does NOT insert — caller
    // controls insert timing/bulking so tests can exercise single vs. bulk
    // trigger contexts explicitly).
    private static Commission_Record__c buildCrAna(Id referralId, Id contactId, String policyNumber,
            String paymentPeriod, Decimal grossAmount, Decimal adminFee, String status) {
        Commission_Record__c crAna = new Commission_Record__c();
        crAna.Contact__c            = contactId;
        crAna.Policy_Number__c      = policyNumber;
        crAna.Payment_Period__c     = paymentPeriod;
        crAna.Compensation_Type__c  = COMP_TYPE_COMMISSION;
        crAna.Payment_Flow__c       = 'Referral';
        crAna.Payment_Model__c      = MODEL_AS_EARNED_PMPM;
        crAna.Gross_Amount__c       = grossAmount;
        crAna.Admin_Fee__c          = adminFee;
        crAna.Status__c             = status;
        crAna.Payment_Status__c     = 'Pending';
        crAna.Referral_Record__c    = referralId;
        crAna.Accrual_Source__c     = 'Statement_Reconciled';
        // Net_Amount__c intentionally NOT set here — assumed formula field.
        // See header note if that assumption is wrong.
        return crAna;
    }

    // ── 1. Single insert updates count + latest period ───────────────────

    @isTest
    static void testRollup_SingleInsert_UpdatesCountAndLatestPeriod() {
        Contact writingAgent   = createContact('WritingAgentA');
        Contact referringAgent = createContact('ReferringAgentA');
        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, 'POL-RR-A1',
                MODEL_AS_EARNED_PMPM, Date.newInstance(2026, 1, 1));

        Test.startTest();
        insert buildCrAna(ref.Id, referringAgent.Id, 'POL-RR-A1', period(2026, 1), 1000, 100, STATUS_RECONCILED);
        Test.stopTest();

        Referral_Record__c updated = [
            SELECT Total_CR_Ana_Created__c, Total_CR_Ana_Amount_Paid__c, Latest_CR_Ana_Period__c
            FROM   Referral_Record__c WHERE Id = :ref.Id
        ];
        System.assertEquals(1, updated.Total_CR_Ana_Created__c, 'One linked CR-ana should count as 1');
        System.assertEquals(period(2026, 1), updated.Latest_CR_Ana_Period__c);
        System.assertEquals(0, updated.Total_CR_Ana_Amount_Paid__c, 'Reconciled (not Paid) should not count toward amount paid');
    }

    // ── 2. Bulk insert across periods: count + latest period across the batch ─

    @isTest
    static void testRollup_BulkInsert_CountsAndLatestPeriodAcrossBatch() {
        Contact writingAgent   = createContact('WritingAgentB');
        Contact referringAgent = createContact('ReferringAgentB');
        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, 'POL-RR-B1',
                MODEL_AS_EARNED_PMPM, Date.newInstance(2026, 1, 1));

        List<Commission_Record__c> crAnas = new List<Commission_Record__c>{
            buildCrAna(ref.Id, referringAgent.Id, 'POL-RR-B1', period(2026, 1), 1000, 100, STATUS_RECONCILED),
            buildCrAna(ref.Id, referringAgent.Id, 'POL-RR-B1', period(2026, 2), 1000, 100, STATUS_RECONCILED),
            buildCrAna(ref.Id, referringAgent.Id, 'POL-RR-B1', period(2026, 3), 1000, 100, STATUS_RECONCILED)
        };

        Test.startTest();
        insert crAnas;
        Test.stopTest();

        Referral_Record__c updated = [
            SELECT Total_CR_Ana_Created__c, Latest_CR_Ana_Period__c
            FROM   Referral_Record__c WHERE Id = :ref.Id
        ];
        System.assertEquals(3, updated.Total_CR_Ana_Created__c);
        System.assertEquals(period(2026, 3), updated.Latest_CR_Ana_Period__c, 'Latest period should be the max across the batch');
    }

    // ── 3. Status change to Paid sums Net_Amount__c for Paid records only ─

    @isTest
    static void testRollup_StatusChangeToPaid_UpdatesAmountPaid() {
        Contact writingAgent   = createContact('WritingAgentC');
        Contact referringAgent = createContact('ReferringAgentC');
        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, 'POL-RR-C1',
                MODEL_AS_EARNED_PMPM, Date.newInstance(2026, 1, 1));

        Commission_Record__c crAnaPaid = buildCrAna(ref.Id, referringAgent.Id, 'POL-RR-C1', period(2026, 1),
                1000, 100, STATUS_RECONCILED); // Net expected = 900
        Commission_Record__c crAnaStillReconciled = buildCrAna(ref.Id, referringAgent.Id, 'POL-RR-C1', period(2026, 2),
                500, 50, STATUS_RECONCILED); // Net expected = 450, stays unpaid
        insert new List<Commission_Record__c>{ crAnaPaid, crAnaStillReconciled };

        Test.startTest();
        crAnaPaid.Status__c = STATUS_PAID;
        update crAnaPaid;
        Test.stopTest();

        Referral_Record__c updated = [
            SELECT Total_CR_Ana_Created__c, Total_CR_Ana_Amount_Paid__c
            FROM   Referral_Record__c WHERE Id = :ref.Id
        ];
        System.assertEquals(2, updated.Total_CR_Ana_Created__c, 'Created count reflects both rows regardless of status');
        System.assertEquals(900, updated.Total_CR_Ana_Amount_Paid__c,
                'Only the Paid row (1000 - 100 admin fee) should count toward amount paid');
    }

    // ── 4. Updating an unrelated field must not corrupt an accurate rollup ─

    @isTest
    static void testRollup_NonStatusUpdate_RollupStaysAccurate() {
        Contact writingAgent   = createContact('WritingAgentD');
        Contact referringAgent = createContact('ReferringAgentD');
        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, 'POL-RR-D1',
                MODEL_AS_EARNED_PMPM, Date.newInstance(2026, 1, 1));

        Commission_Record__c crAna = buildCrAna(ref.Id, referringAgent.Id, 'POL-RR-D1', period(2026, 1),
                1000, 100, STATUS_RECONCILED);
        insert crAna;

        Test.startTest();
        crAna.Gross_Amount__c = 1200; // unrelated to Status__c; handler should treat this as a no-op trigger-wise
        update crAna;
        Test.stopTest();

        Referral_Record__c updated = [
            SELECT Total_CR_Ana_Created__c, Latest_CR_Ana_Period__c
            FROM   Referral_Record__c WHERE Id = :ref.Id
        ];
        System.assertEquals(1, updated.Total_CR_Ana_Created__c, 'Rollup should remain accurate after a non-status update');
        System.assertEquals(period(2026, 1), updated.Latest_CR_Ana_Period__c);
    }

    // ── 5. Multiple Referral_Record__c parents stay scoped independently ─

    @isTest
    static void testRollup_MultipleReferrals_ScopedIndependently() {
        Contact writingAgent1   = createContact('WritingAgentE1');
        Contact referringAgent1 = createContact('ReferringAgentE1');
        Referral_Record__c ref1 = createReferral(writingAgent1.Id, referringAgent1.Id, 'POL-RR-E1',
                MODEL_AS_EARNED_PMPM, Date.newInstance(2026, 1, 1));

        Contact writingAgent2   = createContact('WritingAgentE2');
        Contact referringAgent2 = createContact('ReferringAgentE2');
        Referral_Record__c ref2 = createReferral(writingAgent2.Id, referringAgent2.Id, 'POL-RR-E2',
                MODEL_AS_EARNED_PMPM, Date.newInstance(2026, 1, 1));

        List<Commission_Record__c> crAnas = new List<Commission_Record__c>{
            buildCrAna(ref1.Id, referringAgent1.Id, 'POL-RR-E1', period(2026, 1), 1000, 100, STATUS_RECONCILED),
            buildCrAna(ref1.Id, referringAgent1.Id, 'POL-RR-E1', period(2026, 2), 1000, 100, STATUS_RECONCILED),
            buildCrAna(ref2.Id, referringAgent2.Id, 'POL-RR-E2', period(2026, 1), 2000, 200, STATUS_RECONCILED)
        };

        Test.startTest();
        insert crAnas;
        Test.stopTest();

        Map<Id, Referral_Record__c> updated = new Map<Id, Referral_Record__c>([
            SELECT Total_CR_Ana_Created__c, Latest_CR_Ana_Period__c
            FROM   Referral_Record__c WHERE Id IN :new List<Id>{ ref1.Id, ref2.Id }
        ]);
        System.assertEquals(2, updated.get(ref1.Id).Total_CR_Ana_Created__c, 'ref1 should count only its own 2 rows');
        System.assertEquals(1, updated.get(ref2.Id).Total_CR_Ana_Created__c, 'ref2 should count only its own 1 row');
        System.assertEquals(period(2026, 2), updated.get(ref1.Id).Latest_CR_Ana_Period__c);
        System.assertEquals(period(2026, 1), updated.get(ref2.Id).Latest_CR_Ana_Period__c);
    }

    // ── 6. No-op: Commission_Record__c without Referral_Record__c is ignored ─

    @isTest
    static void testNoOp_CommissionRecordWithoutReferralRecordIsIgnored() {
        Contact writingAgent = createContact('WritingAgentF');

        Commission_Record__c crHouse = new Commission_Record__c();
        crHouse.Agent__c             = writingAgent.Id;
        crHouse.Policy_Number__c     = 'POL-RR-F1';
        crHouse.Payment_Period__c    = period(2026, 1);
        crHouse.Payment_Model__c     = MODEL_AS_EARNED_PMPM;
        crHouse.Compensation_Type__c = COMP_TYPE_COMMISSION;
        crHouse.Gross_Amount__c      = 1000;
        crHouse.Status__c            = STATUS_RECONCILED;
        // Referral_Record__c deliberately left null — this is the CR-house
        // path, not a CR-ana; the rollup handler must ignore it.

        Test.startTest();
        insert crHouse; // should not throw, and should not touch any Referral_Record__c
        Test.stopTest();

        // No specific Referral_Record__c to assert against; the meaningful
        // assertion here is simply that the insert above didn't throw.
        System.assert(crHouse.Id != null, 'CR-house insert with no Referral_Record__c should succeed without error');
    }
}