@IsTest
private class SwoogoEventServiceTest {

    @IsTest
    static void testHandleEventCreated_InsertNew() {
        // --- Prepare mock payload ---
        SwoogoEventService.WebhookPayload payload = new SwoogoEventService.WebhookPayload();
        payload.action = 'created';
        payload.objectType = 'event';
        payload.event = new SwoogoEventService.EventPayload();
        payload.event.id = 1001L;
        payload.event.name = 'Test Swoogo Event';
        payload.event.start_date = '2025-10-05';
        payload.event.end_date = '2025-10-06';
        payload.event.location = 'Paris';

        // --- Prepare mock REST request ---
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/events';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoEventService.handleEventCreated();
        Test.stopTest();

        // --- Validate inserted Invitation ---
        Invitation__c inv = [SELECT Name, Event_Start_Date__c, Event_End_Date__c, Location__c, External_Event_Id__c
                             FROM Invitation__c 
                             WHERE External_Event_Id__c = :String.valueOf(payload.event.id)
                             LIMIT 1];
        System.assertEquals('Test Swoogo Event', inv.Name);
        System.assertEquals(Date.newInstance(2025, 10, 05), inv.Event_Start_Date__c);
        System.assertEquals(Date.newInstance(2025, 10, 06), inv.Event_End_Date__c);
        System.assertEquals('Paris', inv.Location__c);

        // --- Validate Webhook log ---
        Webhook_Log_c__c log = [SELECT Status__c FROM Webhook_Log_c__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('Processed', log.Status__c);
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest
    static void testHandleEventCreated_UpdateExisting() {
        // --- Insert existing Invitation ---
        Invitation__c inv = new Invitation__c(
            Name = 'Old Event',
            External_Event_Id__c = '2002',
            Event_Start_Date__c = Date.newInstance(2025, 10, 01),
            Event_End_Date__c = Date.newInstance(2025, 10, 02),
            Location__c = 'London'
        );
        insert inv;

        // --- Prepare updated payload ---
        SwoogoEventService.WebhookPayload payload = new SwoogoEventService.WebhookPayload();
        payload.action = 'updated';
        payload.objectType = 'event';
        payload.event = new SwoogoEventService.EventPayload();
        payload.event.id = 2002L;
        payload.event.name = 'Updated Event Name';
        payload.event.start_date = '2025-10-10';
        payload.event.end_date = '2025-10-11';
        payload.event.location = 'Berlin';

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/events';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoEventService.handleEventCreated();
        Test.stopTest();

        // --- Re-query updated Invitation ---
        inv = [SELECT Name, Event_Start_Date__c, Event_End_Date__c, Location__c
               FROM Invitation__c 
               WHERE External_Event_Id__c = '2002'
               LIMIT 1];

        System.assertEquals('Old Event', inv.Name);
        System.assertEquals('London', inv.Location__c);
        System.assertEquals(Date.newInstance(2025, 10, 01), inv.Event_Start_Date__c);
        System.assertEquals(Date.newInstance(2025, 10, 02), inv.Event_End_Date__c);
    }

    @IsTest
    static void testHandleEventCreated_EmptyBody() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/events';
        req.httpMethod = 'POST';
        req.requestBody = null;

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoEventService.handleEventCreated();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Empty body'));
    }

    @IsTest
    static void testHandleEventCreated_MissingEventPayload() {
        SwoogoEventService.WebhookPayload payload = new SwoogoEventService.WebhookPayload();
        payload.action = 'created';
        payload.objectType = 'event';
        payload.event = null;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/events';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoEventService.handleEventCreated();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Missing event payload'));
    }

    @IsTest
    static void testHandleEventCreated_ExceptionHandling() {
        SwoogoEventService.WebhookPayload payload = new SwoogoEventService.WebhookPayload();
        payload.event = new SwoogoEventService.EventPayload();
        payload.event.id = 3003L;
        payload.event.name = 'Broken Date Event';
        payload.event.start_date = 'InvalidDate'; // triggers exception

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/swoogo/events';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoEventService.handleEventCreated();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Error'));
    }
}