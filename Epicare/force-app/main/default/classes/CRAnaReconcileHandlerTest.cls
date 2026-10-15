/**
 * Test class for CRAnaReconcileHandler (trigger: CRAnaReconcileTrigger).
 *
 * Covers:
 *  1. Branch A (As_Earned_PMPM / As_Earned_PPPM) — CR-ana created every
 *     Reconciled transition.
 *  2. Branch B (Advanced_Commission_6/9, Partial_Advance_Annual) —
 *     CR-ana created ONLY for the period matching Referral_Record.Effective_Date.
 *  3. Idempotency — re-running / duplicate Reconciled transition for a
 *     period that already has a CR-ana does not create a duplicate.
 *  4. Admin fee calculation for all three Override_Type__c values,
 *     including the Percentage Of Premium path that queries Appointment__c.
 *  5. No-op paths: no Verified Referral_Record match, non-Commission
 *     Compensation_Type__c, and unrecognized Payment_Model_Snapshot__c.
 */
@isTest
private class CRAnaReconcileHandlerTest {

    private static final String STATUS_RECONCILED = 'Reconciled';

    // Commission_Record__c.Status__c does not have 'Pending' in Production.
    // 'Estimated' is a valid active picklist value and is used as the
    // initial non-Reconciled status before testing the transition.
    private static final String STATUS_PENDING = 'Estimated';

    private static final String COMP_TYPE_COMMISSION = 'Commission';
    private static final String COMP_TYPE_OVERRIDE   = 'Override';
    private static final String REFERRAL_VERIFIED    = 'Verified';

    // ── Shared fixture builders ─────────────────────────────────

    private static Integer contactCounter = 0;

    private static Contact createContact(String lastName) {
        contactCounter++;

        Contact c = new Contact(
            LastName = lastName,
            Email = 'craana.test.' + contactCounter + '@example.com',
            NPN__c = '99900' + String.valueOf(contactCounter).leftPad(4, '0'),
            Agent_Status__c = 'Onboarding'
        );

        insert c;
        return c;
    }

    private static Agreement__c createAgreement(
        String overrideType,
        Decimal amount,
        Decimal pct
    ) {
        Agreement__c a = new Agreement__c();

        a.Override_Type__c = overrideType;

        if (amount != null) {
            a.Override_Amount__c = amount;
        }

        if (pct != null) {
            a.Override_Percentage__c = pct;
        }

        insert a;
        return a;
    }

    // Appointment__c requires Agent__c, State_s__c, Carrier__c, Agency__c
    private static Appointment__c createAppointment(
        Id agentId,
        Decimal premium
    ) {
        Carrier__c carrier = new Carrier__c(
            Name = 'Test Carrier',
            Supported_Lines_of_Business__c = 'Life'
        );

        insert carrier;

        Account agency = new Account(
            Name = 'Test Agency'
        );

        insert agency;

        Appointment__c appt = new Appointment__c();

        appt.Agent__c = agentId;
        appt.State_s__c = 'CA';
        appt.Carrier__c = carrier.Id;
        appt.Agency__c = agency.Id;
        appt.Premium__c = premium;

        insert appt;

        return appt;
    }

    private static Referral_Record__c createReferral(
        Id writingAgentId,
        Id referringAgentId,
        String policyNumber,
        String paymentModel,
        Date effectiveDate,
        Id agreementId
    ) {
        Referral_Record__c r = new Referral_Record__c();

        r.Writing_Agent__c = writingAgentId;
        r.Referring_Agent__c = referringAgentId;
        r.Policy_Number__c = policyNumber;
        r.Payment_Model_Snapshot__c = paymentModel;
        r.Effective_Date__c = effectiveDate;
        r.Status__c = REFERRAL_VERIFIED;

        if (agreementId != null) {
            r.Agreement__c = agreementId;
        }

        insert r;

        return r;
    }

