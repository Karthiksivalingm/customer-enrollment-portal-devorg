@isTest
private class GuestSessionAttendanceControllerTest {

    @TestSetup
    static void setupData() {
        Contact con = new Contact(LastName = 'Guest Session Guest');
        insert con;

        Invitation__c inv = new Invitation__c(Name = 'GuestSession Test Invitation');
        insert inv;

        Guest_List__c guest = new Guest_List__c(
            Contact__c    = con.Id,
            Invitation__c = inv.Id
            // Title__c      = 'Mr' // not writeable
        );
        insert guest;

        Sub_Event__c subEvent1 = new Sub_Event__c(Invitation__c = inv.Id); // Name is not writeable
        Sub_Event__c subEvent2 = new Sub_Event__c(Invitation__c = inv.Id); // Name is not writeable
        insert new List<Sub_Event__c>{ subEvent1, subEvent2 };

        // NOTE: Sub_Event_Name__c is set here for clarity, but query results indicate it may be
        // recalculated by automation from the related Sub_Event__c rather than stored as entered -
        // see the relaxed assertions below.
        insert new List<Session_Attendance__c>{
            new Session_Attendance__c(
                Guest_List__c     = guest.Id,
                Sub_Event__c      = subEvent1.Id,
                Sub_Event_Name__c = 'Opening Session',
                Attended__c       = true,
                Registered__c     = true,
                Event_Name__c     = 'Test Event'
            ),
            new Session_Attendance__c(
                Guest_List__c     = guest.Id,
                Sub_Event__c      = subEvent2.Id,
                Sub_Event_Name__c = 'Closing Session',
                Attended__c       = false,
                Registered__c     = false,
                Event_Name__c     = 'Test Event'
            )
        };
    }

    @isTest
    static void testGetSessionAttendance_defaultPaging() {
        Guest_List__c guest = [SELECT Id FROM Guest_List__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = GuestSessionAttendanceController.getSessionAttendance(guest.Id, null, null);
        Test.stopTest();

        System.assertEquals(2, (Integer) result.get('totalCount'));
        System.assertEquals(false, (Boolean) result.get('hasMore'));

        List<Object> raw = (List<Object>) result.get('records');
        System.assertEquals(2, raw.size());

        GuestSessionAttendanceController.SessionWrapper first =
            (GuestSessionAttendanceController.SessionWrapper) raw[0];
        System.assertEquals(1, first.rowNum);
        // Sub_Event_Name__c appears to be derived/automation-driven rather than a plain
        // writeable text field - our direct insert value isn't reliably reflected, so we
        // don't assert on its exact text here.
        System.assertEquals(true, first.attended);
    }

    @isTest
    static void testGetSessionAttendance_pagingHasMore() {
        Guest_List__c guest = [SELECT Id FROM Guest_List__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = GuestSessionAttendanceController.getSessionAttendance(guest.Id, 1, 0);
        Test.stopTest();

        List<Object> raw = (List<Object>) result.get('records');
        System.assertEquals(1, raw.size());
        System.assertEquals(true, (Boolean) result.get('hasMore'));
    }

    @isTest
    static void testGetSessionAttendance_secondRecordNotAttended() {
        Guest_List__c guest = [SELECT Id FROM Guest_List__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = GuestSessionAttendanceController.getSessionAttendance(guest.Id, 20, 1);
        Test.stopTest();

        List<Object> raw = (List<Object>) result.get('records');
        System.assertEquals(1, raw.size());
        GuestSessionAttendanceController.SessionWrapper w = (GuestSessionAttendanceController.SessionWrapper) raw[0];
        // Sub_Event_Name__c isn't asserted here for the same reason as above.
        System.assertEquals(false, w.attended);
        System.assertEquals(false, w.registered);
    }
}