@isTest
private class SwoogoRegistrantSyncServiceTest {

    private static Invitation__c makeInvitation() {
        Invitation__c inv = new Invitation__c(External_Event_Id__c = '1001', Name = 'Test Event');
        insert inv;
        return inv;
    }

    @isTest
    static void testSyncRegistrantsResolvesByExternalId() {
        Contact c = new Contact(
            FirstName = 'Jane', LastName = 'Doe',
            contact_external_id__c = '9001'
        );
        insert c;
        Invitation__c inv = makeInvitation();
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id, Swoogo_Registrant_Id__c = '3001'
        );
        insert g;

        SwoogoApiClient.SwoogoRegistrant r = new SwoogoApiClient.SwoogoRegistrant();
        r.id = 3001; r.contact_id = '9001'; r.email = 'jane.doe@example.com';
        r.first_name = 'Jane'; r.last_name = 'Doe'; r.job_title = 'Manager';
        r.mobile_phone = '1234567890'; r.work_phone = '0987654321';
        r.registration_status = 'accepted'; r.deleted = false;

        Test.startTest();
        SwoogoRegistrantSyncService.syncRegistrants(
            new List<SwoogoApiClient.SwoogoRegistrant>{ r }, inv.Id);
        Test.stopTest();

        Contact updated = [SELECT Title, Email_Office__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('Manager', updated.Title);
        System.assertEquals('jane.doe@example.com', updated.Email_Office__c);

        Guest_List__c updatedG = [SELECT RSVP__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assertEquals('Accepted', updatedG.RSVP__c);
    }

    @isTest
    static void testSyncRegistrantsResolvesByEmailFallback() {
        Contact c = new Contact(FirstName = 'John', LastName = 'Smith', Email = 'john.smith@example.com');
        insert c;
        Invitation__c inv = makeInvitation();
        Guest_List__c g = new Guest_List__c(
            Contact__c = c.Id, Invitation__c = inv.Id, Swoogo_Registrant_Id__c = '3005'
        );
        insert g;

        SwoogoApiClient.SwoogoRegistrant r = new SwoogoApiClient.SwoogoRegistrant();
        r.id = 3005; r.email = 'john.smith@example.com';
        r.first_name = 'John'; r.last_name = 'Smith';
        r.registration_status = 'declined'; r.deleted = false;

        Test.startTest();
        SwoogoRegistrantSyncService.syncRegistrants(
            new List<SwoogoApiClient.SwoogoRegistrant>{ r }, inv.Id);
        Test.stopTest();

        Contact updated = [SELECT contact_external_id__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(null, updated.contact_external_id__c);

        Guest_List__c updatedG = [SELECT RSVP__c FROM Guest_List__c WHERE Id = :g.Id];
        System.assertEquals('Declined', updatedG.RSVP__c);
    }

    @isTest
    static void testSyncRegistrantsSkipsDeletedAndUnresolved() {
        Invitation__c inv = makeInvitation();

        SwoogoApiClient.SwoogoRegistrant deletedReg = new SwoogoApiClient.SwoogoRegistrant();
        deletedReg.id = 4001; deletedReg.deleted = true;

        SwoogoApiClient.SwoogoRegistrant unresolvedReg = new SwoogoApiClient.SwoogoRegistrant();
        unresolvedReg.id = 4002; unresolvedReg.email = 'nobody@nowhere.com'; unresolvedReg.deleted = false;

        Test.startTest();
        SwoogoRegistrantSyncService.syncRegistrants(
            new List<SwoogoApiClient.SwoogoRegistrant>{ deletedReg, unresolvedReg }, inv.Id);
        SwoogoRegistrantSyncService.syncRegistrants(null, inv.Id);
        SwoogoRegistrantSyncService.syncRegistrants(new List<SwoogoApiClient.SwoogoRegistrant>(), inv.Id);
        Test.stopTest();

        System.assert(true); // no exceptions = pass, nothing to link/update
    }

    @isTest
    static void testSyncRegistrantsBackfillsSwoogoRegistrantIdAndCustomFields() {
        Contact c = new Contact(
            FirstName = 'Amy', LastName = 'Lee', contact_external_id__c = '9010'
        );
        insert c;
        Invitation__c inv = makeInvitation();
        // Guest_List__c exists but has no Swoogo_Registrant_Id__c yet
        Guest_List__c g = new Guest_List__c(Contact__c = c.Id, Invitation__c = inv.Id);
        insert g;

        SwoogoApiClient.SwoogoRegistrant r = new SwoogoApiClient.SwoogoRegistrant();
        r.id = 4010; r.contact_id = '9010'; r.email = 'amy.lee@example.com';
        r.first_name = 'Amy'; r.last_name = 'Lee';
        r.registration_status = 'visited'; r.deleted = false;

        SwoogoQuestionMapService.EventQuestionMap qm = new SwoogoQuestionMapService.EventQuestionMap();
        qm.simpleFieldMap.put('Hotel_Name__c', 'c_1001');
        qm.inboundDateAttr = 'c_1002';
        qm.inboundTimeAttr = 'c_1003';
        qm.outboundDateAttr = 'c_1004';
        qm.outboundTimeAttr = 'c_1005';
        qm.buildCustomFieldsList();

        Map<String,Object> raw = new Map<String,Object>{
            'id' => 4010,
            'c_1001' => 'Hilton Downtown',
            'c_1002' => '2026-05-30', 'c_1003' => '14:00:00',
            'c_1004' => '2026-06-03', 'c_1005' => '09:00:00'
        };

        Test.startTest();
        SwoogoRegistrantSyncService.syncRegistrants(
            new List<SwoogoApiClient.SwoogoRegistrant>{ r }, inv.Id, qm,
            new List<Map<String,Object>>{ raw });
        Test.stopTest();

        Guest_List__c updatedG = [
            SELECT Swoogo_Registrant_Id__c, Hotel_Name__c,
                   Inbound_Date_Time__c, Outbound_Date_Time__c
            FROM Guest_List__c WHERE Id = :g.Id
        ];
        System.assertEquals('4010', updatedG.Swoogo_Registrant_Id__c);
        System.assertEquals('Hilton Downtown', updatedG.Hotel_Name__c);
        System.assertNotEquals(null, updatedG.Inbound_Date_Time__c);
        System.assertNotEquals(null, updatedG.Outbound_Date_Time__c);
    }
}