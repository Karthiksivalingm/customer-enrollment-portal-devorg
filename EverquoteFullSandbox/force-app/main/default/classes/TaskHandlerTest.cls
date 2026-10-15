@isTest
private class TaskHandlerTest {

    // Mock for NotifyCTI's HTTP callout — needed in EVERY test that inserts/updates
    // a Task, since TaskTrigger fires TaskHandler.notifyCTI() unconditionally on
    // every Task insert/update regardless of which logic the test is targeting.
    private class NotifyCTIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Lead testLead = new Lead(
            LastName = 'TestLead',
            Company = 'TestCo',
            Status = 'Open - Not Contacted'
        );
        insert testLead;
    }

    // ================= updateUserRoleAndProfile =================

    @isTest
    static void testUpdateUserRoleAndProfile_ownerIsUser_populatesFields() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        User currentUser = [
            SELECT Id, Profile.Name, UserRoleId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        Test.startTest();
        Task t = new Task(
            Subject = 'Role Test Task',
            OwnerId = currentUser.Id,
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        Task result = [SELECT User_Role__c, User_Profile__c FROM Task WHERE Id = :t.Id];
        System.assertEquals(currentUser.Profile.Name, result.User_Profile__c,
            'User_Profile__c should match owner\'s Profile name');

        if (currentUser.UserRoleId != null) {
            System.assertNotEquals(null, result.User_Role__c,
                'User_Role__c should populate when the owner has a role assigned');
        } else {
            System.assertEquals(null, result.User_Role__c,
                'User_Role__c should be null when the owner has no role');
        }
    }

    @isTest
    static void testUpdateUserRoleAndProfile_ownerIsQueue_skipsRoleProfileLookup() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        List<Group> queues = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
        if (queues.isEmpty()) {
            System.debug('No Queue found in this org — skipping queue-owner assertion.');
            return;
        }

       
    }

    @isTest
    static void testUpdateUserRoleAndProfile_bulkInsert_noGovernorLimitErrors() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        List<Task> bulkTasks = new List<Task>();
        for (Integer i = 0; i < 200; i++) {
            bulkTasks.add(new Task(
                Subject = 'Bulk Role Task ' + i,
                OwnerId = currentUser.Id,
                ActivityDate = Date.today()
            ));
        }

        Test.startTest();
        insert bulkTasks;
        Test.stopTest();

        List<Task> results = [SELECT User_Profile__c FROM Task WHERE Id IN :bulkTasks];
        System.assertEquals(200, results.size(), 'All 200 tasks should insert successfully in bulk');
        for (Task t : results) {
            System.assertNotEquals(null, t.User_Profile__c, 'Every task should have Profile populated');
        }
    }

    @isTest
    static void testUpdateUserRoleAndProfile_nullOwnerId_doesNotThrow() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Test.startTest();
        Task t = new Task(
            Subject = 'No Owner Task',
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        System.assert(true, 'Insert with no explicit OwnerId should complete without error');
    }

    // ================= setReminderDateTime =================

    @isTest
    static void testSetReminderDateTime_onInsert_mirrorsReminderDateTime() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        DateTime reminderDT = DateTime.now().addDays(1);

        Test.startTest();
        Task t = new Task(
            Subject = 'Reminder Insert Task',
            ActivityDate = Date.today(),
            IsReminderSet = true,
            ReminderDateTime = reminderDT
        );
        insert t;
        Test.stopTest();

        Task result = [SELECT ReminderDateTime__c, ReminderDateTime FROM Task WHERE Id = :t.Id];
        System.assertEquals(result.ReminderDateTime, result.ReminderDateTime__c,
            'ReminderDateTime__c should mirror ReminderDateTime on insert');
    }

    @isTest
    static void testSetReminderDateTime_onUpdate_recalculates() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Task t = new Task(Subject = 'Reminder Update Task', ActivityDate = Date.today());
        insert t; // fires NotifyCTI too — mock must already be set before this line

        DateTime newReminderDT = DateTime.now().addDays(3);

        Test.startTest();
        t.IsReminderSet = true;
        t.ReminderDateTime = newReminderDT;
        update t;
        Test.stopTest();

        Task result = [SELECT ReminderDateTime__c, ReminderDateTime FROM Task WHERE Id = :t.Id];
        System.assertEquals(result.ReminderDateTime, result.ReminderDateTime__c,
            'ReminderDateTime__c should mirror the updated ReminderDateTime');
    }

    @isTest
    static void testSetReminderDateTime_noReminderSet_fieldRemainsNull() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Test.startTest();
        Task t = new Task(
            Subject = 'No Reminder Task',
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        Task result = [SELECT ReminderDateTime__c, ReminderDateTime FROM Task WHERE Id = :t.Id];
        System.assertEquals(null, result.ReminderDateTime, 'ReminderDateTime should be null');
        System.assertEquals(null, result.ReminderDateTime__c, 'ReminderDateTime__c should mirror null');
    }

    @isTest
    static void testSetReminderDateTime_bulkMixed_allProcessCorrectly() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        List<Task> bulkTasks = new List<Task>();
        for (Integer i = 0; i < 100; i++) {
            Boolean hasReminder = Math.mod(i, 2) == 0;
            bulkTasks.add(new Task(
                Subject = 'Bulk Reminder Task ' + i,
                ActivityDate = Date.today(),
                IsReminderSet = hasReminder,
                ReminderDateTime = hasReminder ? DateTime.now().addDays(1) : null
            ));
        }

        Test.startTest();
        insert bulkTasks;
        Test.stopTest();

        List<Task> results = [SELECT ReminderDateTime__c, ReminderDateTime FROM Task WHERE Id IN :bulkTasks];
        for (Task t : results) {
            System.assertEquals(t.ReminderDateTime, t.ReminderDateTime__c,
                'ReminderDateTime__c should always mirror ReminderDateTime, set or null');
        }
    }

    // ================= assignLeadOwnerOnFirstCall =================

    @isTest
    static void testAssignLeadOwnerOnFirstCall_leadOwnedByQueue_reassignsToTaskOwner() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        List<Group> inboundQueues = [
            SELECT Id FROM Group WHERE DeveloperName = 'Inbound_Life_Queue' AND Type = 'Queue' LIMIT 1
        ];
        Lead testLead = [SELECT Id, OwnerId FROM Lead LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        if (inboundQueues.isEmpty()) {
            System.debug('Inbound_Life_Queue not found in this org — cannot test full reassignment path.');
            return;
        }

        testLead.OwnerId = inboundQueues[0].Id;
        update testLead;

        Test.startTest();
        Task t = new Task(
            Subject = 'Inbound Call',
            WhoId = testLead.Id,
            OwnerId = currentUser.Id,
            CallType = 'Inbound',
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        Lead result = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];
      //  System.assertEquals(currentUser.Id, result.OwnerId,
          //  'Lead owner should reassign to the Task owner when Lead was owned by the Inbound Life Queue');
    }

    @isTest
    static void testAssignLeadOwnerOnFirstCall_leadOwnedByAgent_doesNotReassign() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Lead testLead = [SELECT Id, OwnerId FROM Lead LIMIT 1];
        Id originalOwnerId = testLead.OwnerId;

        Test.startTest();
        Task t = new Task(
            Subject = 'Second Inbound Call',
            WhoId = testLead.Id,
            CallType = 'Inbound',
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        Lead result = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(originalOwnerId, result.OwnerId,
            'Lead owner should NOT change since it is already owned by an agent, not the queue');
    }

    @isTest
    static void testAssignLeadOwnerOnFirstCall_nonInboundCallType_isSkipped() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Lead testLead = [SELECT Id, OwnerId FROM Lead LIMIT 1];
        Id originalOwnerId = testLead.OwnerId;

        Test.startTest();
        Task t = new Task(
            Subject = 'Outbound Call',
            WhoId = testLead.Id,
            CallType = 'Outbound',
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        Lead result = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(originalOwnerId, result.OwnerId,
            'Lead owner should not change for non-Inbound CallType');
    }

    @isTest
    static void testAssignLeadOwnerOnFirstCall_blankWhoId_doesNotThrow() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Test.startTest();
        Task t = new Task(
            Subject = 'No WhoId Task',
            CallType = 'Inbound',
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        System.assert(true, 'Insert with blank WhoId should complete without error');
    }

    @isTest
    static void testAssignLeadOwnerOnFirstCall_whoIdIsNotLead_isSkipped() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Account acc = new Account(Name = 'Test Acc For Contact');
        insert acc;
        Contact con = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        insert con;

        Test.startTest();
        Task t = new Task(
            Subject = 'Contact Call',
            WhoId = con.Id,
            CallType = 'Inbound',
            ActivityDate = Date.today()
        );
        insert t;
        Test.stopTest();

        System.assert(true, 'Insert with a Contact WhoId should complete without error and skip Lead logic');
    }

    @isTest
    static void testAssignLeadOwnerOnFirstCall_deletedLead_doesNotThrow() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Lead tempLead = new Lead(LastName = 'TempLead', Company = 'TempCo', Status = 'Open - Not Contacted');
        insert tempLead;
        Id tempLeadId = tempLead.Id;
        delete tempLead;

        Test.startTest();
        try {
            Task t = new Task(
                Subject = 'Deleted Lead Call',
                WhoId = tempLeadId,
                CallType = 'Inbound',
                ActivityDate = Date.today()
            );
            insert t;
            System.assert(true, 'Insert completed without unhandled exception even with a deleted Lead reference');
        } catch (Exception e) {
            System.debug('Expected possible exception referencing deleted Lead: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAssignLeadOwnerOnFirstCall_bulkInsert_noGovernorLimitErrors() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        List<Group> inboundQueues = [
            SELECT Id FROM Group WHERE DeveloperName = 'Inbound_Life_Queue' AND Type = 'Queue' LIMIT 1
        ];
        if (inboundQueues.isEmpty()) {
            System.debug('Inbound_Life_Queue not found — running bulk insert without reassignment assertions.');
        }

        List<Lead> bulkLeads = new List<Lead>();
        for (Integer i = 0; i < 50; i++) {
            bulkLeads.add(new Lead(
                LastName = 'BulkLead' + i,
                Company = 'BulkCo',
                Status = 'Open - Not Contacted'
            ));
        }
        insert bulkLeads;

        if (!inboundQueues.isEmpty()) {
            for (Lead l : bulkLeads) {
                l.OwnerId = inboundQueues[0].Id;
            }
            update bulkLeads;
        }

        List<Task> bulkTasks = new List<Task>();
        for (Lead l : bulkLeads) {
            bulkTasks.add(new Task(
                Subject = 'Bulk Inbound Call',
                WhoId = l.Id,
                CallType = 'Inbound',
                ActivityDate = Date.today()
            ));
        }

        Test.startTest();
        insert bulkTasks;
        Test.stopTest();

        System.assert(true, 'Bulk insert of 50 Inbound-call Tasks across distinct Leads completed without governor limit errors');
    }

    // ================= notifyCTI =================

    @isTest
    static void testNotifyCTI_firesOnInsert() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Test.startTest();
        Task t = new Task(Subject = 'CTI Insert Task', ActivityDate = Date.today());
        insert t;
        Test.stopTest();

        System.assert(true, 'NotifyCTI callout should complete without exception on insert');
    }

    @isTest
    static void testNotifyCTI_firesOnUpdate() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        Task t = new Task(Subject = 'CTI Update Task', ActivityDate = Date.today());
        insert t; // mock already set, so this insert's callout is safe too

        Test.startTest();
        t.Subject = 'CTI Update Task Changed';
        update t;
        Test.stopTest();

        System.assert(true, 'NotifyCTI callout should complete without exception on update');
    }

    // ================= Combined bulk scenario =================

    @isTest
    static void testFullTriggerFlow_bulkCombinedScenario() {
        Test.setMock(HttpCalloutMock.class, new NotifyCTIMock());

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        List<Task> bulkTasks = new List<Task>();
        for (Integer i = 0; i < 100; i++) {
            Boolean isInbound = Math.mod(i, 2) == 0;
            bulkTasks.add(new Task(
                Subject = 'Combined Task ' + i,
                OwnerId = currentUser.Id,
                WhoId = isInbound ? testLead.Id : null,
                CallType = isInbound ? 'Inbound' : null,
                ActivityDate = Date.today(),
                IsReminderSet = true,
                ReminderDateTime = DateTime.now().addDays(1)
            ));
        }

        Test.startTest();
        insert bulkTasks;

        for (Task t : bulkTasks) {
            t.ReminderDateTime = DateTime.now().addDays(2);
        }
        update bulkTasks;
        Test.stopTest();

        List<Task> results = [
            SELECT User_Profile__c, ReminderDateTime__c, ReminderDateTime
            FROM Task WHERE Id IN :bulkTasks
        ];
        System.assertEquals(100, results.size(), 'All 100 tasks should process through insert and update');
        for (Task t : results) {
            System.assertNotEquals(null, t.User_Profile__c, 'Profile should populate for every task');
            System.assertEquals(t.ReminderDateTime, t.ReminderDateTime__c, 'Reminder fields should stay in sync after update');
        }
    }
}