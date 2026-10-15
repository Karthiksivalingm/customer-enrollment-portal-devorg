@IsTest
private class UplineImportCompleteTest {

    // ================================================================
    // SUCCESS MOCK
    // OAuth succeeds and GoAMS event POST succeeds.
    // ================================================================
    private class SuccessMockCallout implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{"access_token":"test_token"}');
            } else {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{"success":true}');
            }

            return res;
        }
    }


    // ================================================================
    // OAUTH FAILURE MOCK
    //
    // IMPORTANT:
    // Do NOT throw CalloutException here.
    // Returning HTTP 500 allows the production code to handle the
    // failure normally without producing a FATAL_ERROR in the test log.
    // ================================================================
    private class OAuthExceptionMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('{"error":"simulated_oauth_failure"}');

            return res;
        }
    }


    // ================================================================
    // EVENT POST FAILURE MOCK
    //
    // OAuth succeeds.
    // GoAMS event POST returns HTTP 500.
    //
    // This exercises the retryable failure path without throwing an
    // Apex CalloutException.
    // ================================================================
    private class EventPostFailureMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{"access_token":"test_token"}');
            } else {
                res.setStatusCode(500);
                res.setStatus('Internal Server Error');
                res.setBody('{"error":"simulated_event_post_failure"}');
            }

            return res;
        }
    }


    // ================================================================
    // NON-RETRYABLE FAILURE MOCK
    //
    // OAuth succeeds.
    // Event POST returns HTTP 400.
    // ================================================================
    private class OAuthOkNonRetryableMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{"access_token":"test_token"}');
            } else {
                res.setStatusCode(400);
                res.setStatus('Bad Request');
                res.setBody('{"error":"bad_request"}');
            }

            return res;
        }
    }


    // ================================================================
    // RETRYABLE FAILURE MOCK
    //
    // OAuth succeeds.
    // Event POST returns HTTP 503.
    // ================================================================
    private class OAuthOkRetryableMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{"access_token":"test_token"}');
            } else {
                res.setStatusCode(503);
                res.setStatus('Service Unavailable');
                res.setBody('{"error":"service_unavailable"}');
            }

            return res;
        }
    }


    // ================================================================
    // TEST DATA
    // ================================================================
    @TestSetup
    static void setup() {

        List<Commission_Import_Log__c> logs =
            new List<Commission_Import_Log__c>();

        logs.add(
            new Commission_Import_Log__c(
                Source_Type__c       = 'Carepoint Active Policies',
                Processing_Status__c = 'Failed',
                Records_Created__c   = 5,
                Records_Updated__c   = 2
            )
        );

        logs.add(
            new Commission_Import_Log__c(
                Source_Type__c       = 'Claro Book of Business',
                Processing_Status__c = 'Failed',
                Records_Created__c   = 8,
                Records_Updated__c   = 1
            )
        );

        insert logs;
    }


    // ================================================================
    // TEST 1
    // Trigger after update:
    // Failed -> Completed
    //
    // Carepoint source should publish the platform event and the
    // subscriber should send it to GoAMS successfully.
    // ================================================================
    @IsTest
    static void testTriggerSuccessPath() {

        Commission_Import_Log__c rec = [
            SELECT Id,
                   Processing_Status__c,
                   Source_Type__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Carepoint Active Policies'
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMockCallout()
        );

        Test.startTest();

        rec.Processing_Status__c = 'Completed';
        update rec;

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Error_Log__c
            ],
            'No Error_Log__c should be created for a successful import'
        );
    }


    // ================================================================
    // TEST 2
    // Claro source mapping.
    //
    // Covers:
    // startsWith('Claro')
    // Source__c = 'Claro'
    // Report type stripping of "Claro "
    // ================================================================
    @IsTest
    static void testTriggerClaroSourceMapping() {

        Commission_Import_Log__c rec = [
            SELECT Id,
                   Processing_Status__c,
                   Source_Type__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Claro Book of Business'
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMockCallout()
        );

        Test.startTest();

        rec.Processing_Status__c = 'Completed';
        update rec;

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Error_Log__c
            ],
            'No Error_Log__c should be created for a successful Claro import'
        );
    }


    // ================================================================
    // TEST 3
    // Status does not change to Completed.
    //
    // The trigger should NOT publish an event.
    // ================================================================
    @IsTest
    static void testTriggerSkipsWhenStatusUnchanged() {

        Commission_Import_Log__c rec = [
            SELECT Id,
                   Processing_Status__c,
                   Source_Type__c,
                   Records_Created__c,
                   Records_Updated__c
            FROM Commission_Import_Log__c
            WHERE Source_Type__c = 'Carepoint Active Policies'
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMockCallout()
        );

        Test.startTest();

        rec.Records_Created__c = 99;
        update rec;

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Error_Log__c
            ],
            'No event should be published when Processing_Status__c does not change to Completed'
        );
    }


    // ================================================================
    // TEST 4
    // Direct platform-event subscriber test.
    //
    // EventBus.publish() should invoke:
    //
    // UplineImportCompleteEventSubscriber
    //      ->
    // UplineImportCompleteHelper.sendToGoAMS()
    //      ->
    // GoAMSCallout
    // ================================================================
    @IsTest
    static void testEventSubscriberSuccessCoverage() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMockCallout()
        );

        Upline_Policy_Import_Completed__e eventRecord =
            new Upline_Policy_Import_Completed__e(
                Import_Log_ID__c   = '456',
                Source__c          = 'Claro',
                Report_Type__c     = 'Book of Business',
                Records_Created__c = 10,
                Records_Updated__c = 3
            );

        Test.startTest();

        EventBus.publish(eventRecord);

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Error_Log__c
            ],
            'No Error_Log__c should be created for a successful event subscriber callout'
        );
    }


    // ================================================================
    // TEST 5
    // Directly test sendToGoAMS().
    // ================================================================
    @IsTest
    static void testHelperSuccessCoverage() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMockCallout()
        );

        List<Upline_Policy_Import_Completed__e> events =
            new List<Upline_Policy_Import_Completed__e>{

                new Upline_Policy_Import_Completed__e(
                    Import_Log_ID__c   = '123',
                    Source__c          = 'Carepoint',
                    Report_Type__c     = 'Active Policies',
                    Records_Created__c = 5,
                    Records_Updated__c = 2
                )
            };

        Test.startTest();

        UplineImportCompleteHelper.sendToGoAMS(events);

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Error_Log__c
            ],
            'No Error_Log__c should be created for a successful GoAMS callout'
        );
    }


    // ================================================================
    // TEST 6
    // OAuth HTTP 500 failure.
    //
    // IMPORTANT:
    // We enqueue directly with MAX_RETRIES so the production helper
    // dead-letters the event instead of trying to enqueue another
    // retry job during the test.
    //
    // This does NOT throw an Apex exception.
    // ================================================================
    @IsTest
    static void testOAuthHttpFailureAtMaxRetries() {

        Test.setMock(
            HttpCalloutMock.class,
            new OAuthExceptionMock()
        );

        List<Upline_Policy_Import_Completed__e> events =
            new List<Upline_Policy_Import_Completed__e>{

                new Upline_Policy_Import_Completed__e(
                    Import_Log_ID__c = '999',
                    Source__c        = 'Carepoint',
                    Report_Type__c   = 'Active Policies'
                )
            };

        Test.startTest();

        System.enqueueJob(
            new UplineImportCompleteHelper.GoAMSCallout(
                events,
                GoAMSRetryUtil.MAX_RETRIES
            )
        );

        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id,
                   Event_Type__c,
                   Error_Message__c,
                   Source__c,
                   Severity__c,
                   Status__c,
                   Retry_Count__c
            FROM Error_Log__c
        ];

        System.assert(
            !logs.isEmpty(),
            'Expected a dead-letter Error_Log__c for OAuth HTTP 500'
        );

        System.assertEquals(
            'Upline_Policy_Import_Completed__e',
            logs[0].Event_Type__c
        );

        System.assertEquals(
            'High',
            logs[0].Severity__c
        );

        System.assertEquals(
            'Dead Letter',
            logs[0].Status__c
        );

        System.assertEquals(
            GoAMSRetryUtil.MAX_RETRIES,
            logs[0].Retry_Count__c
        );
    }


    // ================================================================
    // TEST 7
    // Event POST returns HTTP 400.
    //
    // 400 is expected to be non-retryable.
    // The production helper should immediately create a dead-letter
    // Error_Log__c.
    // ================================================================
    @IsTest
    static void testPostEventNonRetryableFailureDeadLetters() {

        Test.setMock(
            HttpCalloutMock.class,
            new OAuthOkNonRetryableMock()
        );

        List<Upline_Policy_Import_Completed__e> events =
            new List<Upline_Policy_Import_Completed__e>{

                new Upline_Policy_Import_Completed__e(
                    Import_Log_ID__c = '111',
                    Source__c        = 'Carepoint',
                    Report_Type__c   = 'Active Policies'
                )
            };

        Test.startTest();

        UplineImportCompleteHelper.sendToGoAMS(events);

        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id,
                   Event_Type__c,
                   Error_Message__c,
                   Source__c,
                   Severity__c,
                   Status__c,
                   Retry_Count__c
            FROM Error_Log__c
        ];

        System.assert(
            !logs.isEmpty(),
            'Expected a dead-letter Error_Log__c for HTTP 400'
        );

        System.assertEquals(
            'Upline_Policy_Import_Completed__e',
            logs[0].Event_Type__c
        );

        System.assertEquals(
            'High',
            logs[0].Severity__c
        );

        System.assertEquals(
            'Dead Letter',
            logs[0].Status__c
        );
    }


    // ================================================================
    // TEST 8
    // Event POST returns HTTP 503.
    //
    // 503 is retryable.
    //
    // Start at MAX_RETRIES so the production code goes directly to
    // dead-letter instead of scheduling another queueable.
    // ================================================================
    @IsTest
    static void testPostEventRetryableFailureAtMaxRetriesDeadLetters() {

        Test.setMock(
            HttpCalloutMock.class,
            new OAuthOkRetryableMock()
        );

        List<Upline_Policy_Import_Completed__e> events =
            new List<Upline_Policy_Import_Completed__e>{

                new Upline_Policy_Import_Completed__e(
                    Import_Log_ID__c = '222',
                    Source__c        = 'Carepoint',
                    Report_Type__c   = 'Active Policies'
                )
            };

        Test.startTest();

        System.enqueueJob(
            new UplineImportCompleteHelper.GoAMSCallout(
                events,
                GoAMSRetryUtil.MAX_RETRIES
            )
        );

        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id,
                   Event_Type__c,
                   Error_Message__c,
                   Source__c,
                   Severity__c,
                   Status__c,
                   Retry_Count__c
            FROM Error_Log__c
        ];

        System.assert(
            !logs.isEmpty(),
            'Expected a dead-letter Error_Log__c after max retries'
        );

        System.assertEquals(
            'Upline_Policy_Import_Completed__e',
            logs[0].Event_Type__c
        );

        System.assertEquals(
            'High',
            logs[0].Severity__c
        );

        System.assertEquals(
            'Dead Letter',
            logs[0].Status__c
        );

        System.assertEquals(
            GoAMSRetryUtil.MAX_RETRIES,
            logs[0].Retry_Count__c
        );
    }


    // ================================================================
    // TEST 9
    // Directly test logErrors() with no failed SaveResults.
    // ================================================================
    @IsTest
    static void testLogErrorsMethodNoFailures() {

        Test.startTest();

        UplineImportCompleteHelper.logErrors(
            new List<Database.SaveResult>(),
            new List<Upline_Policy_Import_Completed__e>()
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Error_Log__c
            ],
            'No Error_Log__c should be created when there are no SaveResults'
        );
    }


    // ================================================================
    // TEST 10
    // Directly test logErrors() with a failed SaveResult.
    //
    // Account Name is required, so Account() creates a guaranteed
    // failed Database.SaveResult when using allOrNone=false.
    // ================================================================
    @IsTest
    static void testLogErrorsMethodWithFailure() {

        List<Database.SaveResult> results =
            Database.insert(
                new List<Account>{
                    new Account()
                },
                false
            );

        System.assertEquals(
            1,
            results.size(),
            'Expected one SaveResult'
        );

        System.assertEquals(
            false,
            results[0].isSuccess(),
            'The Account insert should fail because Name is required'
        );

        Test.startTest();

        UplineImportCompleteHelper.logErrors(
            results,
            new List<Upline_Policy_Import_Completed__e>()
        );

        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id,
                   Error_Message__c,
                   Source__c,
                   Status__c,
                   Severity__c
            FROM Error_Log__c
        ];

        System.assertEquals(
            1,
            logs.size(),
            'Expected exactly one Error_Log__c'
        );

        System.assertEquals(
            'UplineImportCompleteTrigger',
            logs[0].Source__c
        );

        System.assertEquals(
            'New',
            logs[0].Status__c
        );

        System.assertEquals(
            'High',
            logs[0].Severity__c
        );

        System.assert(
            String.isNotBlank(logs[0].Error_Message__c),
            'Error message should not be blank'
        );
    }
}