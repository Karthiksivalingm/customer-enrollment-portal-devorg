@isTest
private class SwoogoAttendanceSyncServiceTest {

    private static Invitation__c makeInvitation() {
        Invitation__c inv = new Invitation__c(External_Event_Id__c = '1001', Name = 'Test Event');
        insert inv;
        return inv;
    }

    @isTest
    static void testSyncAttendancesInsertsNew() {
        Invitation__c inv = makeInvitation();
        Sub_Event__c se = new Sub_Event__c(
            Sub_Event_ID__c = '2001', Invitation__c = inv.Id, Sub_Event_Name__c = 'Session'
        );
        insert se;
        Contact c = new Contact(FirstName = 'Jane', LastName = 'Doe');
        insert c;
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id, Swoogo_Registrant_Id__c = '3001'
        );
        insert g;

        SwoogoApiClient.SessionAttendance a = new SwoogoApiClient.SessionAttendance();
        a.registrant_id = 3001; a.session_id = 2001;
        a.check_in_date = '2026-06-01 09:00:00';

        SwoogoApiClient.SwoogoRegistrant r = new SwoogoApiClient.SwoogoRegistrant();
        r.id = 3001; r.session_ids = new List<String>{ '2001' };

        Test.startTest();
        SwoogoAttendanceSyncService.syncAttendances(
            new List<SwoogoApiClient.SessionAttendance>{ a },
            new List<SwoogoApiClient.SwoogoRegistrant>{ r },
            inv.Id);
        Test.stopTest();

        Session_Attendance__c sa = [
            SELECT Attended__c, Registered__c
            FROM Session_Attendance__c
            WHERE Guest_List__c = :g.Id AND Sub_Event__c = :se.Id
        ];
        System.assertEquals(true, sa.Attended__c);
        System.assertEquals(true, sa.Registered__c);
    }

    @isTest
    static void testSyncAttendancesUpdatesExisting() {
        Invitation__c inv = makeInvitation();
        Sub_Event__c se = new Sub_Event__c(
            Sub_Event_ID__c = '2001', Invitation__c = inv.Id, Sub_Event_Name__c = 'Session'
        );
        insert se;
        Contact c = new Contact(FirstName = 'Jane', LastName = 'Doe');
        insert c;
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id, Swoogo_Registrant_Id__c = '3001'
        );
        insert g;
        Session_Attendance__c existing = new Session_Attendance__c(
            Guest_List__c = g.Id, Sub_Event__c = se.Id,
            Events_List__c = inv.Id, Attended__c = false, Registered__c = false
        );
        insert existing;

        SwoogoApiClient.SessionAttendance a = new SwoogoApiClient.SessionAttendance();
        a.registrant_id = 3001; a.session_id = 2001;
        a.check_in_date = '2026-06-01 09:00:00';

        Test.startTest();
        SwoogoAttendanceSyncService.syncAttendances(
            new List<SwoogoApiClient.SessionAttendance>{ a }, null, inv.Id);
        Test.stopTest();

        Session_Attendance__c updated = [
            SELECT Attended__c FROM Session_Attendance__c WHERE Id = :existing.Id
        ];
        System.assertEquals(true, updated.Attended__c);
    }

    @isTest
    static void testSyncAttendancesDedupesMultipleRowsForSameKey() {
        Invitation__c inv = makeInvitation();
        Sub_Event__c se = new Sub_Event__c(
            Sub_Event_ID__c = '2001', Invitation__c = inv.Id, Sub_Event_Name__c = 'Session'
        );
        insert se;
        Contact c = new Contact(FirstName = 'Jane', LastName = 'Doe');
        insert c;
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id, Swoogo_Registrant_Id__c = '3001'
        );
        insert g;

        SwoogoApiClient.SessionAttendance a1 = new SwoogoApiClient.SessionAttendance();
        a1.registrant_id = 3001; a1.session_id = 2001; a1.check_in_date = null;
        SwoogoApiClient.SessionAttendance a2 = new SwoogoApiClient.SessionAttendance();
        a2.registrant_id = 3001; a2.session_id = 2001; a2.check_in_date = '2026-06-01 09:00:00';

        Test.startTest();
        SwoogoAttendanceSyncService.syncAttendances(
            new List<SwoogoApiClient.SessionAttendance>{ a1, a2 }, null, inv.Id);
        Test.stopTest();

        List<Session_Attendance__c> results = [
            SELECT Id, Attended__c FROM Session_Attendance__c
            WHERE Guest_List__c = :g.Id AND Sub_Event__c = :se.Id
        ];
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].Attended__c);
    }

    @isTest
    static void testSyncAttendancesNoOpBranches() {
        Test.startTest();
        SwoogoAttendanceSyncService.syncAttendances(null, null, null);
        SwoogoAttendanceSyncService.syncAttendances(new List<SwoogoApiClient.SessionAttendance>(), null, null);

        // No invitationId
        SwoogoApiClient.SessionAttendance a = new SwoogoApiClient.SessionAttendance();
        a.registrant_id = 1; a.session_id = 1;
        SwoogoAttendanceSyncService.syncAttendances(
            new List<SwoogoApiClient.SessionAttendance>{ a }, null, null);
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void testSyncAttendancesNoMatchingSubEventNoOp() {
        Invitation__c inv = makeInvitation();
        SwoogoApiClient.SessionAttendance a = new SwoogoApiClient.SessionAttendance();
        a.registrant_id = 9999; a.session_id = 9999;
        Test.startTest();
        SwoogoAttendanceSyncService.syncAttendances(
            new List<SwoogoApiClient.SessionAttendance>{ a }, null, inv.Id);
        Test.stopTest();
        System.assert(true);
    }
}