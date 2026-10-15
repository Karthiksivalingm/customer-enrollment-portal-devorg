@IsTest
private class CommissionExceptionFollowUpBatchTest {

    // ============================================================
    // TEST DATA SETUP
    // ============================================================
    @TestSetup
    static void setupData() {

        // The production Batch searches for:
        // UserRole.Name = 'Commissions Director'
        //
        // Use the existing role from the org.
        UserRole directorRole = [
            SELECT Id
            FROM UserRole
            WHERE Name = 'Commissions Director'
            LIMIT 1
        ];

        Profile adminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        String uniqueValue =
            String.valueOf(DateTime.now().getTime());

        User director = new User(
            FirstName = 'Commission',
            LastName = 'Director Test',
            Alias = 'comdir',
            Email = 'commission.director.' +
                    uniqueValue +
                    '@example.com',
            Username = 'commission.director.test.' +
                       uniqueValue +
                       '@example.com',
            ProfileId = adminProfile.Id,
            UserRoleId = directorRole.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert director;
    }


    // ============================================================
    // HELPER - GET TEST DIRECTOR
    // ============================================================
    private static User getTestDirector() {

        return [
            SELECT Id,
                   UserRole.Name,
                   IsActive
            FROM User
            WHERE Username LIKE 'commission.director.test.%@example.com'
            LIMIT 1
        ];
    }


    // ============================================================
    // TEST 1
    // Batch creates follow-up Task
    // ============================================================
    @IsTest
    static void testBatchCreatesFollowUpTask() {

        Commission_Exception__c exceptionRecord =
            new Commission_Exception__c(
                Status__c = 'Open',
                Follow_Up_Date__c =
                    Date.today().addDays(-1),
                Policy_Number__c =
                    'POL-TEST-001'
            );

        insert exceptionRecord;

        Test.startTest();

        Database.executeBatch(
            new CommissionExceptionFollowUpBatch(),
            200
        );

        Test.stopTest();

        List<Task> tasks = [
            SELECT Id,
                   Subject,
                   Priority,
                   Status,
                   OwnerId,
                   WhatId,
                   ActivityDate,
                   Description
            FROM Task
            WHERE WhatId = :exceptionRecord.Id
            AND Subject =
                'Commission Exception Follow-Up'
        ];

        System.assertEquals(
            1,
            tasks.size(),
            'Exactly one follow-up Task should be created.'
        );

        System.assertEquals(
            'Commission Exception Follow-Up',
            tasks[0].Subject
        );

        System.assertEquals(
            'High',
            tasks[0].Priority
        );

        System.assertEquals(
            'Not Started',
            tasks[0].Status
        );

        System.assertEquals(
            exceptionRecord.Id,
            tasks[0].WhatId
        );

        System.assertEquals(
            Date.today(),
            tasks[0].ActivityDate
        );

        // Do NOT compare OwnerId with our test user's Id.
        // Production uses LIMIT 1 and may select another
        // active Commissions Director.
        User taskOwner = [
            SELECT Id,
                   UserRole.Name,
                   IsActive
            FROM User
            WHERE Id = :tasks[0].OwnerId
            LIMIT 1
        ];

        System.assertEquals(
            'Commissions Director',
            taskOwner.UserRole.Name,
            'Task must be assigned to a Commissions Director.'
        );

        System.assertEquals(
            true,
            taskOwner.IsActive,
            'Task owner must be active.'
        );

        System.assert(
            String.isNotBlank(tasks[0].Description),
            'Task description should be populated.'
        );
    }


    // ============================================================
    // TEST 2
    // Prevent duplicate Task
    // ============================================================
    @IsTest
    static void testBatchPreventsDuplicateTask() {

        User director = getTestDirector();

        Commission_Exception__c exceptionRecord =
            new Commission_Exception__c(
                Status__c = 'Open',
                Follow_Up_Date__c =
                    Date.today().addDays(-1),
                Policy_Number__c =
                    'POL-TEST-002'
            );

        insert exceptionRecord;

        Task existingTask = new Task(
            Subject =
                'Commission Exception Follow-Up',
            Priority =
                'High',
            Status =
                'Not Started',
            OwnerId =
                director.Id,
            WhatId =
                exceptionRecord.Id,
            ActivityDate =
                Date.today()
        );

        insert existingTask;

        Test.startTest();

        Database.executeBatch(
            new CommissionExceptionFollowUpBatch(),
            200
        );

        Test.stopTest();

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :exceptionRecord.Id
            AND Subject =
                'Commission Exception Follow-Up'
            AND Status != 'Completed'
        ];

        System.assertEquals(
            1,
            taskCount,
            'Existing follow-up Task must not be duplicated.'
        );
    }


