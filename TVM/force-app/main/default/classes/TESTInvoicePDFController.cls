@istest
public class TESTInvoicePDFController {
   @isTest(seeAllData = true)
    static void TestInvoicePDF(){
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        List<Opportunity> lstopp = [Select Id from Opportunity where AccountId != null Limit 1];

        List<List<String>> s = new List<List<String>>{
    		new List<String>{'sknox@teamvelocitymarketing.com', lstopp[0].Id},
    		new List<String>{'dchen@teamvelocitymarketing.com', lstopp[0].Id}
		};
            
      	InvoicePDFController.generatePDF(s);
        Test.StopTest();
    }
    private class RestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}