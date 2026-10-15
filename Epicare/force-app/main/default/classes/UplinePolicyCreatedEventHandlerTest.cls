@IsTest
private class UplinePolicyCreatedEventHandlerTest {

    private static Id agencyId;
    private static Id agentId;
    private static Id carrierId;
    private static Id uplinePolicyId;

    // ============================================================
    // TEST DATA
    // ============================================================

    @TestSetup
    static void setupData() {

        Account agency = new Account(
            Name = 'Event Handler Test Agency'
        );
        insert agency;

        Contact agent = new Contact(
            LastName = 'Event Handler Test Agent',
            AccountId = agency.Id,
            Email = 'eventhandleragent@test.com',
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding',
            Bypass_VR__c = true
        );
        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name = 'Event Handler Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare',
            Supports_Medicare__c = true
        );
        insert carrier;

        // A real Upline_Policy__c row so the event's Upline_Policy__c
        // lookup value is a genuinely valid, existing Id — the handler
        // doesn't require this to exist, but it keeps the test data
        // realistic and matches production shape.
        Upline_Policy__c uPolicy = new Upline_Policy__c(
            Agent_Code__c = 'AGT-001',
            Agent__c = agent.Id,
            Agency__c = agency.Id,
            Carrier__c = carrier.Id,
            Policy_Number__c = 'UPLINE-EVT-SETUP',
            Effective_Date__c = Date.today(),
            Premium__c = 250.00,
            Policy_Year__c = 3,
            MBI__c = '12345678901',
            Status__c = 'Active',
            Upline_Source__c = 'Manual'
        );
        insert uPolicy;
    }

    // ============================================================
    // LOAD TEST IDS
    // ============================================================

    private static void loadIds() {

        if (agencyId != null) {
            return;
        }

        agencyId = [
            SELECT Id FROM Account
            WHERE Name = 'Event Handler Test Agency'
            LIMIT 1
        ].Id;

        agentId = [
            SELECT Id FROM Contact
            WHERE Email = 'eventhandleragent@test.com'
            LIMIT 1
        ].Id;

        carrierId = [
            SELECT Id FROM Carrier__c
            WHERE Name = 'Event Handler Test Carrier'
            LIMIT 1
        ].Id;

        uplinePolicyId = [
            SELECT Id FROM Upline_Policy__c
            WHERE Policy_Number__c = 'UPLINE-EVT-SETUP'
            LIMIT 1
        ].Id;
    }

    // ============================================================
    // BUILD EVENT
    //
    // Mirrors exactly how UplinePolicyToCommissionHandler.afterInsert
    // populates Upline_Policy_Created__e: Id-valued fields assigned as
    // their String form, date/number fields pre-stringified.
    // ============================================================

    private static Upline_Policy_Created__e buildEvent(
        String policyNumber,
        String agentIdStr,
        String agencyIdStr,
        String carrierIdStr,
        String effectiveDateStr,
        String premiumStr,
        String policyYearStr,
        String uplineSource,
        String status
    ) {

        loadIds();

        return new Upline_Policy_Created__e(
            Upline_Policy__c  = uplinePolicyId,
            Agent_Code__c     = 'AGT-001',
            Agent__c          = agentIdStr,
            Agency__c         = agencyIdStr,
            Carrier__c        = carrierIdStr,
            Policy_Number__c  = policyNumber,
            Effective_Date__c = effectiveDateStr,
            Premium__c        = premiumStr,
            Policy_Year__c    = policyYearStr,
            MBI__c            = '12345678901',
            Upline_Source__c  = uplineSource,
            Status__c         = status
        );
    }

    // ============================================================
    // TEST 1
    //
    // Well-formed single event -> exactly one Commission_Record__c,
    // with every Id/Date/Decimal field correctly parsed back from its
    // Text representation on the event.
    // ============================================================

    @IsTest
    static void testHandleAfterInsert_wellFormedEvent_createsCommissionRecordWithParsedFields() {

        loadIds();

        Upline_Policy_Created__e evt = buildEvent(
            'UPLINE-EVT-001',
            agentId,
            agencyId,
            carrierId,
            String.valueOf(Date.today()),
            '250.00',
            '3',
            'Manual',
            'Active'
        );

        Test.startTest();
        UplinePolicyCreatedEventHandler.handleAfterInsert(
            new List<Upline_Policy_Created__e>{ evt }
        );
        Test.stopTest();

        List<Commission_Record__c> commissions = [
            SELECT Id,
                   Upline_Policy__c,
                   Agent_Code__c,
                   Agent__c,
                   Agency__c,
                   Carrier__c,
                   Policy_Number__c,
                   Effective_Date__c,
                   Premium__c,
                   Policy_Year__c,
                   MBI__c,
                   Upline_Source__c
            FROM Commission_Record__c
            WHERE Policy_Number__c = 'UPLINE-EVT-001'
        ];

        System.assertEquals(
            1,
            commissions.size(),
            'Exactly one Commission Record should be created from a well-formed event.'
        );

        Commission_Record__c comm = commissions[0];

        System.assertEquals(uplinePolicyId, comm.Upline_Policy__c);
        System.assertEquals('AGT-001', comm.Agent_Code__c);
        System.assertEquals(agentId, comm.Agent__c);
        System.assertEquals(agencyId, comm.Agency__c);
        System.assertEquals(carrierId, comm.Carrier__c);
        System.assertEquals('UPLINE-EVT-001', comm.Policy_Number__c);
        System.assertEquals(Date.today(), comm.Effective_Date__c);
        System.assertEquals(250.00, comm.Premium__c);
        System.assertEquals(3, comm.Policy_Year__c);
        System.assertEquals('12345678901', comm.MBI__c);
        System.assertEquals('Manual', comm.Upline_Source__c);
    }

    // ============================================================
    // TEST 2
    //
    // Bulk: two well-formed events in one call -> two Commission
    // Records, confirming the handler is bulk-safe.
    // ============================================================

    @IsTest
    static void testHandleAfterInsert_bulkEvents_createsOneCommissionRecordPerEvent() {

        loadIds();

        Upline_Policy_Created__e evtOne = buildEvent(
            'UPLINE-EVT-002',
            agentId,
            agencyId,
            carrierId,
            String.valueOf(Date.today()),
            '100.00',
            '1',
            'Manual',
            'Active'
        );

        Upline_Policy_Created__e evtTwo = buildEvent(
            'UPLINE-EVT-003',
            agentId,
            agencyId,
            carrierId,
            String.valueOf(Date.today()),
            '150.00',
            '2',
            'Manual',
            'Active'
        );

        Test.startTest();
        UplinePolicyCreatedEventHandler.handleAfterInsert(
            new List<Upline_Policy_Created__e>{ evtOne, evtTwo }
        );
        Test.stopTest();

        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Policy_Number__c IN ('UPLINE-EVT-002', 'UPLINE-EVT-003')
        ];

        System.assertEquals(
            2,
            commissionCount,
            'One Commission Record should be created per event in the batch.'
        );
    }

    // ============================================================
    // TEST 3
    //
    // Optional fields blank on the event (Agent__c, Agency__c,
    // Carrier__c, Effective_Date__c, Premium__c, Policy_Year__c) ->
    // Commission_Record__c is still created, with those fields left
    // null rather than throwing on the isNotBlank/parse checks.
    // ============================================================

    @IsTest
    static void testHandleAfterInsert_blankOptionalFields_createsRecordWithNulls() {

        loadIds();

        Upline_Policy_Created__e evt = buildEvent(
            'UPLINE-EVT-004',
            null,
            null,
            null,
            null,
            null,
            null,
            'Manual',
            'Active'
        );

        Test.startTest();
        UplinePolicyCreatedEventHandler.handleAfterInsert(
            new List<Upline_Policy_Created__e>{ evt }
        );
        Test.stopTest();

        List<Commission_Record__c> commissions = [
            SELECT Id,
                   Agent__c,
                   Agency__c,
                   Carrier__c,
                   Effective_Date__c,
                   Premium__c,
                   Policy_Year__c
            FROM Commission_Record__c
            WHERE Policy_Number__c = 'UPLINE-EVT-004'
        ];

        System.assertEquals(
            1,
            commissions.size(),
            'A Commission Record should still be created when optional fields are blank.'
        );

        System.assertEquals(null, commissions[0].Agent__c);
        System.assertEquals(null, commissions[0].Agency__c);
        System.assertEquals(null, commissions[0].Carrier__c);
        System.assertEquals(null, commissions[0].Effective_Date__c);
        System.assertEquals(null, commissions[0].Premium__c);
        System.assertEquals(null, commissions[0].Policy_Year__c);
    }

    // ============================================================
    // TEST 4
    //
    // Malformed event (Upline_Policy__c is not a valid Id) is caught,
    // logged, and skipped — it must NOT throw an unhandled exception,
    // and must NOT block a good event elsewhere in the same batch
    // from being inserted.
    // ============================================================

    @IsTest
    static void testHandleAfterInsert_malformedEvent_isSkippedWithoutBlockingOthers() {

        loadIds();

        Upline_Policy_Created__e badEvt = buildEvent(
            'UPLINE-EVT-BAD',
            agentId,
            agencyId,
            carrierId,
            String.valueOf(Date.today()),
            '100.00',
            '1',
            'Manual',
            'Active'
        );
        badEvt.Upline_Policy__c = 'not-a-valid-id';

        Upline_Policy_Created__e goodEvt = buildEvent(
            'UPLINE-EVT-GOOD',
            agentId,
            agencyId,
            carrierId,
            String.valueOf(Date.today()),
            '100.00',
            '1',
            'Manual',
            'Active'
        );

        Test.startTest();
        // Should not throw, even though badEvt fails to parse.
        UplinePolicyCreatedEventHandler.handleAfterInsert(
            new List<Upline_Policy_Created__e>{ badEvt, goodEvt }
        );
        Test.stopTest();

        Integer badCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Policy_Number__c = 'UPLINE-EVT-BAD'
        ];

        System.assertEquals(
            0,
            badCount,
            'No Commission Record should be created for a malformed event.'
        );

        Integer goodCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Policy_Number__c = 'UPLINE-EVT-GOOD'
        ];

        System.assertEquals(
            1,
            goodCount,
            'A well-formed event elsewhere in the same batch should still '
            + 'be inserted despite another event failing to parse.'
        );
    }

    // ============================================================
    // TEST 5
    //
    // Empty event list -> handler returns early, no DML attempted, no
    // error.
    // ============================================================

    @IsTest
    static void testHandleAfterInsert_emptyList_noOp() {

        Test.startTest();
        UplinePolicyCreatedEventHandler.handleAfterInsert(
            new List<Upline_Policy_Created__e>()
        );
        Test.stopTest();

        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
        ];

        System.assertEquals(
            0,
            commissionCount,
            'No Commission Record should be created when no events are passed in.'
        );
    }

    // ============================================================
    // TEST 6 — END TO END
    //
    // Actually publishes Upline_Policy_Created__e via EventBus.publish
    // and lets UplinePolicyCreatedEventTrigger route it to
    // UplinePolicyCreatedEventHandler, confirming the trigger wiring
    // itself (not just the handler method in isolation) results in a
    // Commission_Record__c after Test.stopTest() flushes the event.
    // ============================================================

    @IsTest
    static void testTrigger_publishedEvent_createsCommissionRecordEndToEnd() {

        loadIds();

        Upline_Policy_Created__e evt = buildEvent(
            'UPLINE-EVT-E2E',
            agentId,
            agencyId,
            carrierId,
            String.valueOf(Date.today()),
            '325.00',
            '4',
            'Manual',
            'Active'
        );

        Test.startTest();
        EventBus.publish(evt);
        Test.stopTest();

        List<Commission_Record__c> commissions = [
            SELECT Id, Policy_Number__c, Premium__c, Policy_Year__c
            FROM Commission_Record__c
            WHERE Policy_Number__c = 'UPLINE-EVT-E2E'
        ];

        System.assertEquals(
            1,
            commissions.size(),
            'Publishing the platform event should result in exactly one '
            + 'Commission Record via UplinePolicyCreatedEventTrigger.'
        );

        System.assertEquals(325.00, commissions[0].Premium__c);
        System.assertEquals(4, commissions[0].Policy_Year__c);
    }
}