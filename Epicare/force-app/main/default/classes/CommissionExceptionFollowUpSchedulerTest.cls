@IsTest
private class CommissionExceptionFollowUpSchedulerTest {

    @IsTest
    static void testScheduler() {

        String jobName =
            'Commission Exception Scheduler Test ' +
            String.valueOf(DateTime.now().getTime());

        String cronExp =
            '0 0 0 1 1 ? 2099';

        Test.startTest();

        System.schedule(
            jobName,
            cronExp,
            new CommissionExceptionFollowUpScheduler()
        );

        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id,
                   CronJobDetail.Name,
                   State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];

        System.assertEquals(
            1,
            jobs.size(),
            'Scheduler job should be created successfully.'
        );
    }
}