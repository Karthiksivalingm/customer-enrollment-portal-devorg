/**
 * SwoogoApiClientTest
 *
 * PRECONDITION: requires at least one SwoogoConfig__mdt record already
 * deployed to this org (see SwoogoCalloutMock header comment).
 */
@isTest
private class SwoogoApiClientTest {

    @isTest
    static void testGetEventById() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        SwoogoApiClient.SwoogoEvent e = SwoogoApiClient.getEventById('1001');
        Test.stopTest();
        System.assertEquals(1001, e.id);
        System.assertEquals('Test Event', e.name);
    }

    @isTest
    static void testGetAllEvents() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        List<SwoogoApiClient.SwoogoEvent> events = SwoogoApiClient.getAllEvents();
        Test.stopTest();
        System.assert(!events.isEmpty());
    }

    @isTest
    static void testGetEventsUpdatedAfter() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        List<SwoogoApiClient.SwoogoEvent> events =
            SwoogoApiClient.getEventsUpdatedAfter(Datetime.now().addDays(-1));
        Test.stopTest();
        System.assert(!events.isEmpty());
    }

    @isTest
    static void testGetSessionsForEventAndDelta() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        List<SwoogoApiClient.SwoogoSession> sessions =
            SwoogoApiClient.getSessionsForEvent('1001');
        List<SwoogoApiClient.SwoogoSession> delta =
            SwoogoApiClient.getSessionsUpdatedAfter('1001', Datetime.now().addDays(-1));
        Test.stopTest();
        System.assert(!sessions.isEmpty());
        // SwoogoApiClient returns the raw description as Swoogo sends it —
        // HTML stripping happens later in SwoogoSubEventSyncService, not here.
        System.assertEquals('<p>Desc</p>', sessions[0].description);
        System.assert(!delta.isEmpty());
    }

    @isTest
    static void testGetRegistrantsForEventAndDelta() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        List<SwoogoApiClient.SwoogoRegistrant> regs =
            SwoogoApiClient.getRegistrantsForEvent('1001');
        List<SwoogoApiClient.SwoogoRegistrant> regsExtra =
            SwoogoApiClient.getRegistrantsForEvent('1001', new List<String>{'c_1001'});
        List<SwoogoApiClient.SwoogoRegistrant> delta =
            SwoogoApiClient.getRegistrantsUpdatedAfter('1001', Datetime.now().addDays(-1));
        List<SwoogoApiClient.SwoogoRegistrant> deltaExtra =
            SwoogoApiClient.getRegistrantsUpdatedAfter(
                '1001', Datetime.now().addDays(-1), new List<String>{'c_1001'});
        Test.stopTest();
        System.assert(!regs.isEmpty());
        System.assertEquals('2001', regs[0].session_ids[0]);
        System.assert(!regsExtra.isEmpty());
        System.assert(!delta.isEmpty());
        System.assert(!deltaExtra.isEmpty());
    }

    @isTest
    static void testGetRawRegistrants() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        List<Map<String,Object>> raw = SwoogoApiClient.getRawRegistrants(
            '1001', new List<String>{'c_1001'}, Datetime.now().addDays(-1));
        Test.stopTest();
        System.assert(!raw.isEmpty());
    }

    @isTest
    static void testGetSessionAttendancesAndDelta() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        List<SwoogoApiClient.SessionAttendance> att =
            SwoogoApiClient.getSessionAttendances('1001');
        List<SwoogoApiClient.SessionAttendance> deltaAtt =
            SwoogoApiClient.getSessionAttendancesUpdatedAfter('1001', Datetime.now().addDays(-1));
        Test.stopTest();
        System.assert(!att.isEmpty());
        System.assert(!deltaAtt.isEmpty());
    }

    @isTest
    static void testFindAndCreateContact() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        Long foundId = SwoogoApiClient.findContactIdByEmail('jane.doe@example.com');
        Long blankId = SwoogoApiClient.findContactIdByEmail('');
        Long createdId = SwoogoApiClient.createContact('new@example.com', 'New', 'Person', '003000000000001');
        Test.stopTest();
        System.assertEquals(9001, foundId);
        System.assertEquals(null, blankId);
        System.assertEquals(9002, createdId);
    }

    @isTest
    static void testUpdateContactExternalId() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        // No return value to assert on (void PUT) — this confirms the call
        // completes without throwing against the mocked endpoint.
        SwoogoApiClient.updateContactExternalId(9001L, '003000000000001');
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void testInvitationListsAndMembers() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        List<SwoogoApiClient.SwoogoInvitationList> lists =
            SwoogoApiClient.getInvitationListsForEvent('1001');
        List<SwoogoApiClient.SwoogoInvitationListMember> members =
            SwoogoApiClient.getInvitationListMembers(5001L);
        SwoogoApiClient.addContactToInvitationList(5001L, 9001L);
        SwoogoApiClient.addRegistrantToGroup(3001L, 3000L);
        Test.stopTest();
        System.assert(!lists.isEmpty());
        System.assert(!members.isEmpty());
    }

    @isTest
    static void testCreateRegistrantNewAndExisting() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        // registrants.json search returns an existing item -> should short-circuit
        Long existing = SwoogoApiClient.createRegistrant(
            1001L, null, 'Jane', 'Doe', 'jane.doe@example.com',
            'Acme', 'Manager', '1234567890', '003000000000001', 'VIP');
        Test.stopTest();
        System.assertEquals(3001, existing);
    }

    @isTest
    static void testGetOrCreateRegTypeIdCreatesNew() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        Long regTypeId = SwoogoApiClient.getOrCreateRegTypeId(1001L, 'VIP');
        Long blankResult = SwoogoApiClient.getOrCreateRegTypeId(1001L, '');
        Test.stopTest();
        System.assertEquals(7001, regTypeId);
        System.assertEquals(null, blankResult);
    }

    @isTest
    static void test429ThrowsAndCapturesResetHeader() {
        SwoogoCalloutMock mock = new SwoogoCalloutMock();
        mock.forceRateLimitOnce = true;
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Boolean threw = false;
        try {
            SwoogoApiClient.getEventById('1001');
        } catch (SwoogoApiClient.SwoogoException ex) {
            threw = true;
            System.assert(ex.getMessage().contains('429'));
        }
        Test.stopTest();
        System.assert(threw);
        System.assertEquals(5, SwoogoApiClient.lastRateLimitResetSeconds);
    }

    @isTest
    static void test401RetriesWithFreshToken() {
        SwoogoCalloutMock mock = new SwoogoCalloutMock();
        mock.forceUnauthorizedOnce = true;
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        SwoogoApiClient.SwoogoEvent e = SwoogoApiClient.getEventById('1001');
        Test.stopTest();
        System.assertEquals(1001, e.id);
    }

    @isTest
    static void testFormatDT() {
        Datetime dt = Datetime.newInstanceGmt(2026, 6, 1, 9, 0, 0);
        String formatted = SwoogoApiClient.formatDT(dt);
        System.assertEquals('2026-06-01T09:00:00Z', formatted);
    }
}