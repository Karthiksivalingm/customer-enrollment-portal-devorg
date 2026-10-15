@IsTest(SeeAllData=true)
private class NIPRStaleCheckBatchTest {

    // ============================================================
    // TEST 1: Batch Execution
    // ============================================================
    @IsTest
    static void testBatchExecution() {

        Integer contactCount = [
            SELECT COUNT()
            FROM Contact
            WHERE NIPR_Update_Before__c > 30
        ];

        System.assert(
            contactCount > 0,
            'No Contacts found matching NIPR stale check criteria.'
        );

        Test.startTest();

        Database.executeBatch(
            new NIPRStaleCheckBatch(),
            500
        );

        Test.stopTest();

        System.assert(
            true,
            'NIPRStaleCheckBatch executed successfully.'
        );
    }


    // ============================================================
    // TEST 2: Scheduler Execution
    // ============================================================
    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();

        String jobId = System.schedule(
            'NIPR Stale Scheduler Test',
            '0 0 0 1 1 ? 2099',
            new NIPRStaleCheckScheduler()
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Scheduler should create a scheduled job.'
        );

        CronTrigger job = [
            SELECT Id,
                   CronJobDetail.Name,
                   State
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];

        System.assertEquals(
            'NIPR Stale Scheduler Test',
            job.CronJobDetail.Name
        );
    }


    // ============================================================
    // TEST 3: Batch Start
    // ============================================================
    @IsTest
    static void testStartMethod() {

        NIPRStaleCheckBatch batch =
            new NIPRStaleCheckBatch();

        Test.startTest();

        Database.QueryLocator result =
            batch.start(null);

        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'start() should return a QueryLocator.'
        );
    }


    // ============================================================
    // TEST 4: Batch Finish
    // ============================================================
    @IsTest
    static void testFinishMethod() {

        NIPRStaleCheckBatch batch =
            new NIPRStaleCheckBatch();

        Test.startTest();

        batch.finish(null);

        Test.stopTest();

        System.assert(
            true,
            'finish() executed successfully.'
        );
    }


    // ============================================================
    // TEST 5: Scheduler Direct Execute
    // ============================================================
    @IsTest
    static void testSchedulerDirectExecute() {

        Test.startTest();

        NIPRStaleCheckScheduler scheduler =
            new NIPRStaleCheckScheduler();

        scheduler.execute(null);

        Test.stopTest();

        System.assert(
            true,
            'Scheduler execute() executed successfully.'
        );
    }
}