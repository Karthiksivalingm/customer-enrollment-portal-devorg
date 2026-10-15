/**
 * Class    : PaymentBatchAssemblyTest
 * Covers  : PaymentBatchAssembly (assemble() + Schedulable.execute())
 *
 * ══════════════════════════════════════════════════════════════════════════
 * SCHEMA NOTE — Commission_Record__c.Net_Amount__c is a FORMULA field
 * (Gross_Amount__c - Admin_Fee__c - Chargeback_Amount__c, per Object
 * Manager), confirmed not writeable. The test factory therefore never
 * assigns Net_Amount__c directly — it sets Gross_Amount__c, Admin_Fee__c,
 * and Chargeback_Amount__c instead and lets the platform compute
 * Net_Amount__c, then re-queries it where an assertion needs the computed
 * value (PaymentBatchAssembly.assemble() itself only reads Net_Amount__c,
 * so this doesn't affect the class under test — only how the test builds
 * data for it).
 *
 * SCHEMA ASSUMPTIONS FLAGGED — Commission_Record__c fields beyond the ones
 * PaymentBatchAssembly.cls itself references (Compensation_Type__c,
 * Payment_Flow__c, Status__c, Payment_Batch__c, Contact__c, Gross_Amount__c,
 * Net_Amount__c) plus Admin_Fee__c/Chargeback_Amount__c (needed only to
 * drive the Net_Amount__c formula above) are NOT visible in the class under
 * test, so this test data factory only ever sets those nine fields. If
 * Commission_Record__c has other required fields (validation rules,
 * required lookups, etc. — e.g. something like a Policy__c or
 * Effective_Date__c from earlier pieces of this project), record creation
 * below will fail on FIELD_CUSTOM_VALIDATION or REQUIRED_FIELD_MISSING and
 * those fields need adding to makeCommissionRecord(). I don't have that
 * describe output, so I'm not guessing at extra fields.
 *
 * KNOWN ORG BEHAVIOR — PaymentBatchAssembly.assemble() computes and inserts
 * correct Total_Gross__c/Total_Net__c on the new Payment_Batch__c (confirmed
 * via debug log — 350/315 for the CR-ana+override scenario). Immediately
 * after, its own Commission_Record__c-linking update fires pre-existing org
 * automation — CommissionRecordTrigger (BeforeUpdate) →
 * CommissionRecordTriggerHandler.beforeSave →
 * CommissionPaymentBatchRollupHandler.updatePaymentBatchTotals — which
 * re-derives those same two fields via its own aggregate SOQL and
 * overwrites them. Because that handler runs in a BeforeUpdate context, its
 * SOQL only sees each Commission_Record__c's pre-update (committed)
 * Payment_Batch__c value, not the one currently being saved — so for a
 * brand-new batch, on the very first records ever linked to it, the
 * aggregate matches 0 rows and the handler sets Total_Gross__c/Total_Net__c
 * to 0, clobbering what PaymentBatchAssembly just wrote. Record_Count__c is
 * untouched by that handler.
 * This means the FINAL, post-assemble() state of Total_Gross__c/Total_Net__c
 * on a newly-created batch is 0/0 in this org today — not the correct sums
 * PaymentBatchAssembly itself computed. Per instruction, this test class
 * only asserts the actual observed final state (0/0) rather than papering
 * over it, since the assemble() call under test is not the only thing
 * writing to these fields in this org. This is a genuine bug in
 * CommissionPaymentBatchRollupHandler (out of scope here — no access to
 * change it) and should be fixed there; the comments on the affected
 * assertions below call this out explicitly so it doesn't read as if 0
 * were the intended/correct value.
 * ══════════════════════════════════════════════════════════════════════════
 */
@isTest
private class PaymentBatchAssemblyTest {

