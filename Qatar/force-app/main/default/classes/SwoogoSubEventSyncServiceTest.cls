@isTest
private class SwoogoSubEventSyncServiceTest {

    private static Invitation__c makeInvitation() {
        Invitation__c inv = new Invitation__c(
            External_Event_Id__c = '1001',
            Name = 'Test Event'
        );
        insert inv;
        return inv;
    }

    @isTest
    static void testUpsertSubEventsInsertsNew() {
        Invitation__c inv = makeInvitation();

        SwoogoApiClient.SwoogoSession s = new SwoogoApiClient.SwoogoSession();
        s.id = 2001;
        s.name = 'Opening Session';
        s.session_date = '2026-06-01';
        s.start_time = '09:00:00';
        s.end_time = '10:00:00';
        s.description = '<p>Welcome &amp; intro</p>';
        s.updated_at = '2026-01-01 00:00:00';

        Test.startTest();
        SwoogoSubEventSyncService.upsertSubEvents(
            '1001', inv.Id, new List<SwoogoApiClient.SwoogoSession>{ s }, 'FULL');
        Test.stopTest();

        Sub_Event__c se = [
            SELECT Sub_Event_Name__c, Description__c, Start_DateTime__c
            FROM Sub_Event__c WHERE Sub_Event_ID__c = '2001' LIMIT 1
        ];
        System.assertEquals('Opening Session', se.Sub_Event_Name__c);
        System.assertEquals('Welcome & intro', se.Description__c);
        System.assertNotEquals(null, se.Start_DateTime__c);
    }

    @isTest
    static void testUpsertSubEventsUpdatesExisting() {
        Invitation__c inv = makeInvitation();
        Sub_Event__c existing = new Sub_Event__c(
            Sub_Event_ID__c = '2001',
            Invitation__c = inv.Id,
            Sub_Event_Name__c = 'Old Name'
        );
        insert existing;

        SwoogoApiClient.SwoogoSession s = new SwoogoApiClient.SwoogoSession();
        s.id = 2001;
        s.name = 'New Name';
        s.session_date = '2026-06-01';
        s.start_time = '11:00:00';
        s.end_time = '12:00:00';

        Test.startTest();
        SwoogoSubEventSyncService.upsertSubEvents(
            '1001', inv.Id, new List<SwoogoApiClient.SwoogoSession>{ s }, 'DELTA');
        Test.stopTest();

        Sub_Event__c updated = [SELECT Sub_Event_Name__c FROM Sub_Event__c WHERE Id = :existing.Id];
        System.assertEquals('New Name', updated.Sub_Event_Name__c);
    }

    @isTest
    static void testUpsertSubEventsNullInvitationIdNoOp() {
        SwoogoApiClient.SwoogoSession s = new SwoogoApiClient.SwoogoSession();
        s.id = 2001;
        s.name = 'Orphan Session';

        Test.startTest();
        SwoogoSubEventSyncService.upsertSubEvents(
            '1001', null, new List<SwoogoApiClient.SwoogoSession>{ s }, 'FULL');
        Test.stopTest();

        List<Sub_Event__c> results = [SELECT Id FROM Sub_Event__c WHERE Sub_Event_ID__c = '2001'];
        System.assertEquals(0, results.size());
    }

    @isTest
    static void testUpsertSubEventsEmptyListNoOp() {
        Test.startTest();
        SwoogoSubEventSyncService.upsertSubEvents(
            '1001', null, new List<SwoogoApiClient.SwoogoSession>(), 'FULL');
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void testSessionWithNoIdIsSkipped() {
        Invitation__c inv = makeInvitation();
        SwoogoApiClient.SwoogoSession s = new SwoogoApiClient.SwoogoSession();
        s.name = 'No Id Session';

        Test.startTest();
        SwoogoSubEventSyncService.upsertSubEvents(
            '1001', inv.Id, new List<SwoogoApiClient.SwoogoSession>{ s }, 'FULL');
        Test.stopTest();

        List<Sub_Event__c> results = [SELECT Id FROM Sub_Event__c WHERE Invitation__c = :inv.Id];
        System.assertEquals(0, results.size());
    }

    @isTest
    static void testSyncAllSubEventsAndDeltaViaMock() {
        Invitation__c inv = makeInvitation();
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        SwoogoSubEventSyncService.syncAllSubEvents('1001', inv.Id);
        SwoogoSubEventSyncService.syncDeltaSubEvents('1001', inv.Id, Datetime.now().addDays(-1));
        Test.stopTest();

        List<Sub_Event__c> results = [SELECT Id FROM Sub_Event__c WHERE Invitation__c = :inv.Id];
        System.assert(!results.isEmpty());
    }
}