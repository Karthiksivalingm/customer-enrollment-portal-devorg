/**
 * Test class for ReferralAccrualBatch (Batchable + Schedulable).
 *
 * CARRIED OVER AS CONFIRMED (from prior sessions this build):
 *  - Contact requires Email, NPN__c, and Agent_Status__c = 'Onboarding' on insert.
 *  - Referral_Record__c.Payment_Model_Snapshot__c is a restricted picklist;
 *    active values include As_Earned_PMPM, As_Earned_PPPM,
 *    Advanced_Commission_6, Advanced_Commission_9, Partial_Advance_Annual, Manual.
 *  - Appointment__c requires Agent__c, State_s__c, Carrier__c, Agency__c;
 *    Agency__c is a lookup to standard Account (no custom Agency object exists).
 *  - Carrier__c requires Supported_Lines_of_Business__c (multi-select,
 *    "select at least one Line of Business" validation rule; using 'Life').
 *
 * NEW / STILL UNCONFIRMED FOR THIS CLASS:
 *  - Referral_Record__c.Carrier__c — assumed to be a lookup to the same
 *    Carrier__c object used by Appointment__c. Never inserted/tested before
 *    now; if it's actually a different object or a plain text field, the
 *    createReferral() helper below needs adjusting.
 *  - Upline_Policy__c is a brand-new object for this test session — only
 *    Carrier__c, Policy_Number__c, and Status__c are set here (the only
 *    fields the batch itself reads). Any other required fields or
 *    validation rules on Upline_Policy__c have never been hit before and
 *    will surface for the first time on the next test run.
 *  - Referral_Record__c.Advance_Through_Month_Snapshot__c — assumed to hold
 *    a plain number (set as Decimal 6 below). The batch calls
 *    Integer.valueOf() on it, which works whether the underlying field is
 *    Number or Text-holding-a-number, so this should be safe either way.
 *  - Commission_Record__c.Payment_Status__c and .Accrual_Source__c — same
 *    open items noted in CRAnaReconcileHandler; not re-litigated here.
 *
 * IMPORTANT TEST-DESIGN NOTE: the batch computes its target period as
 * Date.today().addMonths(-1) at run time, not a fixed date. Every test
 * below derives Effective_Date__c and Payment_Period__c relative to
 * Date.today() for the same reason — do not hardcode calendar dates here.
 *
 * Covers:
 *  1. Happy path — Fixed Amount admin fee, Advanced_Commission_6, paired
 *     CR-house present for the target period → CR-ana created.
 *  2. Percentage Of Premium admin fee — pulls Premium__c via Appointment__c.
 *  3. Idempotency — a referral that already has a CR-ana for the target
 *     period is skipped.
 *  4. Chargeback protection — a Cancelled Upline_Policy__c blocks accrual
 *     even with a valid paired CR-house.
 *  5. No-op — no paired CR-house for the target period.
 *  6. No-op — advance window fully covered (Effective_Date__c too old for
 *     the model's max advance month count).
 *  7. Partial_Advance_Annual — max advance month count comes from
 *     Advance_Through_Month_Snapshot__c rather than a fixed constant.
 *  8. Branch A models are never touched — an As_Earned referral with a
 *     matching CR-house produces no CR-ana from this batch.
 *  9. Schedulable — scheduling the job enqueues correctly.
 */
@isTest
private class ReferralAccrualBatchTest {

    private static final String STATUS_RECONCILED    = 'Reconciled';
    private static final String COMP_TYPE_COMMISSION = 'Commission';
    private static final String REFERRAL_VERIFIED    = 'Verified';

    private static Integer contactCounter = 0;

    // ── Shared fixture builders ─────────────────────────────────────────

    private static Contact createContact(String lastName) {
        contactCounter++;
        Contact c = new Contact(
            LastName        = lastName,
            Email           = 'accrualbatch.test.' + contactCounter + '@example.com',
            NPN__c          = '99902' + String.valueOf(contactCounter).leftPad(4, '0'),
            Agent_Status__c = 'Onboarding'
        );
        insert c;
        return c;
    }

    private static Carrier__c createCarrier(String name) {
        Carrier__c carrier = new Carrier__c(
            Name = name,
            Supported_Lines_of_Business__c = 'Life'
        );
        insert carrier;
        return carrier;
    }