    private static Commission_Record__c buildCrHouse(
        Id agentId,
        String policyNumber,
        String paymentPeriod,
        String paymentModel,
        Decimal grossAmount,
        Id appointmentId
    ) {
        Commission_Record__c cr = new Commission_Record__c();

        cr.Agent__c = agentId;
        cr.Policy_Number__c = policyNumber;
        cr.Payment_Period__c = paymentPeriod;
        cr.Payment_Model__c = paymentModel;
        cr.Compensation_Type__c = COMP_TYPE_COMMISSION;
        cr.Gross_Amount__c = grossAmount;

        // IMPORTANT:
        // Production Commission_Record__c.Status__c does not contain
        // 'Pending'. 'Estimated' is a valid active value.
        cr.Status__c = STATUS_PENDING;

        if (appointmentId != null) {
            cr.Appointment__c = appointmentId;
        }

        return cr;
    }

    private static String period(
        Integer year,
        Integer month
    ) {
        String mm = month < 10
            ? '0' + month
            : String.valueOf(month);

        return year + '-' + mm;
    }

    // ── 1. Branch A: As_Earned creates a CR-ana on every Reconciled hit ──

    @isTest
    static void testBranchA_AsEarned_CreatesCrAnaEachTime() {

        Contact writingAgent =
            createContact('WritingAgentA');

        Contact referringAgent =
            createContact('ReferringAgentA');

        Agreement__c agreement =
            createAgreement(
                'Fixed Amount',
                50,
                null
            );

        createReferral(
            writingAgent.Id,
            referringAgent.Id,
            'POL-A-1',
            'As_Earned_PMPM',
            Date.newInstance(2026, 1, 15),
            agreement.Id
        );

        Commission_Record__c crHouseJan =
            buildCrHouse(
                writingAgent.Id,
                'POL-A-1',
                period(2026, 1),
                'As_Earned_PMPM',
                1000,
                null
            );

        Commission_Record__c crHouseFeb =
            buildCrHouse(
                writingAgent.Id,
                'POL-A-1',
                period(2026, 2),
                'As_Earned_PMPM',
                1000,
                null
            );

        insert new List<Commission_Record__c>{
            crHouseJan,
            crHouseFeb
        };

        Test.startTest();

        crHouseJan.Status__c = STATUS_RECONCILED;
        crHouseFeb.Status__c = STATUS_RECONCILED;

        update new List<Commission_Record__c>{
            crHouseJan,
            crHouseFeb
        };

        Test.stopTest();

        List<Commission_Record__c> crAnas = [
            SELECT Id,
                   Payment_Period__c,
                   Admin_Fee__c,
                   Status__c,
                   Contact__c,
                   Referral_Record__c
            FROM Commission_Record__c
            WHERE Payment_Flow__c = 'Referral'
        ];

        System.assertEquals(
            2,
            crAnas.size(),
            'Branch A should create one CR-ana per Reconciled transition'
        );

        for (Commission_Record__c ana : crAnas) {
            System.assertEquals(
                referringAgent.Id,
                ana.Contact__c
            );

            System.assertEquals(
                STATUS_RECONCILED,
                ana.Status__c
            );

            System.assertEquals(
                50,
                ana.Admin_Fee__c,
                'Fixed Amount override should copy Override_Amount__c'
            );
        }
    }

    // ── 2. Branch B: only the first accrual period creates a CR-ana here ─

