@isTest
private class Zendesktest {

    @isTest
    static void testWebhookCreatesCase() {

        // Create Contact for matching email
        Contact con = new Contact(
            LastName = 'Test Contact',
            Email = 'testuser@test.com'
        );
        insert con;

        // Mock JSON payload from Zendesk
        String jsonBody = JSON.serialize(new Map<String,Object>{
            'subject' => 'Test Ticket',
            'description' => 'Issue from Zendesk',
            'priority' => 'High',
            'RequestorName' => 'John Doe',
            'RequestorEmail' => 'testuser@test.com',
            'BrandName' => 'Test Brand',
            'RequestorType' => 'Technical',
            'ids' => 'ZD12345'
        });

        // Prepare REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/zendeskSfWebhook/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ZendeskWebhookAPI.handleWebhook();
        Test.stopTest();

        // Validate Case created
        Case c = [SELECT Id, Subject, Zendesk_ID__c, Priority, SuppliedEmail 
                  FROM Case 
                  WHERE Zendesk_ID__c = 'ZD12345'
                  LIMIT 1];

        System.assertEquals('Test Ticket', c.Subject);
        System.assertEquals('ZD12345', c.Zendesk_ID__c);
        System.assertEquals('High', c.Priority);
        System.assertEquals('testuser@test.com', c.SuppliedEmail);
    }


    @isTest
    static void testWebhookWithoutContact() {

        // JSON without existing contact
        String jsonBody = JSON.serialize(new Map<String,Object>{
            'subject' => 'Test Ticket 2',
            'description' => 'Issue from Zendesk',
            'priority' => 'Medium',
            'RequestorName' => 'Jane',
            'RequestorEmail' => 'nocontact@test.com',
            'BrandName' => 'Test Brand',
            'RequestorType' => 'Support',
            'ids' => 'ZD99999'
        });

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/zendeskSfWebhook/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ZendeskWebhookAPI.handleWebhook();
        Test.stopTest();

        // Verify case created even without contact
        Case c = [SELECT Id, SuppliedEmail 
                  FROM Case 
                  WHERE Zendesk_ID__c = 'ZD99999'
                  LIMIT 1];

        System.assertEquals('nocontact@test.com', c.SuppliedEmail);
    }
}