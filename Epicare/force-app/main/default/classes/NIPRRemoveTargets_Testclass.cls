@isTest
public class NIPRRemoveTargets_Testclass {
    
    // Simple mock response class
    private class NIPRMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "status": "SUCCESS" }');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testQueueableClass() {
        // Prepare test data
        NAICProducerCode__c nic = new NAICProducerCode__c(
            Name = 'test',
            NPNNumber__c = '17595388'
        );
        insert nic;

        List<NAICProducerCode__c> lstcodes = new List<NAICProducerCode__c>{nic};

        Test.startTest();
        // Set mock
        Test.setMock(HttpCalloutMock.class, new NIPRMockResponse());

        // Enqueue Queueable
        System.enqueueJob(new NIPRRemoveTargets(lstcodes));
        Test.stopTest();
    }

    @isTest
    static void testHelperClass() {
        // Prepare test data
        Set<String> idsList = new Set<String>{ '17595388', '12345678' };

        Test.startTest();
        // Set mock
        Test.setMock(HttpCalloutMock.class, new NIPRMockResponse());

        // Call @future method
        NIPRRemoveTargetsHelper.execute(idsList);
        Test.stopTest();
    }
}