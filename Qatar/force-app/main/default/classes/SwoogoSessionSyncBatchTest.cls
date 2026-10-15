@isTest
private class SwoogoSessionSyncBatchTest {

    private static Invitation__c makeInvitation(String extId) {
        Invitation__c inv = new Invitation__c(External_Event_Id__c = extId, Name = 'Test Event');
        insert inv;
        return inv;
    }

    @isTest
    static void testFirstRunFetchesSessionsOnly() {
        makeInvitation('1001');
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());

        Test.startTest();
        Database.executeBatch(
            new SwoogoSessionSyncBatch(
                new List<String>{ '1001' }, true, null, Datetime.now()),
            1);
        Test.stopTest();

        List<Sub_Event__c> sessions = [SELECT Id FROM Sub_Event__c WHERE Sub_Event_ID__c = '2001'];
        System.assert(!sessions.isEmpty());
        // First run does not sync registrants/attendance
        List<Guest_List__c> guests = [SELECT Id FROM Guest_List__c];
        System.assertEquals(0, guests.size());
    }

    @isTest
    static void testDeltaRunFetchesSessionsRegistrantsAndAttendance() {
        Invitation__c inv = makeInvitation('1001');
        Sub_Event__c se = new Sub_Event__c(
            Sub_Event_ID__c = '2001', Invitation__c = inv.Id, Sub_Event_Name__c = 'Session'
        );
        insert se; // existing session -> event is NOT new to SF, gates attendance fetch

        // SwoogoRegistrantSyncService only UPDATES existing Contact/Guest_List__c
        // records — it never creates new ones — so a matching fixture must
        // already exist for the mock's registrant (id=3001, contact_id=9001,
        // email=jane.doe@example.com) to have anything to attach to.
        Contact c = new Contact(
            FirstName = 'Jane', LastName = 'Doe',
            Email = 'jane.doe@example.com', contact_external_id__c = '9001'
        );
        insert c;
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id, Swoogo_Registrant_Id__c = '3001'
        );
        insert g;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());

        Test.startTest();
        Database.executeBatch(
            new SwoogoSessionSyncBatch(
                new List<String>{ '1001' }, false, Datetime.now().addDays(-1), Datetime.now()),
            1);
        Test.stopTest();

        Guest_List__c updatedGuest = [SELECT RSVP__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assertEquals('Accepted', updatedGuest.RSVP__c);

        List<Session_Attendance__c> attendance = [
            SELECT Id, Attended__c FROM Session_Attendance__c
            WHERE Guest_List__c = :g.Id AND Sub_Event__c = :se.Id
        ];
        System.assert(!attendance.isEmpty());
        System.assertEquals(true, attendance[0].Attended__c);
    }

    @isTest
    static void testChunkingSchedulesFollowUpChunk() {
        // 7 events > CHUNK_SIZE (6), so finish() should call scheduleChunk()
        // for the remainder. Rather than relying on the scheduled job
        // actually firing during Test.stopTest() (unreliable in the Apex
        // test harness for a 3rd level of batch/schedule chaining), this
        // only verifies the reschedule itself was created.
        List<String> eventIds = new List<String>{
            '3001','3002','3003','3004','3005','3006','3007'
        };
        List<Invitation__c> invs = new List<Invitation__c>();
        for (String eid : eventIds) {
            invs.add(new Invitation__c(External_Event_Id__c = eid, Name = 'Event ' + eid));
        }
        insert invs;

        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        // Batch size must be >= what start() actually returns (6, after the
        // constructor's own chunking truncates 7 -> first 6 + 1 remainder)
        // or Salesforce tries to call execute() more than once, which Apex
        // test context does not support ("No more than one executeBatch can
        // be called from within a test method"). This constant is unrelated
        // to the app's own CHUNK_SIZE-based chunking, which already happened
        // in the constructor before start() ever runs.
        Database.executeBatch(
            new SwoogoSessionSyncBatch(eventIds, true, null, Datetime.now()), 10);
        Test.stopTest();

        // Salesforce never deletes CronTrigger rows for one-time jobs (it
        // only flips State to 'DELETED' once fired), so this row is present
        // whether or not the reschedule actually fired during stopTest().
        List<CronTrigger> scheduledChunks = [
            SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SwoogoP2Chunk%'
        ];
        System.assert(!scheduledChunks.isEmpty());

        // Abort every job found rather than assuming there's exactly one —
        // CronTrigger rows for un-fired scheduled jobs are not reliably
        // cleaned up by test-transaction rollback, so leaving this behind
        // can cause unrelated tests elsewhere (anything that checks for a
        // pending 'SwoogoP2Chunk%' job) to see a false positive.
        for (CronTrigger ct : scheduledChunks) {
            System.abortJob(ct.Id);
        }
    }

    @isTest
    static void testSkipsEventWithNoInvitation() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        Database.executeBatch(
            new SwoogoSessionSyncBatch(
                new List<String>{ '9999' }, true, null, Datetime.now()),
            1);
        Test.stopTest();
        System.assert(true); // no exception thrown, event logged & skipped
    }

    @isTest
    static void testConstructorDedupesEventIds() {
        makeInvitation('1001');
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        // Same id repeated — constructor should de-dupe before chunking
        Database.executeBatch(
            new SwoogoSessionSyncBatch(
                new List<String>{ '1001', '1001', '1001' }, true, null, Datetime.now()),
            1);
        Test.stopTest();

        List<Sub_Event__c> sessions = [SELECT Id FROM Sub_Event__c WHERE Sub_Event_ID__c = '2001'];
        System.assertEquals(1, sessions.size());
    }

    @isTest
    static void testNullEventIdListHandledGracefully() {
        Test.startTest();
        Database.executeBatch(new SwoogoSessionSyncBatch(null, true, null, Datetime.now()), 1);
        Test.stopTest();
        System.assert(true);
    }
}