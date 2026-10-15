@isTest
private class OnboardingChecklistEscalationTest {

    @testSetup
    static void createData() {

        // Record that should be escalated
        Onboarding_Checklist__c checklist1 =
            new Onboarding_Checklist__c(
              Status__c = 'Not Started',
                EPA_Signed_Date__c = Date.today().addDays(-2)
            );
        insert checklist1;

        // Record that should NOT be escalated
        Onboarding_Checklist__c checklist2 =
            new Onboarding_Checklist__c(
              Status__c= 'Not Started',
                EPA_Signed_Date__c = Date.today().addDays(-4)
            );
        insert checklist2;
    }

    @isTest
    static void testBatchCreatesTask() {

        Test.startTest();

        Database.executeBatch(
            new OnboardingChecklistEscalationBatch(),
            200
        );

        Test.stopTest();

        List<Task> tasks = [

            SELECT Id,
                   Subject,
                   Priority,
                   Status
            FROM Task
            WHERE Subject LIKE
                'ESCALATION: ONBOARDING%'
        ];

        System.assertEquals(
            2,
            tasks.size()
        );

        System.assertEquals(
            'High',
            tasks[0].Priority
        );

        System.assertEquals(
            'Not Started',
            tasks[0].Status
        );
    }

    @isTest
    static void testDuplicateTaskNotCreated() {

        Onboarding_Checklist__c checklist = [

            SELECT Id, OwnerId
            FROM Onboarding_Checklist__c
            WHERE Status__c = 'Not Started'
            LIMIT 1
        ];

        Task existingTask = new Task(
            Subject =
                'ESCALATION: ONBOARDING NOT STARTED (24H SLA BREACH)',
            WhatId = checklist.Id,
            OwnerId = checklist.OwnerId,
            Status = 'Not Started',
            Priority = 'High'
        );

        insert existingTask;

        Test.startTest();

        Database.executeBatch(
            new OnboardingChecklistEscalationBatch(),
            200
        );

        Test.stopTest();

        Integer taskCount = [

            SELECT Count()
            FROM Task
            WHERE WhatId = :checklist.Id
        ];

        System.assertEquals(
            1,
            taskCount
        );
    }

    @isTest
    static void testScheduler() {

        Test.startTest();

        String jobId = System.schedule(
            'Onboarding Checklist Job',
            '0 0 1 * * ?',
            new OnboardingChecklistEscalationScheduler()
        );

        Test.stopTest();

        CronTrigger ct = [

            SELECT Id,
                   CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(
            'Onboarding Checklist Job',
            ct.CronJobDetail.Name
        );
    }
}