    // ── Shared test-data constants, mirrored from the private statics in
    // PaymentBatchAssembly.cls (those are private, so re-declared here). ──
    private static final String COMPENSATION_TYPE_COMMISSION = 'Commission';
    private static final String COMPENSATION_TYPE_OVERRIDE   = 'Override';
    private static final String PAYMENT_FLOW_REFERRAL        = 'Referral';
    private static final String STATUS_RECONCILED            = 'Reconciled';
    private static final String STATUS_ESTIMATED             = 'Estimated';
    private static final String BATCH_TYPE_REFERRAL          = 'Referral';
    private static final String BATCH_STATUS_DRAFT           = 'Draft';

    // ────────────────────────────────────────────────────────────────
    // Test 1: one Contact with both Reconciled CR-ana AND pending
    // overrides gets exactly ONE Referral batch containing both,
    // correctly summed and linked back.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testAssemble_CrAnaAndOverrides_SameContact_OneBatch() {
        Contact agent = makeContact('Agent', 'One');
        insert agent;

        // Net_Amount__c = Gross_Amount__c - Admin_Fee__c - Chargeback_Amount__c (formula),
        // so drive it via Admin_Fee__c: 100-10=90, 200-20=180, 50-5=45 -> net total 315.
        List<Commission_Record__c> recs = new List<Commission_Record__c>{
            makeCommissionRecord(agent.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, null, 100, 10, 0),
            makeCommissionRecord(agent.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, null, 200, 20, 0),
            makeCommissionRecord(agent.Id, COMPENSATION_TYPE_OVERRIDE, null, STATUS_ESTIMATED, null, 50, 5, 0)
        };
        insert recs;

        Test.startTest();
        new PaymentBatchAssembly().assemble();
        Test.stopTest();

        List<Payment_Batch__c> batches = [
            SELECT Id, Batch_Type__c, Status__c, Total_Gross__c, Total_Net__c, Record_Count__c
            FROM Payment_Batch__c
        ];
        System.assertEquals(1, batches.size(), 'Expected exactly one batch for the single Contact.');
        Payment_Batch__c batch = batches[0];
        System.assertEquals(BATCH_TYPE_REFERRAL, batch.Batch_Type__c);
        System.assertEquals(BATCH_STATUS_DRAFT, batch.Status__c);
        System.assertEquals(3, batch.Record_Count__c, 'All 3 eligible records (2 CR-ana + 1 override) should be counted.');
        // NOTE: PaymentBatchAssembly itself computes and inserts Total_Gross__c=350 /
        // Total_Net__c=315 here (confirmed in debug log). This assertion checks the
        // FINAL state after CommissionPaymentBatchRollupHandler's BeforeUpdate rollup
        // runs on the linking update and overwrites both to 0 — see class header
        // "KNOWN ORG BEHAVIOR". This is the handler's bug, not PaymentBatchAssembly's;
        // asserting 0 here documents current org behavior, not intended behavior.
        System.assertEquals(0, batch.Total_Gross__c, 'Post-rollup-handler value; PaymentBatchAssembly itself sets this to 350 before the handler overwrites it.');
        System.assertEquals(0, batch.Total_Net__c, 'Post-rollup-handler value; PaymentBatchAssembly itself sets this to 315 before the handler overwrites it.');

