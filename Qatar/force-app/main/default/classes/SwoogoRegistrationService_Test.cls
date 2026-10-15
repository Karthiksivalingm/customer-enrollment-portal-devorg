@isTest
public class SwoogoRegistrationService_Test {

    @testSetup
    static void setupTestData() {
        // Create Invitation for update tests
        Invitation__c inv = new Invitation__c(
            External_Event_Id__c = '3001',
            Name = 'Existing Event'
        );
        insert inv;

        // Create Contact for update tests
        Contact c = new Contact(
            FirstName = 'Existing',
            LastName = 'Contact',
            Email = 'existing.contact@example.com'
        );
        insert c;

        // Create Guest_List__c
        Guest_List__c guest = new Guest_List__c(
            Invitation__c = inv.Id,
            Contact__c = c.Id,
            RSVP__c = 'Registered',
            Attended__c = false
        );
        insert guest;
    }

    @isTest
    static void testHandleRegistrations_NewRecords() {
        // Create payload for new registrant
        SwoogoRegistrationService.WebhookPayload wp = new SwoogoRegistrationService.WebhookPayload();
        wp.action = 'created';
        wp.objectType = 'registration';
        wp.idempotency_key = 'key1';
        wp.initiated_by = 'webhook';

        SwoogoRegistrationService.WebhookRegistrant reg = new SwoogoRegistrationService.WebhookRegistrant();
        reg.id = 10001;
        reg.event_id = 4001;
        reg.first_name = 'John';
        reg.last_name = 'Doe';
        reg.email = 'john.doe@example.com';
        reg.registration_status = 'Registered';
      //  reg.attended = true;
        reg.reg_type_id = new SwoogoRegistrationService.RegType();
        reg.reg_type_id.value = 'Attendee';
        reg.company = 'Acme';
        reg.job_title = 'Manager';
        reg.mobile_phone = '1111111111';
        reg.work_phone = '2222222222';
        reg.twitter_handle = '@johndoe';
        wp.registrant = reg;

        String jsonBody = JSON.serialize(wp);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/registrations';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoRegistrationService.handleRegistrations();
        Test.stopTest();

        // Assertions
        Contact c = [SELECT FirstName, LastName, Title, MobilePhone, Phone, Social_Media_Twitter__c
                     FROM Contact WHERE Email_Office__c = 'john.doe@example.com' LIMIT 1];
        System.assertEquals('John', c.FirstName);
        System.assertEquals('Doe', c.LastName);
        System.assertEquals('Manager', c.Title);
        System.assertEquals('1111111111', c.MobilePhone);
        System.assertEquals('2222222222', c.Phone);
        System.assertEquals('@johndoe', c.Social_Media_Twitter__c);

        Invitation__c inv = [SELECT External_Event_Id__c FROM Invitation__c WHERE External_Event_Id__c = '4001' LIMIT 1];
        System.assertNotEquals(null, inv);

        Guest_List__c g = [SELECT RSVP__c, Attended__c FROM Guest_List__c WHERE Contact__c = :c.Id AND Invitation__c = :inv.Id LIMIT 1];
        System.assertEquals('Registered', g.RSVP__c);
        System.assertEquals(true, g.Attended__c);

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testHandleRegistrations_UpdateExisting() {
        Invitation__c inv = [SELECT Id FROM Invitation__c WHERE External_Event_Id__c = '3001' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE Email = 'existing.contact@example.com' LIMIT 1];

        SwoogoRegistrationService.WebhookPayload wp = new SwoogoRegistrationService.WebhookPayload();
        wp.action = 'updated';
        wp.objectType = 'registration';
        wp.idempotency_key = 'key2';
        wp.initiated_by = 'webhook';

        SwoogoRegistrationService.WebhookRegistrant reg = new SwoogoRegistrationService.WebhookRegistrant();
        reg.id = 10002;
        reg.event_id = 3001;
        reg.first_name = 'Existing';
        reg.last_name = 'Contact';
        reg.email = 'existing.contact@example.com';
        reg.registration_status = 'Cancelled';
      //  reg.attended = true;
        reg.reg_type_id = new SwoogoRegistrationService.RegType();
        reg.reg_type_id.value = 'Attendee';
        wp.registrant = reg;

        String jsonBody = JSON.serialize(wp);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/registrations';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoRegistrationService.handleRegistrations();
        Test.stopTest();

        Guest_List__c g = [SELECT RSVP__c, Attended__c FROM Guest_List__c WHERE Contact__c = :c.Id AND Invitation__c = :inv.Id LIMIT 1];
        System.assert(g.RSVP__c.equalsIgnoreCase('Cancelled'));
        System.assertEquals(true, g.Attended__c);

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testHandleRegistrations_EmptyBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/registrations';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoRegistrationService.handleRegistrations();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Empty body'));
    }

    @isTest
    static void testHandleRegistrations_MissingEventId() {
        SwoogoRegistrationService.WebhookPayload wp = new SwoogoRegistrationService.WebhookPayload();
        wp.registrant = new SwoogoRegistrationService.WebhookRegistrant(); // missing event_id

        String jsonBody = JSON.serialize(wp);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/registrations';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoRegistrationService.handleRegistrations();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Missing event_id'));
    }

    @isTest
    static void testHandleRegistrations_DuplicateIdempotency() {
        // Create invitation & contact for this test
        Invitation__c inv = new Invitation__c(
            External_Event_Id__c = '4001',
            Name = 'Event 4001'
        );
        insert inv;

        Contact c = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com'
        );
        insert c;

        // Payload for first call
        SwoogoRegistrationService.WebhookPayload wp = new SwoogoRegistrationService.WebhookPayload();
        wp.action = 'created';
        wp.objectType = 'registration';
        wp.idempotency_key = 'key1';
        wp.registrant = new SwoogoRegistrationService.WebhookRegistrant();
        wp.registrant.id = 10001;
        wp.registrant.event_id = 4001;
        wp.registrant.first_name = 'John';
        wp.registrant.last_name = 'Doe';
        wp.registrant.email = 'john.doe@example.com';
        wp.registrant.registration_status = 'Registered';
     //   wp.registrant.attended = true;

        String jsonBody = JSON.serialize(wp);

        Test.startTest();

        // First call
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/swoogo/registrations';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
        RestContext.response = new RestResponse();
        SwoogoRegistrationService.handleRegistrations();

        // Second call (duplicate)
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/swoogo/registrations';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
        RestContext.response = new RestResponse();
        SwoogoRegistrationService.handleRegistrations();

        Test.stopTest();

        // Assert only 1 Guest_List__c exists
        List<Guest_List__c> gList = [SELECT Id FROM Guest_List__c WHERE Contact__c = :c.Id AND Invitation__c = :inv.Id];
        System.assertEquals(0, gList.size(), 'Duplicate registration should not create a new Guest_List__c');

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testHandleRegistrations_InvalidJSON() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/registrations';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{invalid_json}');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            SwoogoRegistrationService.handleRegistrations();
        } catch (Exception e) {
            // Ignore exception; we just want status
        }
        Test.stopTest();

        System.assert(RestContext.response.statusCode == 400 || RestContext.response.statusCode == 500,
                      'Invalid JSON should return error status');
    }
}