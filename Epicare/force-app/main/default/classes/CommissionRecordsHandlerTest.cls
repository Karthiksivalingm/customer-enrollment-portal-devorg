@isTest
private class CommissionRecordsHandlerTest {

    // NOTE ON SCOPE: CommissionRecordHandler is not wired to the
    // CommissionRecordTrigger shown to us (that trigger only calls
    // CommissionRecordTriggerHandler.beforeSave and
    // CommissionPaymentBatchRollupHandler.updatePaymentBatchTotals).
    // We don't know what trigger (if any) actually calls
    // CommissionRecordHandler.handleBeforeInsert/handleAfterInsert in
    // this org, so every test here calls those methods DIRECTLY,
    // matching what a before/after-insert trigger would do, instead of
    // relying on `insert` to invoke them implicitly. This makes the
    // tests correct regardless of trigger wiring.

    // ─── Constants — MUST mirror CommissionRecordHandler exactly ────────────
    // (previous test class had EX_UNKNOWN_POLICY = 'Unknown Policy' (space),
    // but the handler's actual constant is 'Unknown_Policy' (underscore) —
    // that mismatch let a silently-swallowed DML failure pass as "handled
    // cleanly". Fixed here to the real value so the assertion is honest.)
    private static final String STATUS_RECONCILED   = 'Reconciled';
    private static final String STATUS_ESTIMATED    = 'Estimated';
    private static final String EX_UNDERPAID        = 'Underpaid';
    private static final String EX_OVERPAID         = 'Overpaid';
    private static final String EX_UNKNOWN_POLICY   = 'Unknown_Policy';
    private static final String EX_PAYMENT_MISMATCH = 'Payment Flow Mismatch';

    // Appointment__c.Payment_Flow__c values (underscore style)
    private static final String APPT_FLOW_PENDING = 'Pending';
    private static final String APPT_FLOW_DIRECT  = 'Carrier_Direct';

    // Commission_Record__c.Payment_Flow__c values (space style)
    private static final String CR_FLOW_DIRECT = 'Carrier Direct';

    private static Id agentId;
    private static Id carrierId;
    private static Id agencyId;

    @testSetup
    static void setupTestData() {
        Account agency = new Account(Name = 'Test Agency');
        insert agency;

        Contact agent = new Contact(
            LastName           = 'Test Agent',
            AccountId          = agency.Id,
            Email              = 'testagent@example.com',
            NPN__c             = '1234567890',
            Agent_Status__c    = 'Onboarding',
            Insurance_Types__c = 'Medicare'
        );
        insert agent;

        agent.Agent_Status__c = 'Active';
        update agent;

        Carrier__c carrier = new Carrier__c(
            Name                           = 'Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare'
        );
        insert carrier;

        // Status__c = 'Request' explicitly: the org's Require_Green_Onboarding_Semaphore
        // validation rule on Appointment__c blocks any Status__c OTHER than 'Request'
        // unless Agent__r.Overall_Semaphore__c = 'Green' or Agent__r.Bypass_VR__c is
        // true. Our test Contact never completes the underlying onboarding-completion
        // fields that drive that formula, so leaving Status__c blank (which the rule's
        // NOT(ISPICKVAL(Status__c, "Request")) treats as "not Request") trips the rule.
        // Staying at 'Request' avoids needing to fake the whole completion chain.
        Appointment__c directAppt = new Appointment__c(
            Agent__c            = agent.Id,
            Carrier__c          = carrier.Id,
            Agency__c           = agency.Id,
            Line_of_Business__c = 'Medicare',
            State_s__c          = 'CA',
            Status__c           = 'Request',
            Payment_Flow__c     = APPT_FLOW_DIRECT
        );
        insert directAppt;

        Appointment__c pendingAppt = new Appointment__c(
            Agent__c            = agent.Id,
            Carrier__c          = carrier.Id,
            Agency__c           = agency.Id,
            Line_of_Business__c = 'Medicare',
            State_s__c          = 'CA',
            Status__c           = 'Request',
            Payment_Flow__c     = APPT_FLOW_PENDING
        );
        insert pendingAppt;
    }

