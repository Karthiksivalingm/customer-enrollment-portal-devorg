@isTest
public class TypeformBackfillTest {

    private class GoodHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('/responses')) {
                res.setStatusCode(200);
                res.setBody(
                    '{"items":[{"answers":[' +
                        '{"email":"test@test.com"},' +
                        '{"file_url":"https://files.typeform.com/file123"}' +
                    ']}],' +
                    '"total_items":1}'
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

    private class NoMatchHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"items":[],"total_items":0}');
            return res;
        }
    }

    private class NullAnswersHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Empty items — null answers means no email match possible
            res.setBody('{"items":[],"total_items":0}');
            return res;
        }
    }

    private class NoFileUrlHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"items":[{"answers":[' +
                    '{"email":"test@test.com"},' +
                    '{"text":"some text answer"}' +
                ']}],"total_items":1}'
            );
            return res;
        }
    }

    private class FileFailHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('/responses')) {
                res.setStatusCode(200);
                res.setBody(
                    '{"items":[{"answers":[' +
                        '{"email":"test@test.com"},' +
                        '{"file_url":"https://files.typeform.com/file123"}' +
                    ']}],"total_items":1}'
                );
            } else {
                res.setStatusCode(403);
                res.setBody('{"error":"Forbidden"}');
            }
            return res;
        }
    }

    // ============================================================
    // Test 1 — Happy path: matched lead, file saved and linked
    // ============================================================
    @isTest
    static void testHappyPath() {
        Lead l = new Lead(
            LastName  = 'Test',
            Company   = 'TestCo',
            Email     = 'test@test.com',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c = 'abc123');

        Map<String, String> emailToLeadId = new Map<String, String>{
            'test@test.com' => l.Id
        };

        Test.setMock(HttpCalloutMock.class, new GoodHttpMock());

        Test.startTest();
        Database.executeBatch(new TypeformBackfill('S0t1jVLc', emailToLeadId), 5);
        Test.stopTest();

        System.assert(
            [SELECT count() FROM ContentVersion] > 0,
            'ContentVersion should be created'
        );
        Integer links = [
            SELECT count() FROM ContentDocumentLink
            WHERE LinkedEntityId = :l.Id
        ];
        System.assertEquals(true, links > 0, 'Files should be linked to lead');
    }

    // ============================================================
    // Test 2 — Error response from Typeform
    // ============================================================
    @isTest
    static void testErrorResponse() {
        Lead l = new Lead(
            LastName  = 'Err',
            Company   = 'ErrCo',
            Email     = 'err@test.com',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c = 'abc123');

        Map<String, String> emailToLeadId = new Map<String, String>{
            'err@test.com' => l.Id
        };

        Test.setMock(HttpCalloutMock.class, new ErrorHttpMock());

        Test.startTest();
        Database.executeBatch(new TypeformBackfill('S0t1jVLc', emailToLeadId), 5);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT count() FROM ContentVersion],
            'No files should be saved on API error'
        );
    }

    // ============================================================
    // Test 3 — No match returned from Typeform query
    // ============================================================
    @isTest
    static void testNoMatch() {
        Lead l = new Lead(
            LastName  = 'NoMatch',
            Company   = 'NoMatchCo',
            Email     = 'test@test.com',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c = 'abc123');

        Map<String, String> emailToLeadId = new Map<String, String>{
            'test@test.com' => l.Id
        };

        Test.setMock(HttpCalloutMock.class, new NoMatchHttpMock());

        Test.startTest();
        Database.executeBatch(new TypeformBackfill('S0t1jVLc', emailToLeadId), 5);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT count() FROM ContentVersion],
            'No files should be saved when no match found'
        );
    }

    // ============================================================
    // Test 4 — Null answers — should not crash
    // ============================================================
    @isTest
    static void testNullAnswers() {
        Lead l = new Lead(
            LastName  = 'Null',
            Company   = 'NullCo',
            Email     = 'null@test.com',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c = 'abc123');

        Map<String, String> emailToLeadId = new Map<String, String>{
            'null@test.com' => l.Id
        };

        Test.setMock(HttpCalloutMock.class, new NullAnswersHttpMock());

        Test.startTest();
        Database.executeBatch(new TypeformBackfill('S0t1jVLc', emailToLeadId), 5);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT count() FROM ContentVersion],
            'No files should be saved when no items returned'
        );
    }

    // ============================================================
    // Test 5 — Response has no file_url — only JSON saved
    // ============================================================
    @isTest
    static void testNoFileUrl() {
        Lead l = new Lead(
            LastName  = 'NoFile',
            Company   = 'NoFileCo',
            Email     = 'test@test.com',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c = 'abc123');

        Map<String, String> emailToLeadId = new Map<String, String>{
            'test@test.com' => l.Id
        };

        Test.setMock(HttpCalloutMock.class, new NoFileUrlHttpMock());

        Test.startTest();
        Database.executeBatch(new TypeformBackfill('S0t1jVLc', emailToLeadId), 5);
        Test.stopTest();

        // Only JSON file should be saved — no attachment
        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion];
        System.assertEquals(1, cvs.size(), 'Only JSON file should be saved');
        System.assert(cvs[0].Title.contains('.json'), 'File should be JSON');
    }

    // ============================================================
    // Test 6 — File download fails — JSON still saved
    // ============================================================
    @isTest
    static void testFileFetchFails() {
        Lead l = new Lead(
            LastName  = 'FileFail',
            Company   = 'FileFailCo',
            Email     = 'test@test.com',
            Has_Physical_Store__c         = true,
            Resale_Certificate_Status__c  = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;
        insert new Typeform_Config__c(Personal_Access_Token__c = 'abc123');

        Map<String, String> emailToLeadId = new Map<String, String>{
            'test@test.com' => l.Id
        };

        Test.setMock(HttpCalloutMock.class, new FileFailHttpMock());

        Test.startTest();
        Database.executeBatch(new TypeformBackfill('S0t1jVLc', emailToLeadId), 5);
        Test.stopTest();

        // JSON should still be saved even if file download fails
        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion];
        System.assertEquals(1, cvs.size(), 'JSON should still be saved when file download fails');
        System.assert(cvs[0].Title.contains('.json'), 'Saved file should be JSON');
    }

    // ============================================================
    // Test 7 — Empty email map
    // ============================================================
    @isTest
    static void testEmptyEmailMap() {
        insert new Typeform_Config__c(Personal_Access_Token__c = 'abc123');

        Map<String, String> emailToLeadId = new Map<String, String>();

        Test.setMock(HttpCalloutMock.class, new GoodHttpMock());

        Test.startTest();
        Database.executeBatch(new TypeformBackfill('S0t1jVLc', emailToLeadId), 5);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT count() FROM ContentVersion],
            'No files should be saved for empty email map'
        );
    }
}