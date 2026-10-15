@isTest
public class UpdateFillRateBatchTest {

    @isTest
    static void testBatchExecution() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Uncapped_Fill_Rate__c = 100,
                Low_Fill_Rate_Alert__c = true
            ));
        }
        insert accounts;
        List<Account> beforeUpdate = [SELECT Id FROM Account WHERE Uncapped_Fill_Rate__c != NULL AND Low_Fill_Rate_Alert__c != NULL];
        System.assertEquals(5, beforeUpdate.size(), 'All 5 records should exist before batch execution');

        System.Test.startTest();
        UpdateFillRateBatch batch = new UpdateFillRateBatch();
        Database.executeBatch(batch, 200);
        System.Test.stopTest();

        List<Account> afterUpdate = [SELECT Id FROM Account WHERE Uncapped_Fill_Rate__c = NULL AND Low_Fill_Rate_Alert__c = NULL];
        System.assertEquals(5, afterUpdate.size(), 'All 5 records should have null values after batch execution');
    }

    /**
     * This method tests the Scheduler execution.
     */
    @isTest
    static void testSchedulerExecution() {
        // Schedule the job using a valid cron expression (example: every Friday at 10 PM)
        String cronExp = '0 0 22 ? * 6 *';  // Every Friday at 10:00 PM
        Test.startTest();
        FillRateBatchScheduler scheduler = new FillRateBatchScheduler();
        String jobId = System.schedule('Test Fill Rate Batch', cronExp, scheduler);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job should be created successfully.');

        CronTrigger[] cronJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name = 'Test Fill Rate Batch'];
        System.assertEquals(1, cronJobs.size(), 'There should be one scheduled job.');
        System.assertEquals(cronExp, cronJobs[0].CronExpression, 'The cron expression should match the expected value.');
    }
}