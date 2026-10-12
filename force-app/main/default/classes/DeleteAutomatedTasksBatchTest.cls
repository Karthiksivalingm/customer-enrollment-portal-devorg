@isTest
private class DeleteAutomatedTasksBatchTest {

    @isTest
    static void testBatchDeletesOldAutomatedTasks() {
        // NOTE: You cannot insert a Task with CreatedBy.Name = 'Automated Process'
        // in a test context (CreatedById is only settable via a real Automated
        // Process user, e.g. Einstein Activity Capture's integration user).
        // Recommended approach: filter/verify logic against your sandbox's real
        // Automated Process tasks, OR refactor the query to filter by a known
        // Integration User Id (see "Alternative filter" note in the batch class)
        // so this test can insert tasks under a mocked running user via
        // System.runAs(), which DOES let you set CreatedById.

        User automatedProcessUser = [
            SELECT Id FROM User WHERE Name = 'Automated Process' LIMIT 1
        ];

        Task t;
        System.runAs(automatedProcessUser) {
            t = new Task(
                Subject = 'Email: Test Automated Task',
                TaskSubtype = 'Email',
                Status = 'Completed',
                ActivityDate = Date.today().addDays(-2)
            );
            insert t;
        }

        Test.startTest();
        Database.executeBatch(new DeleteAutomatedTasksBatch(), 200);
        Test.stopTest();

        List<Task> remaining = [SELECT Id FROM Task WHERE Id = :t.Id];
        System.assertEquals(0, remaining.size(), 'Automated task should have been deleted');
    }

    @isTest
    static void testScheduler() {
        Test.startTest();
        String cron = '0 0 2 * * ?';
        System.schedule('Test Daily Automated Task Cleanup', cron, new DeleteAutomatedTasksBatch());
        Test.stopTest();

        List<CronTrigger> ct = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE CronExpression = :cron
        ];
        System.assertEquals(1, ct.size());
    }
}