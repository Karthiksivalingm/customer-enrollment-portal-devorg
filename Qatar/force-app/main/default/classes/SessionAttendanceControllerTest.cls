@isTest
private class SessionAttendanceControllerTest {

    @TestSetup
    static void setupData() {
        Contact con = new Contact(LastName = 'Session Guest');
        insert con;

        Invitation__c inv = new Invitation__c(Name = 'Session Test Invitation');
        insert inv;

        Guest_List__c guest = new Guest_List__c(
            Contact__c    = con.Id,
            Invitation__c = inv.Id
            // Title__c      = 'Mr' // not writeable
        );
        insert guest;

        Sub_Event__c subEvent = new Sub_Event__c(Invitation__c = inv.Id); // Name is not writeable
        insert subEvent;

        insert new List<Session_Attendance__c>{
            new Session_Attendance__c(
                Guest_Name__c = 'Session Guest',
                Guest_List__c = guest.Id,
                Sub_Event__c  = subEvent.Id,
                Attended__c   = true,
                Registered__c = true,
                Event_Name__c = 'Test Event'
            ),
            new Session_Attendance__c(
                Guest_Name__c = 'Another Guest',
                Guest_List__c = guest.Id,
                Sub_Event__c  = subEvent.Id,
                Attended__c   = false,
                Registered__c = true,
                Event_Name__c = 'Test Event'
            )
        };
    }

    @isTest
    static void testGetSessionAttendance_defaultPaging() {
        Sub_Event__c subEvent = [SELECT Id FROM Sub_Event__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = SessionAttendanceController.getSessionAttendance(subEvent.Id, null, null);
        Test.stopTest();

        System.assertEquals(2, (Integer) result.get('totalCount'));
        System.assertEquals(false, (Boolean) result.get('hasMore'));

        List<Object> raw = (List<Object>) result.get('records');
        System.assertEquals(2, raw.size());

        SessionAttendanceController.SessionAttendanceWrapper first =
            (SessionAttendanceController.SessionAttendanceWrapper) raw[0];
        System.assertEquals(1, first.rowNum);
        System.assertNotEquals(null, first.contactId);
    }

    @isTest
    static void testGetSessionAttendance_pagingHasMore() {
        Sub_Event__c subEvent = [SELECT Id FROM Sub_Event__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = SessionAttendanceController.getSessionAttendance(subEvent.Id, 1, 0);
        Test.stopTest();

        List<Object> raw = (List<Object>) result.get('records');
        System.assertEquals(1, raw.size());
        System.assertEquals(true, (Boolean) result.get('hasMore'));
    }

    @isTest
    static void testGetSessionAttendance_offsetBeyondRange() {
        Sub_Event__c subEvent = [SELECT Id FROM Sub_Event__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = SessionAttendanceController.getSessionAttendance(subEvent.Id, 20, 10);
        Test.stopTest();

        List<Object> raw = (List<Object>) result.get('records');
        System.assertEquals(0, raw.size());
        System.assertEquals(false, (Boolean) result.get('hasMore'));
    }
}