    private static void loadIds() {
        if (agentId == null) {
            agentId   = [SELECT Id FROM Contact   LIMIT 1].Id;
            carrierId = [SELECT Id FROM Carrier__c LIMIT 1].Id;
            agencyId  = [SELECT Id FROM Account   LIMIT 1].Id;
        }
    }

    private static Appointment__c getDirectAppt() {
        return [SELECT Id FROM Appointment__c WHERE Payment_Flow__c = :APPT_FLOW_DIRECT LIMIT 1];
    }

    private static Appointment__c getPendingAppt() {
        return [SELECT Id FROM Appointment__c WHERE Payment_Flow__c = :APPT_FLOW_PENDING LIMIT 1];
    }

    private static Commission_Record__c buildCR(
        String status, String policyNumber, String paymentPeriod, Decimal grossAmount,
        Id appointmentId, String paymentFlow
    ) {
        loadIds();
        return new Commission_Record__c(
            Status__c             = status,
            Policy_Number__c      = policyNumber,
            Payment_Period__c     = paymentPeriod,
            Gross_Amount__c       = grossAmount,
            Admin_Fee__c          = 0,
            Chargeback_Amount__c  = 0,
            Agent__c              = agentId,
            Carrier__c            = carrierId,
            Agency__c             = agencyId,
            LOB__c                = 'Medicare',
            Compensation_Type__c  = 'New Business',
            Source__c             = 'Manual',
            Effective_Date__c     = Date.today(),
            Payment_Date__c       = Date.today(),
            Appointment__c        = appointmentId,
            Payment_Flow__c       = paymentFlow
        );
    }

    // Runs the full before+insert+after cycle exactly like a real trigger
    // would, for a single-record scenario, and returns the inserted record's
    // fresh Id (or null if the row was rejected via addError).
    private static Id insertThroughHandler(Commission_Record__c rec) {
        List<Commission_Record__c> singleRecordList = new List<Commission_Record__c>{ rec };
        CommissionRecordHandler.handleBeforeInsert(singleRecordList);

        Database.SaveResult sr = Database.insert(rec, false);
        if (!sr.isSuccess()) return null;

        CommissionRecordHandler.handleAfterInsert(singleRecordList);
        return rec.Id;
    }

    // ─── handleBeforeInsert ───────────────────────────────────────────────

    @isTest
    static void testBeforeInsert_StampsPaymentFlowFromAppointment() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c cr = buildCR(STATUS_ESTIMATED, 'POL001', '2024-01', 100.00, appt.Id, null);

        Test.startTest();
        Id newId = insertThroughHandler(cr);
        Test.stopTest();

