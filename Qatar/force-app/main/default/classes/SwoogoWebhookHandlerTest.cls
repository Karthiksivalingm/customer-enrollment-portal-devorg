@isTest
private class SwoogoWebhookHandlerTest {

    private static RestRequest buildRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/swoogo/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        return req;
    }

    @isTest
    static void testSessionEventTopLevelId() {
        RestContext.request = buildRequest(
            '{"event_type":"registrant.session.checkin","event_id":"1001"}');
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoWebhookHandler.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        List<Webhook_Log_c__c> logs = [SELECT Id, Status__c FROM Webhook_Log_c__c];
        System.assert(!logs.isEmpty());
    }

    @isTest
    static void testRegistrantEventNestedUnderData() {
        RestContext.request = buildRequest(
            '{"type":"registrant.updated","data":{"event_id":"1002"}}');
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoWebhookHandler.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testEventIdNestedUnderRegistrant() {
        RestContext.request = buildRequest(
            '{"event_type":"registrant.updated","registrant":{"event_id":"1003"}}');
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoWebhookHandler.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testUnhandledEventType() {
        RestContext.request = buildRequest('{"event_type":"something.else","event_id":"1004"}');
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoWebhookHandler.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testNoEventIdFoundAnywhere() {
        RestContext.request = buildRequest('{"event_type":"registrant.updated"}');
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoWebhookHandler.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testEmptyBody() {
        RestContext.request = buildRequest('');
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoWebhookHandler.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('empty body'));
    }

    @isTest
    static void testMalformedJsonReturnsErrorBodyButStill200() {
        RestContext.request = buildRequest('{not-valid-json');
        RestContext.response = new RestResponse();

        Test.startTest();
        SwoogoWebhookHandler.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('error'));
    }
}