        List<Commission_Record__c> linked = [SELECT Id, Payment_Batch__c FROM Commission_Record__c WHERE Id IN :recs];
        for (Commission_Record__c cr : linked) {
            System.assertEquals(batch.Id, cr.Payment_Batch__c, 'Every eligible record should be linked to the new batch.');
        }
    }

    // ────────────────────────────────────────────────────────────────
    // Test 2: two different Contacts produce two separate batches,
    // each scoped correctly to its own Contact's records.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testAssemble_MultipleContacts_SeparateBatches() {
        Contact agentA = makeContact('Agent', 'A');
        Contact agentB = makeContact('Agent', 'B');
        insert new List<Contact>{ agentA, agentB };

        insert new List<Commission_Record__c>{
            makeCommissionRecord(agentA.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, null, 100, 10, 0),
            makeCommissionRecord(agentB.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, null, 500, 50, 0)
        };

        Test.startTest();
        new PaymentBatchAssembly().assemble();
        Test.stopTest();

        // Total_Gross__c is 0 on both batches post-assemble() (see class header
        // "KNOWN ORG BEHAVIOR"), so it can't be used to tell them apart. Identify
        // each Contact's batch via its linked Commission_Record__c instead.
        Map<Id, Id> batchIdByContact = new Map<Id, Id>();
        for (Commission_Record__c cr : [SELECT Contact__c, Payment_Batch__c FROM Commission_Record__c WHERE Contact__c IN :new List<Id>{ agentA.Id, agentB.Id }]) {
            batchIdByContact.put(cr.Contact__c, cr.Payment_Batch__c);
        }
        System.assertNotEquals(null, batchIdByContact.get(agentA.Id), 'Agent A\'s record should be linked to a batch.');
        System.assertNotEquals(null, batchIdByContact.get(agentB.Id), 'Agent B\'s record should be linked to a batch.');
        System.assertNotEquals(batchIdByContact.get(agentA.Id), batchIdByContact.get(agentB.Id), 'Each Contact should get its own, separate batch.');

        List<Payment_Batch__c> batches = [SELECT Id, Total_Gross__c, Record_Count__c FROM Payment_Batch__c];
        System.assertEquals(2, batches.size(), 'Expected one batch per distinct Contact.');
        for (Payment_Batch__c batch : batches) {
            System.assertEquals(1, batch.Record_Count__c, 'Each batch should contain exactly its own Contact\'s single record.');
            // See class header "KNOWN ORG BEHAVIOR" — PaymentBatchAssembly sets 100/500
            // respectively, but the rollup handler's BeforeUpdate query overwrites both to 0.
            System.assertEquals(0, batch.Total_Gross__c, 'Post-rollup-handler value, not what PaymentBatchAssembly itself computed.');
        }
    }

    // ────────────────────────────────────────────────────────────────
    // Test 3: exclusion filters — already-batched, wrong Compensation_Type__c,
    // wrong Status__c, wrong Payment_Flow__c, and null Contact__c records
    // must all be skipped and left untouched.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testAssemble_ExcludesIneligibleRecords() {
        Contact agent = makeContact('Agent', 'Excl');
        insert agent;

        Payment_Batch__c existingBatch = new Payment_Batch__c(
            Batch_Type__c = BATCH_TYPE_REFERRAL,
            Status__c = BATCH_STATUS_DRAFT,
            Payment_Period__c = '2026-07'
        );
        insert existingBatch;

        Commission_Record__c alreadyBatched = makeCommissionRecord(
            agent.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, existingBatch.Id, 999, 0, 0);
        Commission_Record__c wrongCompType = makeCommissionRecord(
            agent.Id, 'Bonus', PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, null, 999, 0, 0);
        Commission_Record__c wrongCrStatus = makeCommissionRecord(
            agent.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, 'Estimated', null, 999, 0, 0);
        Commission_Record__c wrongFlow = makeCommissionRecord(
            agent.Id, COMPENSATION_TYPE_COMMISSION, 'Direct', STATUS_RECONCILED, null, 999, 0, 0);
        Commission_Record__c wrongOverrideStatus = makeCommissionRecord(
            agent.Id, COMPENSATION_TYPE_OVERRIDE, null, 'Paid', null, 999, 0, 0);

        insert new List<Commission_Record__c>{
            alreadyBatched, wrongCompType, wrongCrStatus, wrongFlow, wrongOverrideStatus
        };

        Test.startTest();
        new PaymentBatchAssembly().assemble();
        Test.stopTest();

        // No new batch should have been created — every candidate record was ineligible.
        List<Payment_Batch__c> allBatches = [SELECT Id FROM Payment_Batch__c];
        System.assertEquals(1, allBatches.size(), 'Only the pre-existing batch should exist; nothing new assembled.');

        List<Commission_Record__c> untouched = [
            SELECT Id, Payment_Batch__c FROM Commission_Record__c
            WHERE Id IN :new List<Id>{ wrongCompType.Id, wrongCrStatus.Id, wrongFlow.Id, wrongOverrideStatus.Id }
        ];
        for (Commission_Record__c cr : untouched) {
            System.assertEquals(null, cr.Payment_Batch__c, 'Ineligible records must not be linked to any batch.');
        }
    }

    // ────────────────────────────────────────────────────────────────
    // Test 4: no eligible records at all -> assemble() is a no-op,
    // exercising the early `if (recordsByContact.isEmpty()) return;` path.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testAssemble_NoEligibleRecords_NoBatchesCreated() {
        Test.startTest();
        new PaymentBatchAssembly().assemble();
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Payment_Batch__c], 'No batches should be created when nothing is eligible.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test 5: Payment_Period__c on the new batch reflects the assembly
    // run date (current month), per header decision #4 — not any
    // underlying commission record's own period.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testAssemble_PaymentPeriod_IsCurrentMonth() {
        Contact agent = makeContact('Agent', 'Period');
        insert agent;
        insert makeCommissionRecord(agent.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, null, 10, 1, 0);

        Test.startTest();
        new PaymentBatchAssembly().assemble();
        Test.stopTest();

        Date today = Date.today();
        String mm = today.month() < 10 ? '0' + today.month() : String.valueOf(today.month());
        String expectedPeriod = today.year() + '-' + mm;

        Payment_Batch__c batch = [SELECT Payment_Period__c FROM Payment_Batch__c LIMIT 1];
        System.assertEquals(expectedPeriod, batch.Payment_Period__c);
    }

    // ────────────────────────────────────────────────────────────────
    // Test 6: the Schedulable entry point (System.schedule / execute)
    // actually triggers assembly, not just assemble() called directly.
    // ────────────────────────────────────────────────────────────────
    @isTest
    static void testScheduledExecute_RunsAssembly() {
        Contact agent = makeContact('Agent', 'Sched');
        insert agent;
        insert makeCommissionRecord(agent.Id, COMPENSATION_TYPE_COMMISSION, PAYMENT_FLOW_REFERRAL, STATUS_RECONCILED, null, 1000, 100, 0);

        // Cron matches the header's documented schedule: 11:00 AM ET, 12th of each month.
        String cronExpr = '0 0 11 12 * ?';

        Test.startTest();
        System.schedule('PaymentBatchAssemblyTest Job', cronExpr, new PaymentBatchAssembly());
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Payment_Batch__c], 'Scheduled execute() should invoke assemble() and create a batch.');
    }

    // ────────────────────────────────────────────────────────────────
    // Test data factories
    // ────────────────────────────────────────────────────────────────
    // Email, NPN__c, and Agent_Status__c are all required on Contact in this
    // org (FIELD_CUSTOM_VALIDATION_EXCEPTION otherwise). Agent_Status__c must
    // be 'Onboarding' at creation time per the validation rule's own message
    // ("Agent Status must be selected as Onboarding while creating Agent
    // record") — field API name inferred from the rule's label, so if it's
    // actually named differently this line needs the real API name swapped in.
    private static Integer contactCounter = 0;
    private static Contact makeContact(String firstName, String lastName) {
        contactCounter++;
        String email = 'pbatest' + contactCounter + '@example.test';
        String npn = '9999' + String.valueOf(contactCounter).leftPad(6, '0');
        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            NPN__c = npn,
            Agent_Status__c = 'Onboarding'
        );
    }

    // Net_Amount__c is a FORMULA field (Gross_Amount__c - Admin_Fee__c -
    // Chargeback_Amount__c) and cannot be set directly — drive it via
    // adminFee/chargebackAmount instead and let the platform compute it.
    private static Commission_Record__c makeCommissionRecord(
        Id contactId,
        String compType,
        String paymentFlow,
        String status,
        Id paymentBatchId,
        Decimal grossAmount,
        Decimal adminFee,
        Decimal chargebackAmount
    ) {
        return new Commission_Record__c(
            Contact__c = contactId,
            Compensation_Type__c = compType,
            Payment_Flow__c = paymentFlow,
            Status__c = status,
            Payment_Batch__c = paymentBatchId,
            Gross_Amount__c = grossAmount,
            Admin_Fee__c = adminFee,
            Chargeback_Amount__c = chargebackAmount
        );
    }
}