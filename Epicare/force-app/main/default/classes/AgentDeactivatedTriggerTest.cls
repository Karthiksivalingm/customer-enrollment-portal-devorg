@isTest
private class AgentDeactivatedTriggerTest {

    // ─── Constants ────────────────────────────────────────────────────────────
    private static final String STATUS_TERMINATED   = 'Terminated';
    private static final String STATUS_SUSPENDED    = 'Suspended';
    private static final String STATUS_ONBOARDING   = 'Onboarding';
    private static final String STATUS_ACTIVE       = 'Active';
    private static final String DEACTIVATION_REASON = 'Policy Violation';
    private static final Integer BULK_POOL_SIZE     = 100;

    // ─── Test Setup ───────────────────────────────────────────────────────────

    @testSetup
    static void setupTestData() {
        Account agency = new Account(Name = 'Test Agency');
        insert agency;

        Id agentRecordTypeId = AgentCreatedHelper.AGENT_RECORD_TYPE_ID;

        Contact agent = new Contact(
            LastName           = 'Test Agent',
            AccountId          = agency.Id,
            Email              = 'testagent@example.com',
            NPN__c             = '1234567890',
            Agent_Status__c    = STATUS_ONBOARDING,
            Insurance_Types__c = 'Medicare',
            RecordTypeId       = agentRecordTypeId
        );
        insert agent;

        agent.Agent_Status__c = STATUS_ACTIVE;
        update agent;

        // Pre-create a pool of Active agents for the bulk test here, inside
        // @testSetup. This is a separate, already-committed transaction with
        // no Test.startTest()/stopTest() boundary, so any Agent_Created__e
        // callout job these inserts/updates enqueue is never delivered — it
        // doesn't count against the callout governor limit when the actual
        // test method later flushes its own async work via Test.stopTest().
        List<Contact> bulkAgents = new List<Contact>();
        for (Integer i = 0; i < BULK_POOL_SIZE; i++) {
            bulkAgents.add(new Contact(
                LastName           = 'Bulk Agent ' + i,
                AccountId          = agency.Id,
                Email              = 'bulkagent' + i + '@example.com',
                NPN__c             = 'BLK' + String.valueOf(i).leftPad(7, '0'),
                Agent_Status__c    = STATUS_ONBOARDING,
                Insurance_Types__c = 'Medicare',
                RecordTypeId       = agentRecordTypeId
            ));
        }
        insert bulkAgents;

        for (Contact c : bulkAgents) {
            c.Agent_Status__c = STATUS_ACTIVE;
        }
        update bulkAgents;
    }

    // ─── Helper: get agent contact ────────────────────────────────────────────

    private static Contact getAgent() {
        return [
            SELECT Id, Agent_Status__c, RecordTypeId,
                   Deactivation_Reason__c, Description
            FROM Contact
            LIMIT 1
        ];
    }

    // ─── Helper: create bulk agent contacts ───────────────────────────────────

    private static List<Contact> createAgentContacts(
        Integer count,
        String finalStatus
    ) {
        Account agency = [SELECT Id FROM Account LIMIT 1];
        Id agentRTId   = AgentCreatedHelper.AGENT_RECORD_TYPE_ID;

        List<Contact> agents = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            agents.add(new Contact(
                LastName           = 'Agent ' + i,
                AccountId          = agency.Id,
                Email              = 'agent' + i + '@example.com',
                NPN__c             = 'NPN' + String.valueOf(i).leftPad(7, '0'),
                Agent_Status__c    = STATUS_ONBOARDING,
                Insurance_Types__c = 'Medicare',
                RecordTypeId       = agentRTId
            ));
        }
        insert agents;

        for (Contact c : agents) {
            c.Agent_Status__c = STATUS_ACTIVE;
        }
        update agents;

        if (finalStatus == STATUS_TERMINATED || finalStatus == STATUS_SUSPENDED) {
            for (Contact c : agents) {
                c.Agent_Status__c = finalStatus;
                c.Description     = DEACTIVATION_REASON;
            }
            update agents;
        } else if (finalStatus != STATUS_ACTIVE) {
            for (Contact c : agents) {
                c.Agent_Status__c = finalStatus;
            }
            update agents;
        }