        Assert.isNotNull(newId, 'Record with a resolvable Direct appointment should insert successfully');
        Commission_Record__c result = [SELECT Payment_Flow__c FROM Commission_Record__c WHERE Id = :newId];
        Assert.areEqual(CR_FLOW_DIRECT, result.Payment_Flow__c,
            'Payment_Flow__c should be stamped from the Appointment\'s Payment_Flow__c, mapped to Commission_Record__c\'s value set');
    }

    @isTest
    static void testBeforeInsert_PendingFlow_TrackedInIndexes() {
        Appointment__c appt = getPendingAppt();
        List<Commission_Record__c> records = new List<Commission_Record__c>{
            buildCR(STATUS_ESTIMATED, 'POL001', '2024-01', 100.00, appt.Id, null)
        };

        Test.startTest();
        CommissionRecordHandler.handleBeforeInsert(records);
        Test.stopTest();

        Assert.isTrue(CommissionRecordHandler.pendingFlowIndexes.contains(0),
            'Index 0 should be tracked in pendingFlowIndexes when the source Appointment is Pending');
    }

    @isTest
    static void testBeforeInsert_NoAppointment_RowRejected() {
        // No Appointment__c and no Payment_Flow__c supplied -> stays blank
        // -> handleBeforeInsert's required-field guard calls addError.
        Commission_Record__c cr = buildCR(STATUS_ESTIMATED, 'POL001', '2024-01', 100.00, null, null);

        Test.startTest();
        Id newId = insertThroughHandler(cr);
        Test.stopTest();

        Assert.isNull(newId, 'Row with no way to resolve Payment_Flow__c should be rejected by handleBeforeInsert');
    }

    @isTest
    static void testBeforeInsert_FlowAlreadySet_NotOverwritten() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c cr = buildCR(STATUS_ESTIMATED, 'POL001', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        Id newId = insertThroughHandler(cr);
        Test.stopTest();

        Commission_Record__c result = [SELECT Payment_Flow__c FROM Commission_Record__c WHERE Id = :newId];
        Assert.areEqual(CR_FLOW_DIRECT, result.Payment_Flow__c,
            'A pre-set Payment_Flow__c should not be overwritten by the Appointment lookup');
    }

    // ─── handleAfterInsert — Payment_Flow_Mismatch soft-flag ───────────────

    @isTest
    static void testAfterInsert_PendingFlow_CreatesPaymentMismatchException() {
        // Exercises handleAfterInsert directly against a record we insert
        // with Payment_Flow__c already set to a VALID Commission_Record__c
        // value, so we can isolate the exception-creation logic from the
        // separate (and likely broken) Appointment-stamp-to-picklist path.
        Appointment__c appt = getPendingAppt();
        Commission_Record__c cr = buildCR(STATUS_ESTIMATED, 'POL_PENDING_001', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);
        insert cr;

        // Re-point Payment_Flow__c on the *queried* copy passed into
        // handleAfterInsert isn't possible (it re-queries by Id), so instead
        // update the persisted row to 'Pending' directly to simulate the
        // state handleBeforeInsert's stamp is trying to produce.
        cr.Payment_Flow__c = APPT_FLOW_PENDING;
        Database.SaveResult sr = Database.update(cr, false);

        Test.startTest();
        CommissionRecordHandler.handleAfterInsert(new List<Commission_Record__c>{ cr });
        Test.stopTest();

        if (!sr.isSuccess()) {
            // Confirms the suspected bug: 'Pending' is not a valid value for
            // Commission_Record__c.Payment_Flow__c, so the mismatch exception
            // can never actually be created via the intended flow.
            Assert.fail('Commission_Record__c.Payment_Flow__c rejected the value \'' + APPT_FLOW_PENDING
                + '\' — the Appointment-to-CommissionRecord Payment_Flow__c stamp in handleBeforeInsert '
                + 'writes a value your picklist doesn\'t accept. Fix the value mapping in handleBeforeInsert, '
                + 'or add \'Pending\' to Commission_Record__c.Payment_Flow__c\'s picklist.');
        }

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c FROM Commission_Exception__c WHERE Commission_Record__c = :cr.Id
        ];
        Assert.areEqual(1, exceptions.size(), 'One Payment Flow Mismatch exception should be created for a Pending flow');
        Assert.areEqual(EX_PAYMENT_MISMATCH, exceptions[0].Exception_Type__c);
    }

    // ─── handleAfterInsert — reconciliation matching ───────────────────────

    @isTest
    static void testAfterInsert_WithinTolerance_EstimatedMarkedReconciled() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c estimated = buildCR(STATUS_ESTIMATED, 'POL_TOL_001', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);
        insertThroughHandler(estimated);

        Commission_Record__c reconciled = buildCR(STATUS_RECONCILED, 'POL_TOL_001', '2024-01', 100.30, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        Id newId = insertThroughHandler(reconciled);
        Test.stopTest();

        Assert.isNotNull(newId);
        Commission_Record__c updatedEstimated = [SELECT Status__c FROM Commission_Record__c WHERE Id = :estimated.Id];
        Assert.areEqual(STATUS_RECONCILED, updatedEstimated.Status__c,
            'Estimated record should flip to Reconciled when the actual amount is within the $0.50 tolerance');

        Integer exCount = [SELECT COUNT() FROM Commission_Exception__c WHERE Commission_Record__c = :newId];
        Assert.areEqual(0, exCount, 'No exception should be raised when the match is within tolerance');
    }

    @isTest
    static void testAfterInsert_ExactToleranceBoundary_EstimatedMarkedReconciled() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c estimated = buildCR(STATUS_ESTIMATED, 'POL_EXACT_TOL', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);
        insertThroughHandler(estimated);

        Commission_Record__c reconciled = buildCR(STATUS_RECONCILED, 'POL_EXACT_TOL', '2024-01', 100.50, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        insertThroughHandler(reconciled);
        Test.stopTest();

        Commission_Record__c updatedEstimated = [SELECT Status__c FROM Commission_Record__c WHERE Id = :estimated.Id];
        Assert.areEqual(STATUS_RECONCILED, updatedEstimated.Status__c,
            'Exactly $0.50 delta is inclusive of tolerance (delta <= TOLERANCE) and should reconcile');
    }

    @isTest
    static void testAfterInsert_JustOverTolerance_OverpaidException() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c estimated = buildCR(STATUS_ESTIMATED, 'POL_OVER_TOL', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);
        insertThroughHandler(estimated);

        Commission_Record__c reconciled = buildCR(STATUS_RECONCILED, 'POL_OVER_TOL', '2024-01', 100.51, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        Id newId = insertThroughHandler(reconciled);
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c, Expected_Amount__c, Actual_Amount__c
            FROM Commission_Exception__c WHERE Commission_Record__c = :newId
        ];
        Assert.areEqual(1, exceptions.size(), 'A delta just over tolerance should raise exactly one exception');
        Assert.areEqual(EX_OVERPAID, exceptions[0].Exception_Type__c);
        Assert.areEqual(100.00, exceptions[0].Expected_Amount__c);
        Assert.areEqual(100.51, exceptions[0].Actual_Amount__c);
    }

    @isTest
    static void testAfterInsert_ActualLessThanEstimated_UnderpaidException() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c estimated = buildCR(STATUS_ESTIMATED, 'POL_UNDER_001', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);
        insertThroughHandler(estimated);

        Commission_Record__c reconciled = buildCR(STATUS_RECONCILED, 'POL_UNDER_001', '2024-01', 90.00, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        Id newId = insertThroughHandler(reconciled);
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c FROM Commission_Exception__c WHERE Commission_Record__c = :newId
        ];
        Assert.areEqual(1, exceptions.size());
        Assert.areEqual(EX_UNDERPAID, exceptions[0].Exception_Type__c);
    }

    @isTest
    static void testAfterInsert_ActualMoreThanEstimated_OverpaidException() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c estimated = buildCR(STATUS_ESTIMATED, 'POL_OVER_001', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);
        insertThroughHandler(estimated);

        Commission_Record__c reconciled = buildCR(STATUS_RECONCILED, 'POL_OVER_001', '2024-01', 115.00, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        Id newId = insertThroughHandler(reconciled);
        Test.stopTest();

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c FROM Commission_Exception__c WHERE Commission_Record__c = :newId
        ];
        Assert.areEqual(1, exceptions.size());
        Assert.areEqual(EX_OVERPAID, exceptions[0].Exception_Type__c);
    }

    @isTest
    static void testAfterInsert_NoEstimatedMatch_UnknownPolicyException() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c reconciled = buildCR(STATUS_RECONCILED, 'POL_NO_MATCH_XYZ', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        Id newId = insertThroughHandler(reconciled);
        Test.stopTest();

        Assert.isNotNull(newId, 'Row should still insert even with no matching Estimated record (soft-flag behavior)');

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c FROM Commission_Exception__c WHERE Commission_Record__c = :newId
        ];
        Assert.areEqual(1, exceptions.size(),
            'An Unknown_Policy exception should be created. If this fails, Unknown_Policy is likely not a valid '
            + 'Exception_Type__c picklist value in this org — the current handler code silently swallows that DML error.');
        Assert.areEqual(EX_UNKNOWN_POLICY, exceptions[0].Exception_Type__c);
    }

    @isTest
    static void testAfterInsert_NonReconciledStatus_NoException() {
        Appointment__c appt = getDirectAppt();
        Commission_Record__c cr = buildCR(STATUS_ESTIMATED, 'POL_EST_001', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT);

        Test.startTest();
        Id newId = insertThroughHandler(cr);
        Test.stopTest();

        Integer exCount = [SELECT COUNT() FROM Commission_Exception__c WHERE Commission_Record__c = :newId];
        Assert.areEqual(0, exCount, 'Only Reconciled-status rows should ever be matched against Estimated rows');
    }

    @isTest
    static void testAfterInsert_BulkReconciled_MixedResults() {
        Appointment__c appt = getDirectAppt();

        List<Commission_Record__c> estimatedRecords = new List<Commission_Record__c>{
            buildCR(STATUS_ESTIMATED, 'POL_MIX_A', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT),
            buildCR(STATUS_ESTIMATED, 'POL_MIX_B', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT),
            buildCR(STATUS_ESTIMATED, 'POL_MIX_C', '2024-01', 100.00, appt.Id, CR_FLOW_DIRECT)
        };
        CommissionRecordHandler.handleBeforeInsert(estimatedRecords);
        insert estimatedRecords;
        CommissionRecordHandler.handleAfterInsert(estimatedRecords);

        List<Commission_Record__c> reconciledRecords = new List<Commission_Record__c>{
            buildCR(STATUS_RECONCILED, 'POL_MIX_A', '2024-01', 100.25, appt.Id, CR_FLOW_DIRECT), // within tolerance
            buildCR(STATUS_RECONCILED, 'POL_MIX_B', '2024-01', 80.00,  appt.Id, CR_FLOW_DIRECT),  // underpaid
            buildCR(STATUS_RECONCILED, 'POL_MIX_C', '2024-01', 120.00, appt.Id, CR_FLOW_DIRECT)   // overpaid
        };

        Test.startTest();
        CommissionRecordHandler.handleBeforeInsert(reconciledRecords);
        insert reconciledRecords;
        CommissionRecordHandler.handleAfterInsert(reconciledRecords);
        Test.stopTest();

        Commission_Record__c polA = [SELECT Status__c FROM Commission_Record__c WHERE Id = :estimatedRecords[0].Id];
        Assert.areEqual(STATUS_RECONCILED, polA.Status__c);

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c FROM Commission_Exception__c
            WHERE Commission_Record__c IN :reconciledRecords ORDER BY Exception_Type__c
        ];
        Assert.areEqual(2, exceptions.size(), 'POL_MIX_B (underpaid) and POL_MIX_C (overpaid) should each raise one exception');

        Set<String> exTypes = new Set<String>();
        for (Commission_Exception__c ex : exceptions) exTypes.add(ex.Exception_Type__c);
        Assert.isTrue(exTypes.contains(EX_UNDERPAID));
        Assert.isTrue(exTypes.contains(EX_OVERPAID));
    }

    @isTest
    static void testBulkInsert_200Records_NoGovernorLimitErrors() {
        loadIds();
        Appointment__c appt = getDirectAppt();

        List<Commission_Record__c> records = new List<Commission_Record__c>();
        for (Integer i = 0; i < 200; i++) {
            records.add(buildCR(STATUS_ESTIMATED, 'POL_BULK_' + i, '2024-01', 100.00, appt.Id, null));
        }

        Test.startTest();
        CommissionRecordHandler.handleBeforeInsert(records);
        insert records;
        CommissionRecordHandler.handleAfterInsert(records);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Commission_Record__c WHERE Appointment__c = :appt.Id];
        Assert.areEqual(200, count);
    }
}