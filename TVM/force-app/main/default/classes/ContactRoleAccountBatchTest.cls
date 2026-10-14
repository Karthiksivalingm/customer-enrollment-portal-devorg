@IsTest
private class ContactRoleAccountBatchTest {

    // Mock callout if triggers do callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"ok"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testBatchWithMock() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create test accounts and contacts (same as before)
        List<Account> accounts = new List<Account>{
            new Account(Name='Test Account 1')
        };
        insert accounts;

        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName='Primary', LastName='Contact', AccountId=accounts[0].Id, Contact_Role__c='Foundation Primary'),
            new Contact(FirstName='Secondary', LastName='Contact', AccountId=accounts[0].Id, Contact_Role__c='Foundation Secondary')
        };
        insert contacts;

        // Execute batch
        Test.startTest();
        ContactRoleAccountBatch batch = new ContactRoleAccountBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Assertions
        Account acc = [SELECT Id, Primary_Contact__c, Secondary_Contact__c FROM Account WHERE Id=:accounts[0].Id];
        System.assertNotEquals(null, acc.Primary_Contact__c);
        System.assertNotEquals(null, acc.Secondary_Contact__c);
    }
}