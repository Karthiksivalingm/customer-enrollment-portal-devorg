@isTest
public class NIPRAddTargets_Testclass {
    
    // Fake HTTP Mock to avoid real callouts
    private class FakeHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }
    
    @isTest
    static void testNIPRAddTargets_Queueable() {
        // Insert test NAICProducerCode__c
        NAICProducerCode__c npc = new NAICProducerCode__c(Name='TestCode', NPNNumber__c='17595388');
        insert npc;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FakeHttpResponseGenerator());
        
        System.enqueueJob(new NIPRAddTargets(new List<NAICProducerCode__c>{npc}));
        
        Test.stopTest();
        
        System.assertEquals(1, [SELECT COUNT() FROM NAICProducerCode__c]);
    }
    
    @isTest
    static void testNIPRAddTargetsHelper_withContact() {
        // Insert Contact with NPN__c
        Contact c = new Contact(LastName='Test Con', NPN__c='12345678');
        insert c;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FakeHttpResponseGenerator());
        
        // Call helper with contact Id
        NIPRAddTargetsHelper.execute(new Set<Id>{c.Id});
        
        Test.stopTest();
        
        System.assertEquals('12345678', [SELECT NPN__c FROM Contact WHERE Id=:c.Id].NPN__c);
    }
    
    @isTest
    static void testNIPRAddTargetsHelper_withAccount() {
        // Insert Account with NPN_Number__c
        Account acc = new Account(Name='Test Acc', NPN_Number__c='98765432');
        insert acc;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FakeHttpResponseGenerator());
        
        // Call helper with account Id
        NIPRAddTargetsHelper.execute(new Set<Id>{acc.Id});
        
        Test.stopTest();
        
        System.assertEquals('98765432', [SELECT NPN_Number__c FROM Account WHERE Id=:acc.Id].NPN_Number__c);
    }
}