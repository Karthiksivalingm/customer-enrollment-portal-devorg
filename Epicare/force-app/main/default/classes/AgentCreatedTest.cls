@isTest
private class AgentCreatedTest {

    // ─────────────────────────────────────────────
    // Record Type helpers — dynamic lookup, never hardcode IDs
    // ─────────────────────────────────────────────
    private static Id getAccountRecordTypeId(String devName) {
        return Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get(devName).getRecordTypeId();
    }
    private static Id getContactRecordTypeId(String devName) {
        return Schema.SObjectType.Contact
            .getRecordTypeInfosByDeveloperName().get(devName).getRecordTypeId();
    }

    // ─────────────────────────────────────────────
    // Callout mocks
    // ─────────────────────────────────────────────
    private class OAuthSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test-token"}');
            } else {
                res.setStatusCode(200);
                res.setBody('OK');
            }
            return res;
        }
    }
    private class OAuthFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('Unauthorized');
            return res;
        }
    }
    private class GoAMSRetryableFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test-token"}');
            } else {
                res.setStatusCode(500); // assumed retryable
            }
            return res;
        }
    }
    private class GoAMSNonRetryableFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test-token"}');
            } else {
                res.setStatusCode(400); // assumed NOT retryable
                res.setBody('Bad Request');
            }
            return res;
        }
    }
    private class OAuthExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated OAuth callout failure');
        }
    }
    private class PostEventExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            if (req.getEndpoint().contains('oauth')) {
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody('{"access_token":"test-token"}');
                return res;
            }
            throw new CalloutException('Simulated postEvent callout failure');
        }
    }

    // ═════════════════════════════════════════════
    // TRIGGER TESTS
    // A real Agent-record-type insert fires the whole live chain:
    // trigger → platform event → subscriber → sendToGoAMS → queueable.
    // Every such test needs a SUCCESS mock, or the OAuth callout fails,
    // retries, and blows past the test-context chaining limit.
    // ═════════════════════════════════════════════

    @isTest
    static void testTrigger_agentRecordType_publishesEvent() {
        Id agencyRTId = getAccountRecordTypeId('Epicare_Corp');
        Id agentRTId  = getContactRecordTypeId('Agent');

        Account a = new Account(Name = 'Test Agency', RecordTypeId = agencyRTId);
        insert a;

        Test.setMock(HttpCalloutMock.class, new OAuthSuccessMock());

        Test.startTest();
            Contact c = new Contact(
                FirstName = 'Test', LastName = 'Agent', Email = 'trigger.agent@test.com',
                NPN__c = '9998887', AccountId = a.Id, RecordTypeId = agentRTId,
                Agent_Status__c = 'onboarding'
            );
            insert c;
        Test.stopTest();

        System.assert(c.Id != null, 'Contact should have been inserted');
    }

    @isTest
    static void testTrigger_nonAgentRecordType_noEventPublished() {
        Id agencyRTId = getAccountRecordTypeId('Epicare_Corp');
        Id otherRTId  = getContactRecordTypeId('Agency_Director');

        Account a = new Account(Name = 'Test Agency 2', RecordTypeId = agencyRTId);
        insert a;

        Test.startTest();
            Contact c = new Contact(
                FirstName = 'Non', LastName = 'Agent', Email = 'trigger.nonagent@test.com',
                NPN__c = '5556667', AccountId = a.Id, RecordTypeId = otherRTId
            );
            insert c;
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id FROM Error_Log__c WHERE Source__c = 'AgentCreatedTrigger'
        ];
        System.assertEquals(0, logs.size(), 'No error log expected when record type does not match');
    }

    @isTest
    static void testTrigger_publishException_logsError() {
        Id agencyRTId = getAccountRecordTypeId('Epicare_Corp');
        Id agentRTId  = getContactRecordTypeId('Agent');

        Account a = new Account(Name = 'Test Agency 3', RecordTypeId = agencyRTId);
        insert a;

        Test.setMock(HttpCalloutMock.class, new OAuthSuccessMock());

        AgentCreatedHelper.throwPublishException = true;
        try {
            Test.startTest();
                Contact c = new Contact(
                    FirstName = 'Exception', LastName = 'Agent', Email = 'trigger.exception@test.com',
                    NPN__c = '1112223', AccountId = a.Id, RecordTypeId = agentRTId,
                    Agent_Status__c = 'onboarding'
                );
                insert c;
            Test.stopTest();
        } finally {
            AgentCreatedHelper.throwPublishException = false;
        }

        List<Error_Log__c> logs = [
            SELECT Id, Source__c, Error_Message__c FROM Error_Log__c
            WHERE Source__c = 'AgentCreatedTrigger'
        ];
        System.assertEquals(1, logs.size(), 'Expected one error log from forced exception');
    }

    // ═════════════════════════════════════════════
    // logErrors()
    // ═════════════════════════════════════════════

    @isTest
    static void testLogErrors_noErrors_nothingInserted() {
        Id agencyRTId = getAccountRecordTypeId('Epicare_Corp');
        Id agentRTId  = getContactRecordTypeId('Agent');

        Account a = new Account(Name = 'Test Agency', RecordTypeId = agencyRTId);
        insert a;

        Test.setMock(HttpCalloutMock.class, new OAuthSuccessMock());

        Contact c = new Contact(
            FirstName = 'Valid', LastName = 'Agent', Email = 'valid@test.com',
            NPN__c = '1234567', AccountId = a.Id, RecordTypeId = agentRTId,
            Agent_Status__c = 'onboarding'
        );
        List<Database.SaveResult> results = Database.insert(new List<Contact>{ c }, false);

        Test.startTest();
            AgentCreatedHelper.logErrors(results, new List<Contact>{ c });
        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, logs.size(), 'No error logs should be inserted on success');
    }

    @isTest
    static void testLogErrors_withErrors_insertsErrorLog() {
        Id agencyRTId = getAccountRecordTypeId('Epicare_Corp');
        Id agentRTId  = getContactRecordTypeId('Agent');

        Account a = new Account(Name = 'Test Agency', RecordTypeId = agencyRTId);
        insert a;

        Contact badContact = new Contact(
            FirstName = 'Missing', LastName = 'NPN', Email = 'badnpn@test.com',
            AccountId = a.Id, RecordTypeId = agentRTId
        );
        List<Database.SaveResult> results = Database.insert(new List<Contact>{ badContact }, false);
        System.assert(!results[0].isSuccess(), 'Expected this insert to fail validation');

        Integer expectedErrorCount = results[0].getErrors().size();

        Test.startTest();
            AgentCreatedHelper.logErrors(results, new List<Contact>{ badContact });
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Source__c FROM Error_Log__c WHERE Source__c = 'AgentCreatedTrigger'
        ];
        System.assertEquals(
            expectedErrorCount, logs.size(),
            'Expected one error log per Database.Error returned for the failed save result'
        );
    }

    // ═════════════════════════════════════════════
    // sendToGoAMS() / GoAMSCallout — success + oauth
    // ═════════════════════════════════════════════

    @isTest
    static void testSendToGoAMS_successPath_noErrorLogs() {
        Test.setMock(HttpCalloutMock.class, new OAuthSuccessMock());

        List<Agent_Created__e> events = new List<Agent_Created__e>{
            new Agent_Created__e(Contact_ID__c = 'FAKE001')
        };

        Test.startTest();
            AgentCreatedHelper.sendToGoAMS(events);
        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, logs.size(), 'No error logs on success path');
    }

    

    @isTest
    static void testGoAMSCallout_oauthFails_atMaxRetries_deadLetters() {
        Test.setMock(HttpCalloutMock.class, new OAuthFailMock());

        AgentCreatedHelper.GoAMSCallout job = new AgentCreatedHelper.GoAMSCallout(
            new List<Agent_Created__e>{ new Agent_Created__e(Contact_ID__c = 'FAKE001') },
            GoAMSRetryUtil.MAX_RETRIES
        );

        Test.startTest();
            System.enqueueJob(job);
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Error_Message__c, Status__c, Source__c FROM Error_Log__c
        ];
        System.assertEquals(1, logs.size(), 'Max retries exceeded should dead-letter');
        System.assertEquals('Dead Letter', logs[0].Status__c);
        System.assert(
            logs[0].Error_Message__c.contains('OAuth token request failed'),
            'Should carry the OAuth failure reason'
        );
    }

    @isTest
    static void testGoAMSCallout_oauthException_atMaxRetries_deadLetters() {
        Test.setMock(HttpCalloutMock.class, new OAuthExceptionMock());

        AgentCreatedHelper.GoAMSCallout job = new AgentCreatedHelper.GoAMSCallout(
            new List<Agent_Created__e>{ new Agent_Created__e(Contact_ID__c = 'FAKE001') },
            GoAMSRetryUtil.MAX_RETRIES
        );

        Test.startTest();
            System.enqueueJob(job);
        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Error_Message__c, Source__c FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'Thrown OAuth exception should still dead-letter at max retries');
        System.assertEquals('AgentCreatedHelper.GoAMSCallout', logs[0].Source__c);
    }

    // ═════════════════════════════════════════════
    // GoAMSCallout — postEvent branches
    // ═════════════════════════════════════════════

    @isTest
    static void testGoAMSCallout_postEventRetryableFailure_atMaxRetries_deadLetters() {
        Test.setMock(HttpCalloutMock.class, new GoAMSRetryableFailMock());

        AgentCreatedHelper.GoAMSCallout job = new AgentCreatedHelper.GoAMSCallout(
            new List<Agent_Created__e>{ new Agent_Created__e(Contact_ID__c = 'FAKE001') },
            GoAMSRetryUtil.MAX_RETRIES
        );

        Test.startTest();
            System.enqueueJob(job);
        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Error_Message__c, Status__c FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'Retryable failure exhausted at max retries should dead-letter');
        System.assertEquals('Dead Letter', logs[0].Status__c);
    }

    @isTest
    static void testGoAMSCallout_postEventNonRetryableFailure_deadLettersImmediately() {
        Test.setMock(HttpCalloutMock.class, new GoAMSNonRetryableFailMock());

        AgentCreatedHelper.GoAMSCallout job = new AgentCreatedHelper.GoAMSCallout(
            new List<Agent_Created__e>{ new Agent_Created__e(Contact_ID__c = 'FAKE001') },
            0
        );

        Test.startTest();
            System.enqueueJob(job);
        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Error_Message__c FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'Non-retryable status should dead-letter without retrying');
        System.assert(logs[0].Error_Message__c.contains('400'), 'Should include the HTTP status');
    }

    @isTest
    static void testGoAMSCallout_postEventException_atMaxRetries_deadLetters() {
        Test.setMock(HttpCalloutMock.class, new PostEventExceptionMock());

        AgentCreatedHelper.GoAMSCallout job = new AgentCreatedHelper.GoAMSCallout(
            new List<Agent_Created__e>{ new Agent_Created__e(Contact_ID__c = 'FAKE001') },
            GoAMSRetryUtil.MAX_RETRIES
        );

        Test.startTest();
            System.enqueueJob(job);
        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Error_Message__c, Source__c FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'postEvent exception exhausted at max retries should dead-letter');
        System.assertEquals('AgentCreatedHelper.GoAMSCallout', logs[0].Source__c);
    }
}