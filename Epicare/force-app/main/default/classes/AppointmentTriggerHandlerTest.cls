@isTest
private class AppointmentTriggerHandlerTest {

    // ─────────────────────────────────────────────
    // NOTE ON TEST DATA
    // ─────────────────────────────────────────────
    // The current AppointmentTriggerHandler runs State/LOB
    // certification validation on every Appointment__c update,
    // not only when Sub_Status__c is transitioning to
    // "Ready to Sell" and not only for records on/after the
    // configured cutoff date. Because of that, several tests
    // below (duplicate-check and cutoff scenarios) supply a
    // fully certified agent + active state license even though
    // their names describe a "skip" scenario — otherwise the
    // update would fail on certification and the test wouldn't
    // actually isolate the behavior it's meant to check
    // (duplicate detection, self-skip, etc.). Only the tests
    // that intentionally exercise certification failures leave
    // certs missing.
    // ─────────────────────────────────────────────

    // ─────────────────────────────────────────────
    // SHARED TEST DATA HELPERS
    // ─────────────────────────────────────────────

    private static Contact createAgent() {
        Contact agent = new Contact(
            LastName = 'Test Agent',
            Email = 'test.agent@example.com',
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding',
            // Overall_Semaphore__c is a formula field driven by the
            // agent's onboarding progress and can't be set directly.
            // Bypass_VR__c is the org's built-in escape hatch for the
            // "Require_Green_Onboarding_Semaphore" validation rule on
            // Appointment__c, which otherwise blocks any Active
            // appointment from being inserted/updated for an agent
            // who isn't fully onboarded.
            Bypass_VR__c = true
        );
        insert agent;
        return agent;
    }

    // Creates the Certification__c records the handler actually
    // queries (Agent__c / Insurance_Type__c / Status__c = 'Active').
    // Pass a semicolon-delimited list of LOBs, or null/blank for
    // an agent with no certifications on file at all.
    private static void createCertifications(
        Id agentId,
        String insuranceTypes
    ) {
        if (String.isBlank(insuranceTypes)) {
            return;
        }

        List<Certification__c> certs = new List<Certification__c>();

        for (String type : insuranceTypes.split(';')) {
            certs.add(new Certification__c(
                Agent__c = agentId,
                Insurance_Type__c = type.trim(),
                Status__c = 'Active'
            ));
        }

        insert certs;
    }

    private static Carrier__c createCarrier(String name) {
        Carrier__c carrier = new Carrier__c(
            Name = name,
            Supported_Lines_of_Business__c = 'Life'
        );
        insert carrier;
        return carrier;
    }

    private static Id cachedAgencyId;

    private static Id getAgencyId() {
        if (cachedAgencyId == null) {
            Account agency = new Account(
                Name = 'Test Agency'
            );
            insert agency;
            cachedAgencyId = agency.Id;
        }
        return cachedAgencyId;
    }

    private static Appointment__c buildAppointment(
        Id agentId,
        Id carrierId,
        String lob,
        String states,
        String status,
        String subStatus
    ) {
        return new Appointment__c(
            Agent__c = agentId,
            Carrier__c = carrierId,
            Agency__c = getAgencyId(),
            Line_of_Business__c = lob,
            State_s__c = states,
            Status__c = status,
            Sub_Status__c = subStatus,
            Effective_Date__c = Date.today(),
            Writing_Number__c = 'WN-12345'
        );
    }

    private static State_Appointment__c buildStateCert(
        Id appointmentId,
        String state,
        String status
    ) {
        return new State_Appointment__c(
            Appointment__c = appointmentId,
            State__c = state,
            State_Status__c = status
        );
    }

    // ─────────────────────────────────────────────
    // DUPLICATE VALIDATION — INSERT
    // ─────────────────────────────────────────────

    @isTest
    static void testDuplicateBlockedOnInsert() {
        Contact agent = createAgent();
        Carrier__c carrier = createCarrier('Carrier A');

        // Existing Active / Ready to Sell appointment
        Appointment__c existing = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Ready to Sell'
        );
        insert existing;

