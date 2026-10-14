@isTest
public class accountListToSendEmail_Test {

    // Generate unique values
    private static String uniqueSuffix() {        
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    // Mock class to handle callouts
    private class MockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @isTest
    public static void test() {

        String suf = uniqueSuffix();

        // Create Account 1
        Account acc = new Account(
            Name = 'testacc2',
            Active__c = true,
            Type = 'Dealer Group',
            Quickbase_Record_ID__c = suf
        );
        insert acc;

        // Create Contact
        Contact con = new Contact(
            LastName = 'test1',
            Email = 'test1@gmail.com',
            AccountId = acc.Id
        );
        insert con;

        // Create Account 2
        Account accRecord2 = new Account(
            Name = 'Test Acc3',
            Quickbase_Record_ID__c = suf + '1'
        );
        insert accRecord2;

        // Create Account Contact Relation
        AccountContactRelation accCon = new AccountContactRelation(
            AccountId = accRecord2.Id,
            ContactId = con.Id,
            Roles = 'All'
        );
        insert accCon;

        Test.startTest();

        // Register mock callout handler (REQUIRED)
        Test.setMock(HttpCalloutMock.class, new MockCallout());

        String accId = acc.Id;

        // Call the methods
        accountListToSendEmail.fetchAccount();
        accountListToSendEmail.listofEmailTemplates('SAMPLE: New Account Manager', accId, 'All Contacts');
        accountListToSendEmail.getContactRelation(accId, 'All Contacts');
        accountListToSendEmail.getContactRelation(accId, 'All');

        Test.stopTest();
    }
}