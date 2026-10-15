@isTest
private class SwoogoEventSyncServiceTest {

    @isTest
    static void testUpsertEventsInsertsNew() {
        SwoogoApiClient.SwoogoEvent e = new SwoogoApiClient.SwoogoEvent();
        e.id = 1001;
        e.name = 'New Event';
        e.status = 'active';
        e.start_date = '2026-06-01';
        e.end_date = '2026-06-02';
        e.location = 'Test City';
        e.updated_at = '2026-01-01 00:00:00';

        Test.startTest();
        SwoogoEventSyncService.upsertEvents(
            new List<SwoogoApiClient.SwoogoEvent>{ e }, 'FULL');
        Test.stopTest();

        Invitation__c inv = [
            SELECT Id, Name, Status__c, Location__c
            FROM Invitation__c WHERE External_Event_Id__c = '1001' LIMIT 1
        ];
        System.assertEquals('New Event', inv.Name);
        System.assertEquals('Active', inv.Status__c);
    }

    @isTest
    static void testUpsertEventsUpdatesExisting() {
        Invitation__c inv = new Invitation__c(
            External_Event_Id__c = '1001',
            Name = 'Old Name',
            Status__c = 'Draft'
        );
        insert inv;

        SwoogoApiClient.SwoogoEvent e = new SwoogoApiClient.SwoogoEvent();
        e.id = 1001;
        e.name = 'Updated Name';
        e.status = 'live';
        e.location = 'New Location';
        e.event_venue_type = 'Virtual';
        e.updated_at = '2026-02-01 00:00:00';

        Test.startTest();
        SwoogoEventSyncService.upsertEvents(
            new List<SwoogoApiClient.SwoogoEvent>{ e }, 'DELTA');
        Test.stopTest();

        Invitation__c updated = [SELECT Name, Status__c FROM Invitation__c WHERE Id = :inv.Id];
        System.assertEquals('Updated Name', updated.Name);
        System.assertEquals('Active', updated.Status__c);
    }

    @isTest
    static void testUpsertEventsMarksDeletedAsCancelled() {
        Invitation__c inv = new Invitation__c(
            External_Event_Id__c = '2002',
            Name = 'Cancel Me',
            Status__c = 'Active'
        );
        insert inv;

        SwoogoApiClient.SwoogoEvent e = new SwoogoApiClient.SwoogoEvent();
        e.id = 2002;
        e.name = 'Cancel Me';
        e.status = 'deleted';

        Test.startTest();
        SwoogoEventSyncService.upsertEvents(
            new List<SwoogoApiClient.SwoogoEvent>{ e }, 'DELTA');
        Test.stopTest();

        Invitation__c updated = [SELECT Status__c FROM Invitation__c WHERE Id = :inv.Id];
        System.assertEquals('Cancelled', updated.Status__c);
    }

    @isTest
    static void testUpsertEventsSkipsNewDeletedEvent() {
        SwoogoApiClient.SwoogoEvent e = new SwoogoApiClient.SwoogoEvent();
        e.id = 3003;
        e.name = 'Never Existed';
        e.status = 'archived';

        Test.startTest();
        SwoogoEventSyncService.upsertEvents(
            new List<SwoogoApiClient.SwoogoEvent>{ e }, 'FULL');
        Test.stopTest();

        List<Invitation__c> results = [
            SELECT Id FROM Invitation__c WHERE External_Event_Id__c = '3003'
        ];
        System.assertEquals(0, results.size());
    }

    @isTest
    static void testUpsertEventsNullAndEmptyNoOp() {
        Test.startTest();
        SwoogoEventSyncService.upsertEvents(null, 'FULL');
        SwoogoEventSyncService.upsertEvents(new List<SwoogoApiClient.SwoogoEvent>(), 'FULL');
        Test.stopTest();
        System.assert(true); // no exception = pass
    }

    @isTest
    static void testMapStatusAllBranches() {
        System.assertEquals(null, SwoogoEventSyncService.mapStatus(null));
        System.assertEquals('Draft', SwoogoEventSyncService.mapStatus('draft'));
        System.assertEquals('Active', SwoogoEventSyncService.mapStatus('active'));
        System.assertEquals('Active', SwoogoEventSyncService.mapStatus('published'));
        System.assertEquals('Active', SwoogoEventSyncService.mapStatus('live'));
        System.assertEquals('Cancelled', SwoogoEventSyncService.mapStatus('deleted'));
        System.assertEquals('Cancelled', SwoogoEventSyncService.mapStatus('archived'));
        System.assertEquals('Cancelled', SwoogoEventSyncService.mapStatus('closed'));
        System.assertEquals('weird', SwoogoEventSyncService.mapStatus('weird'));
    }

    @isTest
    static void testSyncAllEventsAndDeltaAndByIds() {
        Test.setMock(HttpCalloutMock.class, new SwoogoCalloutMock());
        Test.startTest();
        SwoogoEventSyncService.syncAllEvents();
        SwoogoEventSyncService.syncDeltaEvents(Datetime.now().addDays(-1));
        SwoogoEventSyncService.syncEventIds(new Set<String>{ '1001' });
        Test.stopTest();

        List<Invitation__c> results = [
            SELECT Id FROM Invitation__c WHERE External_Event_Id__c = '1001'
        ];
        System.assert(!results.isEmpty());
    }
}