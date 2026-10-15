@isTest
private class SwoogoSessionSyncChunkSchedulerTest {

    @isTest
    static void testExecuteFiresSessionSyncBatch() {
        Invitation__c inv = new Invitation__c(External_Event_Id__c = '1001', Name = 'Test Event');
        insert inv;
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());

        Test.startTest();
        // Call execute() directly rather than going through System.schedule()
        // — scheduled jobs are not reliably flushed by Test.stopTest(), so
        // asserting through an actual fired schedule is non-deterministic.
        // Calling execute() directly still exercises the exact same
        // Database.executeBatch(...) call this class exists to make.
        new SwoogoSessionSyncChunkScheduler(
            new List<String>{ '1001' }, true, null, Datetime.now()
        ).execute(null);
        Test.stopTest();

        List<Sub_Event__c> sessions = [SELECT Id FROM Sub_Event__c WHERE Sub_Event_ID__c = '2001'];
        System.assert(!sessions.isEmpty());
    }
}