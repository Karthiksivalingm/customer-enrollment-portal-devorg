@isTest
private class OnboardingChecklistEscalationBatchTest {

    @isTest
    static void testCreateEscalationTask() {

        Onboarding_Checklist__c checklist = new Onboarding_Checklist__c(
            Status__c = 'Not Started',
            EPA_Signed_Date__c = Date.today().addDays(-2)
        );
        insert checklist;

        Test.startTest();
        Database.executeBatch(new OnboardingChecklistEscalationBatch(), 1);
        Test.stopTest();

        List<Task> tasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :checklist.Id
        ];

        System.assertEquals(1, tasks.size());
        System.assertEquals(
            'ESCALATION: ONBOARDING NOT STARTED (24H SLA BREACH)',
            tasks[0].Subject
        );
    }

    @isTest
    static void testNoDuplicateEscalationTask() {

        Onboarding_Checklist__c checklist = new Onboarding_Checklist__c(
            Status__c = 'Not Started',
            EPA_Signed_Date__c = Date.today().addDays(-2)
        );
        insert checklist;

        Task existingTask = new Task(
            Subject = 'ESCALATION: ONBOARDING NOT STARTED (24H SLA BREACH)',
            WhatId = checklist.Id,
            OwnerId = UserInfo.getUserId(),
            Status = 'Not Started',
            Priority = 'High',
            ActivityDate = Date.today()
        );
        insert existingTask;

        Test.startTest();
        Database.executeBatch(new OnboardingChecklistEscalationBatch(), 1);
        Test.stopTest();

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :checklist.Id
            AND Subject LIKE 'ESCALATION: ONBOARDING%'
        ];

        System.assertEquals(1, taskCount);
    }
}