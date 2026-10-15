@isTest
private class AbortSwoogoJobsBatchTest {

    public class DummySchedulable implements Schedulable {
        public void execute(SchedulableContext sc) {}
    }

    private static final String CRON = '0 0 0 1 1 ? 2099';
    private static final String TEST_PATTERN = 'UnitTestSwoogo%';

    @isTest
    static void abortsOnlyMatchingJobs() {
        System.schedule('UnitTestSwoogo_1', CRON, new DummySchedulable());
        System.schedule('UnitTestSwoogo_2', CRON, new DummySchedulable());
        System.schedule('UnitTestSwoogo_3', CRON, new DummySchedulable());
        System.schedule('UnitTestOther_1',  CRON, new DummySchedulable());

        System.assertEquals(3,
            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :TEST_PATTERN]);

        Test.startTest();
        Database.executeBatch(new AbortSwoogoJobsBatch(TEST_PATTERN), 100);
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :TEST_PATTERN],
            'Matching jobs should be aborted');

        System.assertEquals(1,
            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'UnitTestOther_1'],
            'Non-matching job should not be touched');
    }

    @isTest
    static void runsWithNoMatchingJobs() {
        Test.startTest();
        Database.executeBatch(new AbortSwoogoJobsBatch('NoSuchJobPattern%'), 100);
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'NoSuchJobPattern%']);
    }

    @isTest
    static void defaultConstructorBuildsQuery() {
        // Covers the default constructor without running against real org jobs
        Database.QueryLocator ql = new AbortSwoogoJobsBatch().start(null);
        System.assertNotEquals(null, ql);
    }
}