    @isTest
    static void testBranchB_Advanced_OnlyFirstPeriodCreatesCrAna() {

        Contact writingAgent =
            createContact('WritingAgentB');

        Contact referringAgent =
            createContact('ReferringAgentB');

        Agreement__c agreement =
            createAgreement(
                'Percentage Of Commission',
                null,
                0.1
            );

        Date effectiveDate =
            Date.newInstance(2026, 3, 1);

        createReferral(
            writingAgent.Id,
            referringAgent.Id,
            'POL-B-1',
            'Advanced_Commission_6',
            effectiveDate,
            agreement.Id
        );

        Commission_Record__c crHouseFirst =
            buildCrHouse(
                writingAgent.Id,
                'POL-B-1',
                period(2026, 3),
                'Advanced_Commission_6',
                2000,
                null
            );

        Commission_Record__c crHouseSecond =
            buildCrHouse(
                writingAgent.Id,
                'POL-B-1',
                period(2026, 4),
                'Advanced_Commission_6',
                2000,
                null
            );

        insert new List<Commission_Record__c>{
            crHouseFirst,
            crHouseSecond
        };

        Test.startTest();

        crHouseFirst.Status__c = STATUS_RECONCILED;
        crHouseSecond.Status__c = STATUS_RECONCILED;

        update new List<Commission_Record__c>{
            crHouseFirst,
            crHouseSecond
        };

        Test.stopTest();

        List<Commission_Record__c> crAnas = [
            SELECT Id,
                   Payment_Period__c,
                   Admin_Fee__c
            FROM Commission_Record__c
            WHERE Payment_Flow__c = 'Referral'
        ];

        System.assertEquals(
            1,
            crAnas.size(),
            'Branch B should only create a CR-ana for the first accrual period'
        );

        System.assertEquals(
            period(2026, 3),
            crAnas[0].Payment_Period__c
        );

        System.assertEquals(
            200,
            crAnas[0].Admin_Fee__c,
            '10% of 2000 gross = 200'
        );
    }

    // ── 3. Idempotency: duplicate transition for same period is a no-op ─

    @isTest
    static void testIdempotency_NoDuplicateCrAnaForSamePeriod() {

        Contact writingAgent =
            createContact('WritingAgentC');

        Contact referringAgent =
            createContact('ReferringAgentC');

        Agreement__c agreement =
            createAgreement(
                'Fixed Amount',
                25,
                null
            );

        Referral_Record__c ref =
            createReferral(
                writingAgent.Id,
                referringAgent.Id,
                'POL-C-1',
                'As_Earned_PMPM',
                Date.newInstance(2026, 1, 1),
                agreement.Id
            );

        Commission_Record__c crHouse =
            buildCrHouse(
                writingAgent.Id,
                'POL-C-1',
                period(2026, 1),
                'As_Earned_PMPM',
                500,
                null
            );

        insert crHouse;

        // Pre-seed an existing CR-ana for this Referral_Record
        // + Payment_Period.
        Commission_Record__c preexistingAna =
            new Commission_Record__c();

        preexistingAna.Contact__c =
            referringAgent.Id;

        preexistingAna.Policy_Number__c =
            'POL-C-1';

        preexistingAna.Payment_Period__c =
            period(2026, 1);

        preexistingAna.Compensation_Type__c =
            COMP_TYPE_COMMISSION;

        preexistingAna.Payment_Flow__c =
            'Referral';

        preexistingAna.Status__c =
            STATUS_RECONCILED;

        preexistingAna.Referral_Record__c =
            ref.Id;

        insert preexistingAna;

        Test.startTest();

        crHouse.Status__c =
            STATUS_RECONCILED;

        update crHouse;

        Test.stopTest();

        List<Commission_Record__c> crAnas = [
            SELECT Id
            FROM Commission_Record__c
            WHERE Referral_Record__c = :ref.Id
            AND Payment_Period__c = :period(2026, 1)
        ];

        System.assertEquals(
            1,
            crAnas.size(),
            'No duplicate CR-ana should be created for an already-covered period'
        );
    }

    // ── 4. Admin fee: Percentage Of Premium pulls from Appointment__c ──

