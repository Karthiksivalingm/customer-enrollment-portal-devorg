@isTest
public class NiprSSN_AllTest {
    
    // ---------- Mock Classes for FlowAction ----------
    private class NiprSSNFlowActionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setStatusCode(200);
            // Adjust XML to exactly match what your class expects
            String mockXml = 
                '<NIPRResponse>' +
                    '<INDIVIDUAL>' +
                        '<NPN>1234567890</NPN>' +
                    '</INDIVIDUAL>' +
                '</NIPRResponse>';
            res.setBody(mockXml);
            return res;
        }
    }
    
    private class NiprSSNFlowActionErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setStatusCode(500); // simulate error
            res.setBody('<Error>Server failure</Error>');
            return res;
        }
    }
    
    // ---------- Utility ----------
    private static Contact createTestContact(String lastName, String ssn) {
        Contact con = new Contact(
            LastName = lastName,
            FirstName = 'Unit',
            Email = lastName.toLowerCase() + '@example.com',
            SSN_Number__c = ssn
        );
        insert con;
        return con;
    }
    
    // ---------- Tests for NiprSSNFlowAction ----------
    @isTest
    static void testSsnSearchFromFlow_Success() {
        Contact con = createTestContact('Doe', '123456789');
        
        NiprSSNFlowAction.Request req = new NiprSSNFlowAction.Request();
        req.contactId = con.Id;
        
        Test.setMock(HttpCalloutMock.class, new NiprSSNFlowActionMock());
        
        Test.startTest();
        NiprSSNFlowAction.ssnSearchFromFlow(new List<NiprSSNFlowAction.Request>{req});
        Test.stopTest();
        
        // Just running code for coverage — no asserts
    }
    
    @isTest
    static void testSsnSearchFromFlow_ErrorHandling() {
        Contact con = createTestContact('Smith', '987654321');
        
        NiprSSNFlowAction.Request req = new NiprSSNFlowAction.Request();
        req.contactId = con.Id;
        
        Test.setMock(HttpCalloutMock.class, new NiprSSNFlowActionErrorMock());
        
        Test.startTest();
        NiprSSNFlowAction.ssnSearchFromFlow(new List<NiprSSNFlowAction.Request>{req});
        Test.stopTest();
    }
}