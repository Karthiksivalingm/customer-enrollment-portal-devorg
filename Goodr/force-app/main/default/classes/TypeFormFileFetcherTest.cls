@isTest
public class TypeFormFileFetcherTest {
    
    private class GoodHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('/responses')) {
                res.setStatusCode(200);
                res.setBody(
                    '{"items":[{"answers":[' +
                        '{"email":"test@test.com"},' +
                        '{"file_url":"https://files.typeform.com/file123"},' +
                        '{"field":{"ref":"3ee1fca4-7fc5-4df1-892e-f536b5cc9b69"},"text":"123 Main St"},' +
                        '{"field":{"ref":"d40dc5ac-fe3a-4f32-82e7-14b4694258b1"},"text":"Toronto"},' +
                        '{"field":{"ref":"e1498e1d-1263-458c-9e8a-c5b1da2a951d"},"text":"ON"},' +
                        '{"field":{"ref":"55ecf75f-fd9a-4363-9c06-d3985466a2a4"},"text":"M5H 2N2"},' +
                        '{"field":{"ref":"82f6d6d7-0699-4b8a-9274-d8c5fb14ce3a"},"number":1500}' +
                    ']}]}'
                );
            } else if (req.getEndpoint().contains('file123')) {
                res.setStatusCode(200);
                res.setBodyAsBlob(Blob.valueOf('fake file content'));
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":"Bad request"}');
            }
            return res;
        }
    }
    
    private class ErrorHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Server error"}');
            return res;
        }
    }
    
    @IsTest
    static void testHappyPath() {
        Lead l = new Lead(
            LastName='Test', 
            Company='TestCo', 
            Email='test@test.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c='abc123');
        Test.setMock(HttpCalloutMock.class, new GoodHttpMock());
        
        TypeFormFileFetcherInvoker.Input inp = new TypeFormFileFetcherInvoker.Input();
        inp.leadId = l.Id;
        inp.formId = 'S0t1jVLc';

        Test.startTest();
        TypeFormFileFetcherInvoker.invoke(new List<TypeFormFileFetcherInvoker.Input>{ inp });
        Test.stopTest();

        System.assert([SELECT count() FROM ContentVersion] > 0);
        Integer links = [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :l.Id];

        System.assertEquals(true, links > 0);
        List<Store__c> stores = [SELECT Id, Address__c, Store_Square_Footage__c, Lead__c FROM Store__c];

        System.assertEquals(1, stores.size());
        System.assertEquals(l.Id, stores[0].Lead__c);
        System.assert(stores[0].Address__c.contains('Toronto'));
        System.assertEquals(1500, stores[0].Store_Square_Footage__c);
    }
    
    @IsTest
    static void testEmptyInputs() {
        Test.startTest();
        TypeFormFileFetcherInvoker.invoke(new List<TypeFormFileFetcherInvoker.Input>());
        Test.stopTest();
        System.assertEquals(0, [SELECT count() FROM ContentVersion]);
    }
    
    @IsTest
    static void testErrorResponse() {
        Lead l = new Lead(
            LastName='Err', 
            Company='ErrCo', 
            Email='err@test.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c='abc123');
        Test.setMock(HttpCalloutMock.class, new ErrorHttpMock());
        TypeFormFileFetcherInvoker.Input inp = new TypeFormFileFetcherInvoker.Input();
        inp.leadId = l.Id;
        inp.formId = 'formErr';

        Test.startTest();
        TypeFormFileFetcherInvoker.invoke(new List<TypeFormFileFetcherInvoker.Input>{ inp });
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM ContentVersion]);
    }
}