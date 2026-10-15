@IsTest
private class UplinePolicyToCommissionHandlerTest {

    private static Id agencyId;
    private static Id agentId;
    private static Id carrierId;

    // Must match UplinePolicyToCommissionHandler.API_USERNAME exactly.
    private static final String API_USERNAME = 'apiuser@epicare.com';

    // ============================================================
    // TEST DATA
    // ============================================================

    @TestSetup
    static void setupData() {

        Account agency = new Account(
            Name = 'Upline Handler Test Agency'
        );
        insert agency;

        Contact agent = new Contact(
            LastName = 'Upline Handler Test Agent',
            AccountId = agency.Id,
            Email = 'uplinehandleragent@test.com',
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding',
            Bypass_VR__c = true
        );
        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name = 'Upline Handler Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare',
            Supports_Medicare__c = true
        );
        insert carrier;
    }

    // ============================================================
    // LOAD TEST IDS
    // ============================================================

    private static void loadIds() {

        if (agencyId != null) {
            return;
        }

        agencyId = [
            SELECT Id
            FROM Account
            WHERE Name = 'Upline Handler Test Agency'
            LIMIT 1
        ].Id;

        agentId = [
            SELECT Id
            FROM Contact
            WHERE Email = 'uplinehandleragent@test.com'
            LIMIT 1
        ].Id;

        carrierId = [
            SELECT Id
            FROM Carrier__c
            WHERE Name = 'Upline Handler Test Carrier'
            LIMIT 1
        ].Id;
    }

    // ============================================================
    // GET OR CREATE THE GO AMS INTEGRATION API USER
    //
    // UplinePolicyToCommissionHandler gates event publishing on
    // UserInfo.getUserName() == 'apiuser@epicare.com'. To exercise
    // that path in tests we need a real User record with that exact
    // username, so we look for one first (in case the org already
    // provisions it) and only insert one if it doesn't exist yet.
    // ============================================================

    private static User getApiUser() {

        List<User> existing = [
            SELECT Id, Username
            FROM User
            WHERE Username = :API_USERNAME
            LIMIT 1
        ];

        if (!existing.isEmpty()) {
            return existing[0];
        }

        User apiUser = new User(
            FirstName        = 'GO AMS',
            LastName         = 'Integration',
            Email            = API_USERNAME,
            Username         = API_USERNAME,
            Alias            = 'goamsi',
            TimeZoneSidKey   = 'America/New_York',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId        = UserInfo.getProfileId(),
            IsActive         = true
        );
        insert apiUser;

        return apiUser;
    }

    // ============================================================
    // BUILD UPLINE POLICY
    // ============================================================

    private static Upline_Policy__c buildUplinePolicy(
        String policyNumber,
        String uplineSource,
        String status
    ) {

        loadIds();

        return new Upline_Policy__c(
            Agent_Code__c = 'AGT-001',
            Agent__c = agentId,
            Agency__c = agencyId,
            Carrier__c = carrierId,
            Policy_Number__c = policyNumber,
            Effective_Date__c = Date.today(),
            Premium__c = 250.00,
            Policy_Year__c = 3,
            MBI__c = '12345678901',
            Status__c = status,
            Upline_Source__c = uplineSource
        );
    }

    // ============================================================
    // TEST 1
    //
    // Manual + blank Status, inserted as a NON-API user (e.g. Data
    // Loader / manual entry).
    //
    // Per the 26-Aug restriction, only the GO AMS integration API
    // user's inserts publish Upline_Policy_Created__e (and therefore
    // ever result in an auto-generated Commission_Record__c). Any
    // other running user — which is what happens by default in a
    // test context — must NOT publish the event and must NOT produce
    // a Commission_Record__c as a side effect of this insert.
    //
    // Commission_Import_Log__c creation is unaffected and still fires
    // for every source/user.
    // ============================================================

    @IsTest
    static void testManualSourceBlankStatus_nonApiUser_noCommissionRecord() {

        Upline_Policy__c uplinePolicy = buildUplinePolicy(
            'UPLINE-MANUAL-001',
            'Manual',
            null
        );

        Test.startTest();

        insert uplinePolicy;

        Test.stopTest();

        // --------------------------------------------------------
        // Verify Upline Policy was inserted
        // --------------------------------------------------------

        Integer policyCount = [
            SELECT COUNT()
            FROM Upline_Policy__c
            WHERE Id = :uplinePolicy.Id
        ];

        System.assertEquals(
            1,
            policyCount,
            'The Manual Upline Policy should be inserted successfully.'
        );

        // --------------------------------------------------------
        // Verify NO Commission Record was created (non-API user)
        // --------------------------------------------------------

        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Upline_Policy__c = :uplinePolicy.Id
        ];

        System.assertEquals(
            0,
            commissionCount,
            'A Commission Record must NOT be auto-created from policy '
            + 'creation when the running user is not the GO AMS API user.'
        );

        // --------------------------------------------------------
        // Verify Commission Import Log still gets created
        // --------------------------------------------------------

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Source_Type__c,
                   Processing_Status__c,
                   Import_Date__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Created__c = 1
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'One Manual Commission Import Log should be created regardless '
            + 'of whether a Commission Record was generated.'
        );

        System.assertEquals(
            'Manual',
            logs[0].Source_Type__c,
            'Source Type must exactly match the restricted picklist value Manual.'
        );

        System.assertEquals(
            'Completed',
            logs[0].Processing_Status__c,
            'Import Log should be marked Completed.'
        );

        System.assertEquals(
            1,
            logs[0].Records_Created__c,
            'Records Created should be 1.'
        );

        System.assertEquals(
            0,
            logs[0].Records_Updated__c,
            'Records Updated should be 0 for an insert.'
        );
    }

    // ============================================================
    // TEST 2
    //
    // Bulk insert using only valid Manual source, as a NON-API user.
    //
    // Both records:
    //
    //     Upline_Source__c = Manual
    //     Status__c       = blank
    //
    // therefore:
    //
    //     Source_Type__c = Manual
    //
    // The handler groups the records and creates one Import Log
    // with Records_Created__c = 2, but publishes NO events and
    // creates NO Commission_Record__c rows since the running user
    // is not the GO AMS API user.
    // ============================================================

    @IsTest
    static void testBulkManualRecords_nonApiUser_noCommissionRecords() {

        Upline_Policy__c policyOne = buildUplinePolicy(
            'UPLINE-MANUAL-002',
            'Manual',
            null
        );

        Upline_Policy__c policyTwo = buildUplinePolicy(
            'UPLINE-MANUAL-003',
            'Manual',
            null
        );

        Test.startTest();

        insert new List<Upline_Policy__c>{
            policyOne,
            policyTwo
        };

        Test.stopTest();

        // --------------------------------------------------------
        // Verify both Upline Policies
        // --------------------------------------------------------

        Integer policyCount = [
            SELECT COUNT()
            FROM Upline_Policy__c
            WHERE Policy_Number__c IN (
                'UPLINE-MANUAL-002',
                'UPLINE-MANUAL-003'
            )
        ];

        System.assertEquals(
            2,
            policyCount,
            'Both Manual Upline Policies should be inserted.'
        );

        // --------------------------------------------------------
        // Verify NO Commission Records were created
        // --------------------------------------------------------

        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Policy_Number__c IN (
                'UPLINE-MANUAL-002',
                'UPLINE-MANUAL-003'
            )
        ];

        System.assertEquals(
            0,
            commissionCount,
            'No Commission Records should be created for a bulk non-API-user insert.'
        );

        // --------------------------------------------------------
        // Verify grouped Import Log still fires
        // --------------------------------------------------------

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Source_Type__c,
                   Processing_Status__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Created__c = 2
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'One grouped Manual Import Log should be created.'
        );

        System.assertEquals(
            'Manual',
            logs[0].Source_Type__c
        );

        System.assertEquals(
            'Completed',
            logs[0].Processing_Status__c
        );

        System.assertEquals(
            2,
            logs[0].Records_Created__c
        );

        System.assertEquals(
            0,
            logs[0].Records_Updated__c
        );
    }

    // ============================================================
    // TEST 3
    //
    // Insert and then update the same Manual Upline Policy, as a
    // NON-API user.
    //
    // afterInsert():
    //     - publishes NO event / creates NO Commission Record
    //     - creates Import Log with Records_Created__c = 1
    //
    // afterUpdate():
    //     - creates Import Log with Records_Updated__c = 1
    //     - still creates NO Commission Record (unaffected by update,
    //       and never created one anyway)
    //
    // IMPORTANT:
    // There is only ONE Test.startTest()/Test.stopTest() pair.
    // ============================================================

    @IsTest
    static void testManualSourceAfterUpdate_nonApiUser_noCommissionRecord() {

        Upline_Policy__c uplinePolicy = buildUplinePolicy(
            'UPLINE-MANUAL-UPDATE',
            'Manual',
            null
        );

        Test.startTest();

        // --------------------------------------------------------
        // INSERT
        // --------------------------------------------------------

        insert uplinePolicy;

        // --------------------------------------------------------
        // UPDATE
        // --------------------------------------------------------

        uplinePolicy.Premium__c = 300.00;

        update uplinePolicy;

        Test.stopTest();

        // --------------------------------------------------------
        // Verify Upline Policy update
        // --------------------------------------------------------

        Upline_Policy__c savedPolicy = [
            SELECT Id,
                   Premium__c,
                   Upline_Source__c,
                   Status__c
            FROM Upline_Policy__c
            WHERE Id = :uplinePolicy.Id
        ];

        System.assertEquals(
            300.00,
            savedPolicy.Premium__c,
            'The Upline Policy Premium should be updated.'
        );

        System.assertEquals(
            'Manual',
            savedPolicy.Upline_Source__c,
            'Upline Source should remain Manual.'
        );

        // --------------------------------------------------------
        // Verify Commission Record count stays zero throughout
        // --------------------------------------------------------

        Integer commissionCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Upline_Policy__c = :uplinePolicy.Id
        ];

        System.assertEquals(
            0,
            commissionCount,
            'No Commission Record should exist for a non-API-user insert or update.'
        );

        // --------------------------------------------------------
        // Verify Insert Import Log
        // --------------------------------------------------------

        List<Commission_Import_Log__c> insertLogs = [
            SELECT Id,
                   Source_Type__c,
                   Processing_Status__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Created__c = 1
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            insertLogs.size(),
            'One Manual Import Log should be created for the insert.'
        );

        // --------------------------------------------------------
        // Verify Update Import Log
        // --------------------------------------------------------

        List<Commission_Import_Log__c> updateLogs = [
            SELECT Id,
                   Source_Type__c,
                   Processing_Status__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Updated__c = 1
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            updateLogs.size(),
            'One Manual Import Log should be created for the update.'
        );

        System.assertEquals(
            'Manual',
            updateLogs[0].Source_Type__c,
            'Source Type must be the exact restricted picklist value Manual.'
        );

        System.assertEquals(
            'Completed',
            updateLogs[0].Processing_Status__c,
            'Update Import Log should be marked Completed.'
        );

        System.assertEquals(
            0,
            updateLogs[0].Records_Created__c,
            'Records Created should be 0 for an update.'
        );

        System.assertEquals(
            1,
            updateLogs[0].Records_Updated__c,
            'Records Updated should be 1.'
        );
    }

    // ============================================================
    // TEST 4
    //
    // Insert as the GO AMS integration API user.
    //
    // This is the ONLY path that should publish
    // Upline_Policy_Created__e. NOTE: verifying the published event's
    // payload, or the Commission_Record__c a downstream subscriber
    // eventually creates from it, is out of scope for this test:
    //   - EventBus.TestUtils.getPublishedEventsAsAdmin() is not
    //     available in this org.
    //   - There is currently no trigger deployed on
    //     Upline_Policy_Created__e in this org (confirmed via debug
    //     log — Test.stopTest() has nothing to flush), so
    //     Commission_Record__c is never created here regardless of
    //     which user runs the insert. That creation is owned entirely
    //     by the separate subscriber
    //     (UplinePolicyCreatedEventTrigger / UplinePolicyCreatedEventHandler)
    //     once it exists, and belongs in that class's own test class.
    //
    // What IS this handler's responsibility, and what this test
    // verifies: the insert succeeds without error when run as the API
    // user (i.e. EventBus.publish doesn't throw), and
    // Commission_Import_Log__c creation is unaffected either way.
    // ============================================================

    @IsTest
    static void testApiUserInsert_succeedsAndStillLogsImport() {

        User apiUser = getApiUser();

        Upline_Policy__c uplinePolicy = buildUplinePolicy(
            'UPLINE-APIUSER-001',
            'Manual',
            'Active'
        );

        System.runAs(apiUser) {
            Test.startTest();
            insert uplinePolicy;
            Test.stopTest();
        }

        // --------------------------------------------------------
        // Verify the Upline Policy was inserted (i.e. the insert,
        // including the event-publish side effect, did not throw)
        // --------------------------------------------------------

        Integer policyCount = [
            SELECT COUNT()
            FROM Upline_Policy__c
            WHERE Id = :uplinePolicy.Id
        ];

        System.assertEquals(
            1,
            policyCount,
            'The Upline Policy should be inserted successfully as the API user.'
        );

        // --------------------------------------------------------
        // Import Log still fires the same way for the API user
        // --------------------------------------------------------

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Source_Type__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Created__c = 1
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'Commission Import Log creation is unchanged for the API user.'
        );
    }

    // ============================================================
    // TEST 5
    //
    // Bulk insert as the GO AMS integration API user — verifies the
    // insert (and its bulkified event-publish side effect) succeeds
    // without error across multiple records, and the Import Log is
    // still grouped/created correctly.
    // ============================================================

    @IsTest
    static void testApiUserBulkInsert_succeedsAndStillLogsImport() {

        User apiUser = getApiUser();

        Upline_Policy__c policyOne = buildUplinePolicy(
            'UPLINE-APIUSER-002',
            'Manual',
            'Active'
        );

        Upline_Policy__c policyTwo = buildUplinePolicy(
            'UPLINE-APIUSER-003',
            'Manual',
            'Active'
        );

        System.runAs(apiUser) {
            Test.startTest();
            insert new List<Upline_Policy__c>{ policyOne, policyTwo };
            Test.stopTest();
        }

        Integer policyCount = [
            SELECT COUNT()
            FROM Upline_Policy__c
            WHERE Policy_Number__c IN (
                'UPLINE-APIUSER-002',
                'UPLINE-APIUSER-003'
            )
        ];

        System.assertEquals(
            2,
            policyCount,
            'Both Upline Policies should be inserted successfully as the API user.'
        );

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Source_Type__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Manual'
            AND Records_Created__c = 2
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            logs.size(),
            'One grouped Manual Import Log should be created for the bulk API-user insert.'
        );
    }
}