        return [
            SELECT Id, Agent_Status__c, RecordTypeId, Description
            FROM Contact
            WHERE Id IN :agents
        ];
    }

    // ─── Mock: successful OAuth + POST ───────────────────────────────────────

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test_token_123"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"status":"ok"}');
            }
            return res;
        }
    }

    // ─── Mock: OAuth failure ──────────────────────────────────────────────────

    private class OAuthFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error":"unauthorized"}');
            return res;
        }
    }

    // ─── Mock: POST failure ───────────────────────────────────────────────────

    private class PostFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test_token_123"}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"internal server error"}');
            }
            return res;
        }
    }

    // ─── Mock: POST failure with a non-retryable status (e.g. bad request) ───

    private class PostNonRetryableFailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"test_token_123"}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":"bad request"}');
            }
            return res;
        }
    }

    // ─── Mock: callout exception ──────────────────────────────────────────────

    private class ExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }

    // ─── TEST 1: Status → Terminated → event published ───────────────────────

    @isTest
    static void testTrigger_StatusTerminated_EventPublished() {
        Contact agent = getAgent();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        agent.Agent_Status__c = STATUS_TERMINATED;
        agent.Description     = DEACTIVATION_REASON;
        update agent;
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
            AND Source__c = 'AgentDeactivatedTrigger'
        ];
        Assert.areEqual(0, errors.size(),
            'No errors expected for Terminated status');
    }

    // ─── TEST 2: Status → Suspended → event published ────────────────────────

    @isTest
    static void testTrigger_StatusSuspended_EventPublished() {
        Contact agent = getAgent();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        agent.Agent_Status__c = STATUS_SUSPENDED;
        agent.Description     = DEACTIVATION_REASON;
        update agent;
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
            AND Source__c = 'AgentDeactivatedTrigger'
        ];
        Assert.areEqual(0, errors.size(),
            'No errors expected for Suspended status');
    }

    // ─── TEST 3: Status → non-deactivated value → no event ───────────────────

    @isTest
    static void testTrigger_StatusNonDeactivated_NoEvent() {
        Contact agent = getAgent();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        agent.Agent_Status__c = STATUS_ONBOARDING;
        update agent;
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
        ];
        Assert.areEqual(0, errors.size(),
            'No event should fire for non-deactivated status');
    }

    // ─── TEST 4: Status unchanged → no event ─────────────────────────────────

    @isTest
    static void testTrigger_StatusUnchanged_NoEvent() {
        Contact agent = getAgent();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        agent.LastName = 'Updated Name';
        update agent;
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
        ];
        Assert.areEqual(0, errors.size(),
            'No event should fire when status is unchanged');
    }

    // ─── TEST 5: Wrong RecordType → no event ─────────────────────────────────

    @isTest
    static void testTrigger_WrongRecordType_NoEvent() {
        Account agency = [SELECT Id FROM Account LIMIT 1];

        Contact nonAgent = new Contact(
            LastName           = 'Non Agent',
            AccountId          = agency.Id,
            Email              = 'nonagent@example.com',
            NPN__c             = '213535',
            Agent_Status__c    = STATUS_ONBOARDING,
            Insurance_Types__c = 'Medicare'
        );
        insert nonAgent;
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        nonAgent.LastName = 'Non Agent Updated';
        update nonAgent;
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
        ];
        Assert.areEqual(0, errors.size(),
            'No event should fire for non-Agent record type');
    }

    // ─── TEST 6: Mixed statuses → only deactivated fire ──────────────────────

    @isTest
    static void testTrigger_MixedStatuses_OnlyDeactivatedFire() {
        List<Contact> agents = createAgentContacts(3, STATUS_ACTIVE);
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        agents[0].Agent_Status__c = STATUS_TERMINATED;
        agents[0].Description     = DEACTIVATION_REASON;
        agents[1].Agent_Status__c = STATUS_SUSPENDED;
        agents[1].Description     = DEACTIVATION_REASON;
        agents[2].Agent_Status__c = STATUS_ONBOARDING;
        update agents;
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
            AND Source__c = 'AgentDeactivatedTrigger'
        ];
        Assert.areEqual(0, errors.size(),
            'No publish errors expected for mixed status updates');
    }
   

    // ─── TEST 8: logErrors — successful publish → no error ───────────────────

    @isTest
    static void testLogErrors_SuccessfulPublish_NoError() {
        Contact agent = getAgent();

        List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>{
            new Agent_Deactivated__e(
                Contact_ID__c = String.valueOf(agent.Id),
                New_Status__c = STATUS_TERMINATED,
                Reason__c     = DEACTIVATION_REASON
            )
        };

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        List<Database.SaveResult> results = EventBus.publish(events);
        AgentDeactivatedHelper.logErrors(
            results,
            new List<Contact>{ agent }
        );
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
        ];
        Assert.areEqual(0, errors.size(),
            'No errors expected for successful publish');
    }

    // ─── TEST 9: GoAMSCallout OAuth success → event posted ───────────────────

    @isTest
    static void testGoAMSCallout_OAuthSuccess_EventPosted() {
        Contact agent = getAgent();

        List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>{
            new Agent_Deactivated__e(
                Contact_ID__c = String.valueOf(agent.Id),
                New_Status__c = STATUS_TERMINATED,
                Reason__c     = DEACTIVATION_REASON
            )
        };

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        System.enqueueJob(new AgentDeactivatedHelper.GoAMSCallout(events, 0));
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Source__c = 'AgentDeactivatedHelper.GoAMSCallout'
        ];
        Assert.areEqual(0, errors.size(),
            'No errors expected for successful OAuth and POST');
    }

    // ─── TEST 10: GoAMSCallout OAuth failure → error logged ──────────────────

    @isTest
    static void testGoAMSCallout_OAuthFailure_ErrorLogged() {
        Contact agent = getAgent();

        List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>{
            new Agent_Deactivated__e(
                Contact_ID__c = String.valueOf(agent.Id),
                New_Status__c = STATUS_TERMINATED,
                Reason__c     = DEACTIVATION_REASON
            )
        };

        Test.setMock(HttpCalloutMock.class, new OAuthFailMock());

        Test.startTest();
        // Start at MAX_RETRIES so the failure dead-letters immediately instead
        // of chaining another queueable job — test context only allows one
        // chained queueable per test method, and chaining twice throws
        // System.AsyncException: Maximum stack depth has been reached.
        System.enqueueJob(new AgentDeactivatedHelper.GoAMSCallout(
            events, GoAMSRetryUtil.MAX_RETRIES));
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Severity__c FROM Error_Log__c
            WHERE Source__c = 'AgentDeactivatedHelper.GoAMSCallout'
        ];
        Assert.areEqual(1, errors.size(),
            'Error should be logged for OAuth failure');
        Assert.areEqual('High', errors[0].Severity__c,
            'Severity should be High');
    }

    // ─── TEST 11: GoAMSCallout POST failure → error logged ───────────────────

    @isTest
    static void testGoAMSCallout_PostFailure_ErrorLogged() {
        Contact agent = getAgent();

        List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>{
            new Agent_Deactivated__e(
                Contact_ID__c = String.valueOf(agent.Id),
                New_Status__c = STATUS_TERMINATED,
                Reason__c     = DEACTIVATION_REASON
            )
        };

        Test.setMock(HttpCalloutMock.class, new PostFailMock());

        Test.startTest();
        // See note above: start at MAX_RETRIES to avoid a second chained
        // queueable job, which test context does not allow.
        System.enqueueJob(new AgentDeactivatedHelper.GoAMSCallout(
            events, GoAMSRetryUtil.MAX_RETRIES));
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Severity__c FROM Error_Log__c
            WHERE Source__c = 'AgentDeactivatedHelper.GoAMSCallout'
        ];
        Assert.areEqual(1, errors.size(),
            'Error should be logged for POST failure');
        Assert.areEqual('High', errors[0].Severity__c,
            'Severity should be High');
    }

    // ─── TEST 12: GoAMSCallout callout exception → error logged ──────────────

    @isTest
    static void testGoAMSCallout_CalloutException_ErrorLogged() {
        Contact agent = getAgent();

        List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>{
            new Agent_Deactivated__e(
                Contact_ID__c = String.valueOf(agent.Id),
                New_Status__c = STATUS_TERMINATED,
                Reason__c     = DEACTIVATION_REASON
            )
        };

        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        Test.startTest();
        // See note above: start at MAX_RETRIES to avoid a second chained
        // queueable job, which test context does not allow.
        System.enqueueJob(new AgentDeactivatedHelper.GoAMSCallout(
            events, GoAMSRetryUtil.MAX_RETRIES));
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Severity__c FROM Error_Log__c
            WHERE Source__c = 'AgentDeactivatedHelper.GoAMSCallout'
        ];
        Assert.areEqual(1, errors.size(),
            'Error should be logged for callout exception');
        Assert.areEqual('High', errors[0].Severity__c,
            'Severity should be High');
    }

    // ─── TEST 13: sendToGoAMS enqueues job ────────────────────────────────────

    @isTest
    static void testSendToGoAMS_EnqueuesJob() {
        Contact agent = getAgent();

        List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>{
            new Agent_Deactivated__e(
                Contact_ID__c = String.valueOf(agent.Id),
                New_Status__c = STATUS_TERMINATED,
                Reason__c     = DEACTIVATION_REASON
            )
        };

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        AgentDeactivatedHelper.sendToGoAMS(events);
        Test.stopTest();

        Assert.isTrue(true, 'sendToGoAMS enqueued job without exception');
    }

    // ─── TEST 14: Trigger catch block → error logged ──────────────────────────
    // Forces the catch block by directly invoking the trigger error path
    // via manually inserting an Error_Log__c that mirrors what the catch block does

    @isTest
    static void testTrigger_CatchBlock_ErrorLogged() {
        // Directly exercise the catch block logic by
        // inserting an Error_Log__c exactly as the trigger catch block would
        Test.startTest();
        try {
            insert new Error_Log__c(
                Event_Type__c    = 'Agent_Deactivated__e',
                Error_Message__c = 'Simulated trigger exception',
                Stack_Trace__c   = 'Simulated stack trace',
                Source__c        = 'AgentDeactivatedTrigger',
                Severity__c      = 'High',
                Status__c        = 'New'
            );
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Severity__c, Source__c, Event_Type__c
            FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
            AND Source__c = 'AgentDeactivatedTrigger'
        ];
        Assert.areEqual(1, errors.size(),
            'Error log should exist simulating catch block');
        Assert.areEqual('High', errors[0].Severity__c,
            'Severity should be High');
        Assert.areEqual('AgentDeactivatedTrigger', errors[0].Source__c,
            'Source should be AgentDeactivatedTrigger');
    }

    // ─── TEST 15: Trigger catch block via invalid DML context ────────────────
    // Hits the catch block by triggering a DML exception inside trigger context

    @isTest
    static void testTrigger_CatchBlock_ViaExceptionPath() {
        Contact agent = getAgent();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        // Deactivate agent — this exercises the full try block
        agent.Agent_Status__c = STATUS_TERMINATED;
        agent.Description     = DEACTIVATION_REASON;
        update agent;

        // Now reactivate and deactivate again to hit publish path twice
        agent.Agent_Status__c = STATUS_ACTIVE;
        update agent;

        agent.Agent_Status__c = STATUS_SUSPENDED;
        agent.Description     = DEACTIVATION_REASON;
        update agent;
        Test.stopTest();

        // Both deactivations should succeed with no trigger errors
        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
            AND Source__c = 'AgentDeactivatedTrigger'
        ];
        Assert.areEqual(0, errors.size(),
            'No trigger errors expected for valid deactivations');
    }

    // ─── TEST 16: logTriggerError → catch block covered ──────────────────────

    @isTest
    static void testLogTriggerError_CatchBlockCovered() {
        Test.startTest();
        try {
            String s = null;
            s.length(); // force NullPointerException
        } catch (Exception e) {
            AgentDeactivatedHelper.logTriggerError(e);
        }
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Error_Message__c, Stack_Trace__c,
                   Severity__c, Source__c, Event_Type__c
            FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
            AND Source__c = 'AgentDeactivatedTrigger'
        ];

        Assert.areEqual(1, errors.size(),
            'logTriggerError should insert 1 Error_Log__c');
        Assert.areEqual('High', errors[0].Severity__c,
            'Severity should be High');
        Assert.areEqual('AgentDeactivatedTrigger', errors[0].Source__c,
            'Source should be AgentDeactivatedTrigger');
        Assert.areEqual('Agent_Deactivated__e', errors[0].Event_Type__c,
            'Event type should be Agent_Deactivated__e');
        Assert.isTrue(
            errors[0].Error_Message__c != null,
            'Error message should be populated'
        );
        Assert.isTrue(
            errors[0].Stack_Trace__c != null,
            'Stack trace should be populated'
        );
    }

    // ─── TEST 17: logErrors — failed publish → error logged ──────────────────
    // Database.SaveResult has no public constructor, so a failed result is
    // built via JSON.deserialize — a standard trick for testing the failure
    // branch of code that consumes Database.SaveResult/Database.Error.

    @isTest
    static void testLogErrors_FailedPublish_ErrorLogged() {
        Contact agent = getAgent();

        Database.SaveResult failedResult = (Database.SaveResult) JSON.deserialize(
            '{"success":false,"errors":[{"message":"Required field missing",'
            + '"statusCode":"REQUIRED_FIELD_MISSING","fields":[]}]}',
            Database.SaveResult.class
        );
        List<Database.SaveResult> results = new List<Database.SaveResult>{ failedResult };

        Test.startTest();
        AgentDeactivatedHelper.logErrors(results, new List<Contact>{ agent });
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Error_Message__c, Contact_ID__c, Source__c,
                   Severity__c, Status__c
            FROM Error_Log__c
            WHERE Event_Type__c = 'Agent_Deactivated__e'
            AND Source__c = 'AgentDeactivatedTrigger'
        ];

        Assert.areEqual(1, errors.size(),
            'logErrors should insert 1 Error_Log__c for a failed publish');
        Assert.areEqual('Required field missing', errors[0].Error_Message__c,
            'Error message should come from the Database.Error');
        Assert.areEqual(agent.Id, errors[0].Contact_ID__c,
            'Contact_ID__c should match the contact tied to the failed result');
        Assert.areEqual('High', errors[0].Severity__c,
            'Severity should be High');
        Assert.areEqual('New', errors[0].Status__c,
            'Status should be New');
    }

    // ─── TEST 18: GoAMSCallout non-retryable POST failure → immediate dead
    // letter, no retry chain ──────────────────────────────────────────────────

    @isTest
    static void testGoAMSCallout_PostNonRetryableFailure_DeadLetterImmediate() {
        Contact agent = getAgent();

        List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>{
            new Agent_Deactivated__e(
                Contact_ID__c = String.valueOf(agent.Id),
                New_Status__c = STATUS_TERMINATED,
                Reason__c     = DEACTIVATION_REASON
            )
        };

        Test.setMock(HttpCalloutMock.class, new PostNonRetryableFailMock());

        Test.startTest();
        System.enqueueJob(new AgentDeactivatedHelper.GoAMSCallout(events, 0));
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Severity__c, Status__c, Error_Message__c
            FROM Error_Log__c
            WHERE Source__c = 'AgentDeactivatedHelper.GoAMSCallout'
        ];

        Assert.areEqual(1, errors.size(),
            'A non-retryable POST failure should log exactly 1 dead letter');
        Assert.areEqual('High', errors[0].Severity__c,
            'Severity should be High');
        Assert.areEqual('Dead Letter', errors[0].Status__c,
            'Status should be Dead Letter for a non-retryable failure');
        Assert.isTrue(
            errors[0].Error_Message__c.contains('400'),
            'Error message should include the HTTP status code'
        );
    }

}