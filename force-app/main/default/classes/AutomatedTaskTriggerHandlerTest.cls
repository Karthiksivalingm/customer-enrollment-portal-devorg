/**
 * AutomatedTaskTriggerHandlerTest
 *
 * Covers:
 *  1. A Task inserted as the "Automated Process" system user with
 *     TaskSubtype = 'Email' gets deleted immediately (the real EAC case).
 *  2. A normal Task (not Email subtype) is left alone.
 *  3. An Email-subtype Task created by a REAL user (not Automated Process)
 *     is left alone - this is the important negative case, since it's
 *     the one most likely to break if the CreatedBy filter is ever
 *     loosened or removed.
 *  4. Bulk insert (200 records) works without hitting governor limits.
 *
 * NOTE: System.runAs(automatedProcessUser) relies on every org having a
 * built-in User record with UserType = 'AutomatedProcess'. This is
 * standard in all orgs, but if your org restricts runAs for this user,
 * fall back to the manual sandbox test described alongside this class.
 */
@isTest
private class AutomatedTaskTriggerHandlerTest {

    @isTest
    static void testAutomatedEmailTaskIsDeleted() {
        // Query by Name, not UserType - some orgs have more than one system
        // user with UserType = 'AutomatedProcess' (e.g. a Chatter/bot user),
        // and the handler's delete filter matches on Name specifically.
        User automatedUser = [SELECT Id FROM User WHERE Name = 'Automated Process' LIMIT 1];

        Test.startTest();
        System.runAs(automatedUser) {
            Task t = new Task(
                Subject = 'EAC Email',
                TaskSubtype = 'Email',
                Status = 'Completed',
                ActivityDate = Date.today()
            );
            insert t;
        }
        Test.stopTest();

        List<Task> remaining = [SELECT Id FROM Task WHERE Subject = 'EAC Email'];
        System.assertEquals(0, remaining.size(),
            'Task created by Automated Process with TaskSubtype=Email should be deleted');
    }

    @isTest
    static void testNonEmailTaskIsNotDeleted() {
        Task t = new Task(
            Subject = 'Manual follow-up',
            TaskSubtype = 'Task',
            Status = 'Not Started'
        );
        insert t;

        List<Task> remaining = [SELECT Id FROM Task WHERE Subject = 'Manual follow-up'];
        System.assertEquals(1, remaining.size(),
            'Non-Email tasks should never be touched by this trigger');
    }

    @isTest
    static void testEmailTaskFromRealUserIsNotDeleted() {
        // Same TaskSubtype as the EAC case, but created by the running
        // test user, not the Automated Process user - must be preserved.
        Task t = new Task(
            Subject = 'Logged Email',
            TaskSubtype = 'Email',
            Status = 'Completed'
        );
        insert t;

        List<Task> remaining = [SELECT Id FROM Task WHERE Subject = 'Logged Email'];
        System.assertEquals(1, remaining.size(),
            'Email tasks created by a real user must not be deleted, only ones from Automated Process');
    }

    @isTest
    static void testBulkInsertDoesNotHitLimits() {
        User automatedUser = [SELECT Id FROM User WHERE Name = 'Automated Process' LIMIT 1];

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 200; i++) {
            tasks.add(new Task(
                Subject = 'Bulk EAC ' + i,
                TaskSubtype = 'Email',
                Status = 'Completed'
            ));
        }

        Test.startTest();
        System.runAs(automatedUser) {
            insert tasks;
        }
        Test.stopTest();

        List<Task> remaining = [SELECT Id FROM Task WHERE Subject LIKE 'Bulk EAC%'];
        System.assertEquals(0, remaining.size(),
            'All 200 bulk-inserted automated email tasks should be deleted without hitting limits');
    }
}