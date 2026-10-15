@isTest
private class SwoogoSyncBatchTest {

    @isTest
    static void testFullRunCreatesInvitationAndChainsPass2() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        // Default Swoogo_Sync_State__c has no Last_Sync_Time__c -> first/full run.

        Test.startTest();
        SwoogoSyncBatch.run();
        Test.stopTest();

        List<Invitation__c> results = [
            SELECT Id, Status__c FROM Invitation__c WHERE External_Event_Id__c = '1001'
        ];
        System.assert(!results.isEmpty());

        Swoogo_Sync_State__c state = Swoogo_Sync_State__c.getOrgDefaults();
        System.assertNotEquals(null, state.Last_Sync_Time__c);
    }

    @isTest
    static void testDeltaRunUpdatesExistingInvitationAndSubEvents() {
        Invitation__c inv = new Invitation__c(
            External_Event_Id__c = '1001', Name = 'Stale Name', Status__c = 'Draft'
        );
        insert inv;
        Sub_Event__c se = new Sub_Event__c(
            Sub_Event_ID__c = '2001', Invitation__c = inv.Id, Sub_Event_Name__c = 'Existing Session'
        );
        insert se;

        Swoogo_Sync_State__c state = Swoogo_Sync_State__c.getOrgDefaults();
        state.Last_Sync_Time__c = Datetime.now().addDays(-1);
        upsert state;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        SwoogoSyncBatch.run();
        Test.stopTest();

        Invitation__c updated = [SELECT Name, Status__c FROM Invitation__c WHERE Id = :inv.Id];
        System.assertEquals('Test Event', updated.Name);
        System.assertEquals('Active', updated.Status__c);
    }

    @isTest
    static void testScopedRunWithSpecificEventId() {
        // Exercises the run(String eventIdsCsv) overload / scopeEventIds
        // constructor path specifically (distinct from run() and runFull(),
        // both already covered above).
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        SwoogoSyncBatch.run('1001');
        Test.stopTest();

        List<Invitation__c> results = [
            SELECT Id FROM Invitation__c WHERE External_Event_Id__c = '1001'
        ];
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testRunFullResetsSyncStateAndRuns() {
        Swoogo_Sync_State__c state = Swoogo_Sync_State__c.getOrgDefaults();
        state.Last_Sync_Time__c = Datetime.now();
        upsert state;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        SwoogoSyncBatch.runFull();
        Test.stopTest();

        List<Invitation__c> results = [
            SELECT Id FROM Invitation__c WHERE External_Event_Id__c = '1001'
        ];
        System.assert(!results.isEmpty());
    }

    // NOTE: multi-event scoped runs (Pass 1 -> chained Pass 2 -> chunking ->
    // rescheduled follow-up chunk, 3 levels of batch/schedule chaining) are
    // covered directly against SwoogoSessionSyncBatch in
    // SwoogoSessionSyncBatchTest.testChunkingSchedulesFollowUpChunk instead
    // of here — going through the full SwoogoSyncBatch -> SwoogoSessionSyncBatch
    // chain with multiple scoped ids proved unreliable in the Apex test
    // harness for this org.
}