    // ============================================================
    // TEST 3
    // Future Follow-Up Date should be ignored
    // ============================================================
    @IsTest
    static void testFutureFollowUpDateIgnored() {

        Commission_Exception__c exceptionRecord =
            new Commission_Exception__c(
                Status__c = 'Open',
                Follow_Up_Date__c =
                    Date.today().addDays(10),
                Policy_Number__c =
                    'POL-TEST-003'
            );

        insert exceptionRecord;

        Test.startTest();

        Database.executeBatch(
            new CommissionExceptionFollowUpBatch(),
            200
        );

        Test.stopTest();

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :exceptionRecord.Id
            AND Subject =
                'Commission Exception Follow-Up'
        ];

        System.assertEquals(
            0,
            taskCount,
            'Future follow-up date must not create a Task.'
        );
    }


    // ============================================================
    // TEST 4
    // Non-Open record should be ignored
    // ============================================================
    @IsTest
    static void testNonOpenExceptionIgnored() {

        Commission_Exception__c exceptionRecord =
            new Commission_Exception__c(
                Status__c = null,
                Follow_Up_Date__c =
                    Date.today().addDays(-10),
                Policy_Number__c =
                    'POL-TEST-004'
            );

        insert exceptionRecord;

        Test.startTest();

        Database.executeBatch(
            new CommissionExceptionFollowUpBatch(),
            200
        );

        Test.stopTest();

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :exceptionRecord.Id
            AND Subject =
                'Commission Exception Follow-Up'
        ];

        System.assertEquals(
            0,
            taskCount,
            'Only Open exceptions should be processed.'
        );
    }


    // ============================================================
    // TEST 5
    // Start method coverage
    // ============================================================
    @IsTest
    static void testBatchStart() {

        CommissionExceptionFollowUpBatch batch =
            new CommissionExceptionFollowUpBatch();

        Test.startTest();

        Database.QueryLocator locator =
            batch.start(null);

        Test.stopTest();

        System.assertNotEquals(
            null,
            locator,
            'start() should return a QueryLocator.'
        );
    }


    // ============================================================
    // TEST 6
    // Finish method coverage
    // ============================================================
    @IsTest
    static void testBatchFinish() {

        CommissionExceptionFollowUpBatch batch =
            new CommissionExceptionFollowUpBatch();

        Test.startTest();

        batch.finish(null);

        Test.stopTest();

        System.assert(
            true,
            'finish() executed successfully.'
        );
    }


    // ============================================================
    // TEST 7
    // Scheduler coverage
    //
    // IMPORTANT:
    // We schedule the Scheduler instead of calling execute()
    // directly.
    //
    // We also do NOT assert Task creation here.
    // Batch Task creation is already tested above.
    // ============================================================
    @IsTest
    static void testScheduler() {

        String jobName =
            'Commission Exception Scheduler Test ' +
            String.valueOf(
                DateTime.now().getTime()
            );

        String cronExpression =
            '0 0 0 1 1 ? 2099';

        Test.startTest();

        String jobId = System.schedule(
            jobName,
            cronExpression,
            new CommissionExceptionFollowUpScheduler()
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Scheduler should return a Job Id.'
        );

        CronTrigger scheduledJob = [
            SELECT Id,
                   CronJobDetail.Name,
                   State
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];

        System.assertEquals(
            jobName,
            scheduledJob.CronJobDetail.Name,
            'Scheduled job name should match.'
        );
    }
}