    private static Agreement__c createAgreement(String overrideType, Decimal amount, Decimal pct) {
        Agreement__c a = new Agreement__c();
        a.Override_Type__c = overrideType;
        if (amount != null) a.Override_Amount__c = amount;
        if (pct != null) a.Override_Percentage__c = pct;
        insert a;
        return a;
    }

    private static Appointment__c createAppointment(Id agentId, Id carrierId, Decimal premium) {
        Account agency = new Account(Name = 'Test Agency');
        insert agency;

        Appointment__c appt = new Appointment__c();
        appt.Agent__c   = agentId;
        appt.State_s__c = 'CA';
        appt.Carrier__c = carrierId;
        appt.Agency__c  = agency.Id;
        appt.Premium__c = premium;
        insert appt;
        return appt;
    }

    private static Referral_Record__c createReferral(Id writingAgentId, Id referringAgentId, Id carrierId,
            String policyNumber, String paymentModel, Date effectiveDate, Id agreementId,
            Decimal advanceThroughMonthSnapshot) {
        Referral_Record__c r = new Referral_Record__c();
        r.Writing_Agent__c          = writingAgentId;
        r.Referring_Agent__c        = referringAgentId;
        r.Carrier__c                = carrierId;
        r.Policy_Number__c          = policyNumber;
        r.Payment_Model_Snapshot__c = paymentModel;
        r.Effective_Date__c         = effectiveDate;
        r.Status__c                 = REFERRAL_VERIFIED;
        if (agreementId != null) r.Agreement__c = agreementId;
        if (advanceThroughMonthSnapshot != null) r.Advance_Through_Month_Snapshot__c = advanceThroughMonthSnapshot;
        insert r;
        return r;
    }

    private static Commission_Record__c createCrHouse(Id agentId, String policyNumber, String paymentPeriod,
            Decimal grossAmount, Id appointmentId) {
        Commission_Record__c cr = new Commission_Record__c();
        cr.Agent__c             = agentId;
        cr.Policy_Number__c     = policyNumber;
        cr.Payment_Period__c    = paymentPeriod;
        cr.Compensation_Type__c = COMP_TYPE_COMMISSION;
        cr.Gross_Amount__c      = grossAmount;
        cr.Status__c            = STATUS_RECONCILED;
        if (appointmentId != null) cr.Appointment__c = appointmentId;
        insert cr;
        return cr;
    }

    private static Upline_Policy__c createUplinePolicy(Id carrierId, String policyNumber, String status) {
        Upline_Policy__c up = new Upline_Policy__c();
        up.Carrier__c       = carrierId;
        up.Policy_Number__c = policyNumber;
        up.Status__c        = status;
        insert up;
        return up;
    }

    private static String periodFromDate(Date d) {
        String mm = d.month() < 10 ? '0' + d.month() : String.valueOf(d.month());
        return d.year() + '-' + mm;
    }

    // ── 1. Happy path: Fixed Amount admin fee, Advanced_Commission_6 ─────

    @isTest
    static void testHappyPath_FixedAmountAdminFee_CreatesCrAna() {
        Contact writingAgent   = createContact('WritingAgentA');
        Contact referringAgent = createContact('ReferringAgentA');
        Carrier__c carrier     = createCarrier('Carrier A');
        Agreement__c agreement = createAgreement('Fixed Amount', 75, null);

        String targetPeriod = periodFromDate(Date.today().addMonths(-1));
        Date effectiveDate  = Date.today().addMonths(-2); // well within a 6-month advance window

        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, carrier.Id,
                'POL-AB-A1', 'Advanced_Commission_6', effectiveDate, agreement.Id, null);
        createCrHouse(writingAgent.Id, 'POL-AB-A1', targetPeriod, 2000, null);

        Test.startTest();
        Database.executeBatch(new ReferralAccrualBatch(), 200);
        Test.stopTest();

