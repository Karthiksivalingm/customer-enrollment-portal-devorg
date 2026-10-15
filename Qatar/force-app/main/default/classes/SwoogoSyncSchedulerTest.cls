@isTest
private class SwoogoSyncSchedulerTest {

    @isTest
    static void testExecuteRunsWhenNothingElseIsRunning() {
        // Defensive cleanup: don't assume a clean org state. A leftover,
        // never-fired 'SwoogoP2Chunk%' CronTrigger from any other test
        // (scheduled jobs aren't reliably flushed by Test.stopTest(), so
        // these can survive past their own test method) would make the
        // scheduler see a false "pending chunk" and skip the run below —
        // clearing them out first makes this test self-sufficient.
        for (CronTrigger ct : [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'SwoogoP2Chunk%' AND State != 'DELETED'
        ]) {
            System.abortJob(ct.Id);
        }

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        new SwoogoSyncScheduler().execute(null);
        Test.stopTest();

        List<Invitation__c> results = [
            SELECT Id FROM Invitation__c WHERE External_Event_Id__c = '1001'
        ];
        System.assert(!results.isEmpty());
    }

    @isTest
    static void testExecuteSkipsWhenBatchAlreadyRunning() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        // Kick off a Pass 1 batch — its AsyncApexJob row exists immediately
        // with a Queued/Preparing status even though it hasn't run yet.
        Database.executeBatch(new SwoogoSyncBatch(), 1);
        // This call should see that job as "already running" and return early
        // without starting a second concurrent run.
        new SwoogoSyncScheduler().execute(null);
        Test.stopTest();

        // The one legitimate batch run still completes at stopTest().
        List<Invitation__c> results = [
            SELECT Id FROM Invitation__c WHERE External_Event_Id__c = '1001'
        ];
        System.assert(!results.isEmpty());
    }

    @isTest
    static void testExecuteSkipsWhenPass2ChunkPending() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        // Simulate a pending between-chunk gap: a scheduled 'SwoogoP2Chunk%'
        // job that exists as a CronTrigger row but hasn't fired yet.
        Id jobId = System.schedule(
            'SwoogoP2Chunk-test',
            '0 0 0 15 3 ? 2042',
            new SwoogoSessionSyncChunkScheduler(
                new List<String>{ '1001' }, true, null, Datetime.now()));

        // Should see the pending chunk and skip starting a new Pass 1 run.
        new SwoogoSyncScheduler().execute(null);

        // Explicitly abort this job rather than relying on test-transaction
        // rollback for CronTrigger cleanup. Scheduled jobs don't reliably
        // fire during Test.stopTest(), so an un-aborted far-future
        // CronTrigger row here can otherwise persist in State='WAITING' and
        // leak into OTHER test methods in this class — which then see a
        // "pending chunk" that was never meant for them and incorrectly
        // skip starting their own run (exactly what broke
        // testExecuteRunsWhenNothingElseIsRunning before this fix).
        System.abortJob(jobId);
        Test.stopTest();

        // No Pass1-triggered Invitation__c should exist, since the scheduler
        // skipped starting SwoogoSyncBatch.run() for this test.
        List<Sub_Event__c> sessions = [SELECT Id FROM Sub_Event__c];
        System.assertEquals(0, sessions.size());
    }

    @isTest
    static void testScheduleAllAndAbortAll() {
        Test.startTest();
        SwoogoSyncScheduler.scheduleAll();
        List<CronTrigger> jobs = [
            SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SwoogoSync%'
        ];
        System.assertEquals(4, jobs.size());

        SwoogoSyncScheduler.abortAll();
        List<CronTrigger> remaining = [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'SwoogoSync%' AND State != 'DELETED'
        ];
        System.assertEquals(0, remaining.size());
        Test.stopTest();
    }
}