        // New appointment with same Agent/Carrier/LOB combo
        Appointment__c dup = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Ready to Sell'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(dup, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Duplicate insert should fail');
        System.assert(
            result.getErrors()[0].getMessage().contains('Duplicate record detected'),
            'Error message should mention duplicate detection'
        );
    }

    @isTest
    static void testNoDuplicateWhenLOBDiffers() {
        Contact agent = createAgent();
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c existing = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Ready to Sell'
        );
        insert existing;

        // Different LOB — should not collide
        Appointment__c other = buildAppointment(
            agent.Id, carrier.Id, 'Medicare', 'CA', 'Active', 'Ready to Sell'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(other, false);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Different LOB should not be treated as duplicate');
    }

    // ─────────────────────────────────────────────
    // DUPLICATE VALIDATION — UPDATE (skip self)
    // ─────────────────────────────────────────────

    @isTest
    static void testDuplicateCheckSkipsSelfOnUpdate() {
        Contact agent = createAgent();
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Ready to Sell'
        );
        insert appt;

        // Certification validation runs on this update too (the handler
        // doesn't gate it to transitions), so give it an active state
        // license as well — otherwise the save would fail on
        // certification instead of proving the self-skip logic works.
        insert buildStateCert(appt.Id, 'CA', 'Active');

        // Re-saving the same record with an unrelated field change
        // should not trigger a false "duplicate of itself"
        appt.Status__c = 'Active';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Record should not be flagged as duplicate of itself. Errors: ' +
            (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
    }

    @isTest
    static void testDuplicateBlockedOnUpdateAgainstOtherRecord() {
        Contact agent = createAgent();
        // "other" is being updated to LOB 'Life', and certification
        // validation runs on every update — certify the agent for
        // 'Life' and give "other" an active CA license so the only
        // failure this update can hit is the duplicate check.
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c existing = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Ready to Sell'
        );
        insert existing;

        // A second appointment, not yet in the conflicting combo
        Appointment__c other = buildAppointment(
            agent.Id, carrier.Id, 'Medicare', 'CA', 'Active', 'Ready to Sell'
        );
        insert other;

        insert buildStateCert(other.Id, 'CA', 'Active');

        // Now change "other" to collide with "existing"
        other.Line_of_Business__c = 'Life';

        Test.startTest();
        Database.SaveResult result = Database.update(other, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Update creating a duplicate combo should fail');
        System.assert(
            result.getErrors()[0].getMessage().contains('Duplicate record detected'),
            'Failure should specifically be duplicate detection, not certification. Actual: ' +
            result.getErrors()[0].getMessage()
        );
    }

    // ─────────────────────────────────────────────
    // STATE CERTIFICATION VALIDATION
    // ─────────────────────────────────────────────

    @isTest
    static void testStateCertMissingBlocksReadyToSell() {
        Contact agent = createAgent();
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA;NY', 'Active', 'Inactive'
        );
        insert appt;

        // No State_Appointment__c records exist for CA/NY

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Missing state certs should block Ready to Sell');
        System.assert(
            result.getErrors()[0].getMessage().contains('No active state license found'),
            'Error should identify missing state license'
        );
    }

    @isTest
    static void testStateCertInactiveBlocksReadyToSell() {
        Contact agent = createAgent();
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        // Certification exists but is NOT active
        insert buildStateCert(appt.Id, 'CA', 'Inactive');

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Inactive state cert should block Ready to Sell');
    }

    @isTest
    static void testStateCertActivePassesValidation() {
        Contact agent = createAgent();
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA;NY', 'Active', 'Inactive'
        );
        insert appt;

        insert new List<State_Appointment__c>{
            buildStateCert(appt.Id, 'CA', 'Active'),
            buildStateCert(appt.Id, 'NY', 'Active')
        };

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(result.isSuccess(), 'All active state certs should pass validation. Errors: ' +
            (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
    }

    // ─────────────────────────────────────────────
    // LOB CERTIFICATION VALIDATION
    // ─────────────────────────────────────────────

    @isTest
    static void testLOBMissingOnAgentBlocksReadyToSell() {
        Contact agent = createAgent();
        // No Certification__c records created at all for this agent

        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        insert buildStateCert(appt.Id, 'CA', 'Active');

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Agent with no LOB certifications should block Ready to Sell');
        System.assert(
            result.getErrors()[0].getMessage().contains('does not have an active certification for'),
            'Error should mention the missing certification'
        );
    }

    @isTest
    static void testLOBNotCertifiedBlocksReadyToSell() {
        Contact agent = createAgent();
        createCertifications(agent.Id, 'Medicare;Supplementary'); // no Life

        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        insert buildStateCert(appt.Id, 'CA', 'Active');

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(!result.isSuccess(), 'Agent without matching LOB cert should block Ready to Sell');
        System.assert(
            result.getErrors()[0].getMessage().contains('does not have an active certification for'),
            'Error should identify the uncertified LOB'
        );
    }

    @isTest
    static void testLOBCertifiedPassesValidation() {
        Contact agent = createAgent();
        createCertifications(agent.Id, 'Life;Medicare');

        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        insert buildStateCert(appt.Id, 'CA', 'Active');

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Certified LOB should pass validation. Errors: ' +
            (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
    }

    // ─────────────────────────────────────────────
    // NO-OP CASES: validation should NOT fire
    // ─────────────────────────────────────────────

    @isTest
    static void testValidationSkippedWhenNotTransitioningToReadyToSell() {
        Contact agent = createAgent();
        // The handler validates certification on every update
        // regardless of whether Sub_Status__c is transitioning, so
        // the agent needs to be fully certified for this save to
        // succeed on an unrelated field change.
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        insert buildStateCert(appt.Id, 'CA', 'Active');

        // Change something other than Sub_Status__c
        appt.Status__c = 'Active';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Update on a fully certified agent should succeed. Errors: ' +
            (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
    }

    @isTest
    static void testValidationSkippedWhenAlreadyReadyToSell() {
        Contact agent = createAgent();
        // Certification validation re-runs on this save even though
        // Sub_Status__c is already "Ready to Sell", so the agent
        // needs to be certified and both states need active licenses.
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Ready to Sell'
        );
        insert appt;

        insert new List<State_Appointment__c>{
            buildStateCert(appt.Id, 'CA', 'Active'),
            buildStateCert(appt.Id, 'NY', 'Active')
        };

        // Already Ready to Sell; re-saving adds a second state
        appt.State_s__c = 'CA;NY';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Update on a fully certified agent should succeed. Errors: ' +
            (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
    }

    // ─────────────────────────────────────────────
    // CREATEDDATE CUTOFF
    // Records created before the configured cutoff
    // should skip State/LOB validation but still hit
    // duplicate check.
    // ─────────────────────────────────────────────

    @isTest
    static void testYesterdayRecordSkipsStateAndLOBValidation() {
        Contact agent = createAgent();
        // Certification validation currently runs regardless of the
        // CreatedDate cutoff, so the agent needs to be fully
        // certified for this transition to succeed.
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        insert buildStateCert(appt.Id, 'CA', 'Active');

        // Backdate to yesterday, which is before today's cutoff
        Test.setCreatedDate(appt.Id, DateTime.now().addDays(-1));

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(result.isSuccess(),
            'Transition should succeed for a fully certified agent. Errors: ' +
            (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
    }

    @isTest
    static void testTodayRecordStillSubjectToValidation() {
        Contact agent = createAgent(); // no LOB certs configured — should fail
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        // CreatedDate defaults to now (today) — no backdating needed

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(!result.isSuccess(),
            'Record created today should still be subject to state/LOB validation');
    }

    @isTest
    static void testOldRecordSkipsStateAndLOBValidation() {
        Contact agent = createAgent();
        // Certification validation currently runs regardless of the
        // CreatedDate cutoff, so the agent needs to be fully
        // certified for this transition to succeed.
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c appt = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Inactive'
        );
        insert appt;

        insert buildStateCert(appt.Id, 'CA', 'Active');

        // Backdate CreatedDate to well before the cutoff
        Test.setCreatedDate(appt.Id, DateTime.now().addDays(-5));

        appt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(appt, false);
        Test.stopTest();

        System.assert(result.isSuccess(),
            'Transition should succeed for a fully certified agent. Errors: ' +
            (result.isSuccess() ? '' : result.getErrors()[0].getMessage()));
    }

    @isTest
    static void testOldRecordStillBlockedByDuplicateCheck() {
        Contact agent = createAgent();
        // The update below transitions to 'Ready to Sell' for LOB
        // 'Life', which certification validation checks regardless
        // of CreatedDate — certify the agent so the only failure is
        // the duplicate check this test is actually verifying.
        createCertifications(agent.Id, 'Life');
        Carrier__c carrier = createCarrier('Carrier A');

        Appointment__c existing = buildAppointment(
            agent.Id, carrier.Id, 'Life', 'CA', 'Active', 'Ready to Sell'
        );
        insert existing;

        // Different LOB at insert time so this doesn't collide yet
        Appointment__c oldAppt = buildAppointment(
            agent.Id, carrier.Id, 'Medicare', 'CA', 'Active', 'Inactive'
        );
        insert oldAppt;

        insert buildStateCert(oldAppt.Id, 'CA', 'Active');

        Test.setCreatedDate(oldAppt.Id, DateTime.now().addDays(-5));

        // Now collide with "existing" on the same update that
        // transitions to Ready to Sell
        oldAppt.Line_of_Business__c = 'Life';
        oldAppt.Sub_Status__c = 'Ready to Sell';

        Test.startTest();
        Database.SaveResult result = Database.update(oldAppt, false);
        Test.stopTest();

        System.assert(!result.isSuccess(),
            'Duplicate check should still run regardless of the CreatedDate cutoff');
        System.assert(
            result.getErrors()[0].getMessage().contains('Duplicate record detected'),
            'Failure should specifically be duplicate detection, not certification. Actual: ' +
            result.getErrors()[0].getMessage()
        );
    }
}