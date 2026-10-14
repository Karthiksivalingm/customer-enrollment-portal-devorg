@istest
public class TESTSendAttachmentHandler {
   @isTest(seeAllData = true)
   static void TestinBoundEmail()
   
   {
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
      	
      	List<Opportunity> lstopp = [Select Id from Opportunity where AccountId != null Limit 1];
      	
      	String feedback=SendAttachmentHandler.SendAttachment('dchen@teamvelocitymarketing.com', lstopp[0].Id);
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