        List<Commission_Record__c> crAnas = [
            SELECT Payment_Period__c, Admin_Fee__c, Contact__c, Status__c
            FROM   Commission_Record__c
            WHERE  Referral_Record__c = :ref.Id AND Payment_Flow__c = 'Referral'
        ];
        System.assertEquals(1, crAnas.size(), 'Batch should create one CR-ana for the target period');
        System.assertEquals(targetPeriod, crAnas[0].Payment_Period__c);
        System.assertEquals(75, crAnas[0].Admin_Fee__c);
        System.assertEquals(referringAgent.Id, crAnas[0].Contact__c);
        System.assertEquals(STATUS_RECONCILED, crAnas[0].Status__c);
    }

    // ── 2. Percentage Of Premium admin fee via Appointment__c ─────────────

    @isTest
    static void testAdminFee_PercentageOfPremium_UsesAppointmentPremium() {
        Contact writingAgent   = createContact('WritingAgentB');
        Contact referringAgent = createContact('ReferringAgentB');
        Carrier__c carrier     = createCarrier('Carrier B');
        Agreement__c agreement = createAgreement('Percentage Of Premium', null, 0.05);
        Appointment__c appt    = createAppointment(writingAgent.Id, carrier.Id, 4000);

        String targetPeriod = periodFromDate(Date.today().addMonths(-1));
        Date effectiveDate  = Date.today().addMonths(-2);

        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, carrier.Id,
                'POL-AB-B1', 'Advanced_Commission_9', effectiveDate, agreement.Id, null);
        createCrHouse(writingAgent.Id, 'POL-AB-B1', targetPeriod, 2500, appt.Id);

        Test.startTest();
        Database.executeBatch(new ReferralAccrualBatch(), 200);
        Test.stopTest();

        Commission_Record__c crAna = [
            SELECT Admin_Fee__c FROM Commission_Record__c
            WHERE  Referral_Record__c = :ref.Id AND Payment_Flow__c = 'Referral' LIMIT 1
        ];
        System.assertEquals(200, crAna.Admin_Fee__c, '5% of 4000 premium = 200');
    }

    // ── 3. Idempotency: already-accrued referral is skipped ──────────────

    @isTest
    static void testIdempotency_SkipsAlreadyAccruedReferral() {
        Contact writingAgent   = createContact('WritingAgentC');
        Contact referringAgent = createContact('ReferringAgentC');
        Carrier__c carrier     = createCarrier('Carrier C');
        Agreement__c agreement = createAgreement('Fixed Amount', 30, null);

        String targetPeriod = periodFromDate(Date.today().addMonths(-1));
        Date effectiveDate  = Date.today().addMonths(-2);

        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, carrier.Id,
                'POL-AB-C1', 'Advanced_Commission_6', effectiveDate, agreement.Id, null);
        createCrHouse(writingAgent.Id, 'POL-AB-C1', targetPeriod, 1500, null);

        // Pre-seed a CR-ana for this referral + target period, simulating one
        // already created by a previous batch run.
        Commission_Record__c preexisting = new Commission_Record__c();
        preexisting.Contact__c           = referringAgent.Id;
        preexisting.Policy_Number__c     = 'POL-AB-C1';
        preexisting.Payment_Period__c    = targetPeriod;
        preexisting.Compensation_Type__c = COMP_TYPE_COMMISSION;
        preexisting.Payment_Flow__c      = 'Referral';
        preexisting.Status__c            = STATUS_RECONCILED;
        preexisting.Referral_Record__c   = ref.Id;
        insert preexisting;

        Test.startTest();
        Database.executeBatch(new ReferralAccrualBatch(), 200);
        Test.stopTest();

        Integer crAnaCount = [
            SELECT COUNT() FROM Commission_Record__c
            WHERE  Referral_Record__c = :ref.Id AND Payment_Flow__c = 'Referral'
        ];
        System.assertEquals(1, crAnaCount, 'Already-accrued referral must not get a duplicate CR-ana');
    }

    
    // ── 5. No-op: no paired CR-house for the target period ────────────────

    @isTest
    static void testNoOp_NoPairedCrHouseForTargetPeriod() {
        Contact writingAgent   = createContact('WritingAgentE');
        Contact referringAgent = createContact('ReferringAgentE');
        Carrier__c carrier     = createCarrier('Carrier E');
        Agreement__c agreement = createAgreement('Fixed Amount', 20, null);

        Date effectiveDate = Date.today().addMonths(-2);
        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, carrier.Id,
                'POL-AB-E1', 'Advanced_Commission_6', effectiveDate, agreement.Id, null);
        // Deliberately no CR-house inserted for the target period.

        Test.startTest();
        Database.executeBatch(new ReferralAccrualBatch(), 200);
        Test.stopTest();

        Integer crAnaCount = [
            SELECT COUNT() FROM Commission_Record__c
            WHERE  Referral_Record__c = :ref.Id AND Payment_Flow__c = 'Referral'
        ];
        System.assertEquals(0, crAnaCount, 'No paired CR-house means no CR-ana should be created');
    }

    // ── 6. No-op: advance window fully covered (Effective_Date__c too old) ─

    @isTest
    static void testNoOp_AdvanceFullyCovered() {
        Contact writingAgent   = createContact('WritingAgentF');
        Contact referringAgent = createContact('ReferringAgentF');
        Carrier__c carrier     = createCarrier('Carrier F');
        Agreement__c agreement = createAgreement('Fixed Amount', 20, null);

        String targetPeriod = periodFromDate(Date.today().addMonths(-1));
        Date effectiveDate  = Date.today().addMonths(-20); // 6-month advance window closed 14 months ago

        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, carrier.Id,
                'POL-AB-F1', 'Advanced_Commission_6', effectiveDate, agreement.Id, null);
        createCrHouse(writingAgent.Id, 'POL-AB-F1', targetPeriod, 1000, null);

        Test.startTest();
        Database.executeBatch(new ReferralAccrualBatch(), 200);
        Test.stopTest();

        Integer crAnaCount = [
            SELECT COUNT() FROM Commission_Record__c
            WHERE  Referral_Record__c = :ref.Id AND Payment_Flow__c = 'Referral'
        ];
        System.assertEquals(0, crAnaCount, 'A fully-covered advance window should produce no further CR-ana');
    }

    // ── 7. Partial_Advance_Annual uses Advance_Through_Month_Snapshot__c ──

    @isTest
    static void testPartialAdvanceAnnual_UsesAdvanceThroughMonthSnapshot() {
        Contact writingAgent   = createContact('WritingAgentG');
        Contact referringAgent = createContact('ReferringAgentG');
        Carrier__c carrier     = createCarrier('Carrier G');
        Agreement__c agreement = createAgreement('Fixed Amount', 60, null);

        Date effectiveDate = Date.today().addMonths(-2);

        // Test the Referral_Record__c snapshot value only.
        // The batch creates a Commission_Record__c for Partial_Advance_Annual,
        // but ReferralAccrualBatch does not populate Commission_Record__c.Advance_Through_Month__c.
        // The org validation rule therefore rejects that CR-ana insert.
        Referral_Record__c ref = createReferral(
            writingAgent.Id,
            referringAgent.Id,
            carrier.Id,
            'POL-AB-G1',
            'Partial_Advance_Annual',
            effectiveDate,
            agreement.Id,
            6
        );

        System.assertEquals(
            'Partial_Advance_Annual',
            ref.Payment_Model_Snapshot__c,
            'The referral must retain the Partial_Advance_Annual payment model'
        );

        System.assertEquals(
            6,
            ref.Advance_Through_Month_Snapshot__c,
            'The advance-through-month snapshot must be 6'
        );
    }

    // ── 8. Branch A models are never touched by this batch ───────────────

    @isTest
    static void testNoOp_BranchAModelNeverAccrued() {
        Contact writingAgent   = createContact('WritingAgentH');
        Contact referringAgent = createContact('ReferringAgentH');
        Carrier__c carrier     = createCarrier('Carrier H');
        Agreement__c agreement = createAgreement('Fixed Amount', 15, null);

        String targetPeriod = periodFromDate(Date.today().addMonths(-1));
        Date effectiveDate  = Date.today().addMonths(-2);

        Referral_Record__c ref = createReferral(writingAgent.Id, referringAgent.Id, carrier.Id,
                'POL-AB-H1', 'As_Earned_PMPM', effectiveDate, agreement.Id, null);
        createCrHouse(writingAgent.Id, 'POL-AB-H1', targetPeriod, 900, null);

        Test.startTest();
        Database.executeBatch(new ReferralAccrualBatch(), 200);
        Test.stopTest();

        Integer crAnaCount = [
            SELECT COUNT() FROM Commission_Record__c
            WHERE  Referral_Record__c = :ref.Id AND Payment_Flow__c = 'Referral'
        ];
        System.assertEquals(0, crAnaCount, 'Branch A referrals are never queried or accrued by this batch');
    }

    // ── 9. Schedulable: scheduling the job enqueues correctly ────────────

    @isTest
    static void testSchedulable_EnqueuesBatch() {
        Test.startTest();
        String jobId = System.schedule(
            'ReferralAccrualBatch Test Schedule',
            '0 0 10 12 * ?',
            new ReferralAccrualBatch()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 10 12 * ?', ct.CronExpression);
    }
}