    @isTest
    static void testAdminFee_PercentageOfPremium_UsesAppointmentPremium() {

        Contact writingAgent =
            createContact('WritingAgentD');

        Contact referringAgent =
            createContact('ReferringAgentD');

        Agreement__c agreement =
            createAgreement(
                'Percentage Of Premium',
                null,
                0.05
            );

        Appointment__c appt =
            createAppointment(
                writingAgent.Id,
                3000
            );

        createReferral(
            writingAgent.Id,
            referringAgent.Id,
            'POL-D-1',
            'As_Earned_PPPM',
            Date.newInstance(2026, 1, 1),
            agreement.Id
        );

        Commission_Record__c crHouse =
            buildCrHouse(
                writingAgent.Id,
                'POL-D-1',
                period(2026, 1),
                'As_Earned_PPPM',
                800,
                appt.Id
            );

        insert crHouse;

        Test.startTest();

        crHouse.Status__c =
            STATUS_RECONCILED;

        update crHouse;

        Test.stopTest();

        Commission_Record__c ana = [
            SELECT Admin_Fee__c
            FROM Commission_Record__c
            WHERE Payment_Flow__c = 'Referral'
            LIMIT 1
        ];

        System.assertEquals(
            150,
            ana.Admin_Fee__c,
            '5% of 3000 premium = 150'
        );
    }

    // ── 5. No-op: no Verified Referral_Record for this Agent/Policy ──

    @isTest
    static void testNoOp_NoMatchingReferralRecord() {

        Contact writingAgent =
            createContact('WritingAgentE');

        Commission_Record__c crHouse =
            buildCrHouse(
                writingAgent.Id,
                'POL-E-1',
                period(2026, 1),
                'As_Earned_PMPM',
                900,
                null
            );

        insert crHouse;

        Test.startTest();

        crHouse.Status__c =
            STATUS_RECONCILED;

        update crHouse;

        Test.stopTest();

        Integer anaCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Payment_Flow__c = 'Referral'
        ];

        System.assertEquals(
            0,
            anaCount,
            'No referral match means no CR-ana should be created'
        );
    }

    // ── 6. No-op: non-Commission Compensation_Type__c ignored ──

    @isTest
    static void testNoOp_NonCommissionCompensationTypeIgnored() {

        Contact writingAgent =
            createContact('WritingAgentF');

        Contact referringAgent =
            createContact('ReferringAgentF');

        Agreement__c agreement =
            createAgreement(
                'Fixed Amount',
                10,
                null
            );

        createReferral(
            writingAgent.Id,
            referringAgent.Id,
            'POL-F-1',
            'As_Earned_PMPM',
            Date.newInstance(2026, 1, 1),
            agreement.Id
        );

        Commission_Record__c crHouse =
            buildCrHouse(
                writingAgent.Id,
                'POL-F-1',
                period(2026, 1),
                'As_Earned_PMPM',
                700,
                null
            );

        crHouse.Compensation_Type__c =
            COMP_TYPE_OVERRIDE;

        insert crHouse;

        Test.startTest();

        crHouse.Status__c =
            STATUS_RECONCILED;

        update crHouse;

        Test.stopTest();

        Integer anaCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Payment_Flow__c = 'Referral'
        ];

        System.assertEquals(
            0,
            anaCount,
            'Override compensation type must not spuriously trigger a CR-ana'
        );
    }

    // ── 7. No-op: unrecognized Payment_Model_Snapshot__c is skipped ──

    @isTest
    static void testNoOp_UnrecognizedPaymentModelSkipped() {

        Contact writingAgent =
            createContact('WritingAgentG');

        Contact referringAgent =
            createContact('ReferringAgentG');

        Agreement__c agreement =
            createAgreement(
                'Fixed Amount',
                10,
                null
            );

        createReferral(
            writingAgent.Id,
            referringAgent.Id,
            'POL-G-1',
            'Manual',
            Date.newInstance(2026, 1, 1),
            agreement.Id
        );

        Commission_Record__c crHouse =
            buildCrHouse(
                writingAgent.Id,
                'POL-G-1',
                period(2026, 1),
                'Manual',
                700,
                null
            );

        insert crHouse;

        Test.startTest();

        crHouse.Status__c =
            STATUS_RECONCILED;

        update crHouse;

        Test.stopTest();

        Integer anaCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Payment_Flow__c = 'Referral'
        ];

        System.assertEquals(
            0,
            anaCount,
            'Unrecognized payment model must be a no-op, not an error'
        );
    }
}