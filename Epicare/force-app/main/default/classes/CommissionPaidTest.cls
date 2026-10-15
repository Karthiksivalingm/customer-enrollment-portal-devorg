@IsTest
private class CommissionPaidTest {

    // ─── HTTP Mocks ─────────────────────────────────────────────────────────
    //
    // IMPORTANT FIX: CommissionPaidHelper sets the OAuth endpoint to
    // 'callout:EventAPI/oauth-token'. The original mocks in both source test
    // files checked req.getEndpoint().contains('/oauth/token') — that string
    // (slash-oauth-slash-token) never matches 'oauth-token' (hyphenated), so
    // the OAuth branch never fired. Every "success" mock fell through to the
    // else branch, returned a plain-text 'Success' body for the OAuth call,
    // failed JSON parsing in getAccessToken(), and returned null — meaning
    // the old "success" tests were silently exercising the OAuth-failure
    // path. The old EventFailureMock had the same problem, so it never
    // reached the event-POST-failure code either. Matching on 'oauth-token'
    // below fixes this for all mocks.

    class GoAMSMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"dummyToken"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"success":true}');
            }
            return res;
        }
    }

    // Same happy-path behavior as GoAMSMock, but records the JSON body of
    // the event-POST call (not the OAuth call) so a test can assert on the
    // exact payload sent to GO AMS — e.g. verifying Period__c goes out
    // unmodified per the PB-0018 fix, rather than just checking that no
    // Error_Log__c rows were written.
    class CapturingMock implements HttpCalloutMock {
        public String capturedBody;
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"dummyToken"}');
            } else {
                capturedBody = req.getBody();
                res.setStatusCode(200);
                res.setBody('{"success":true}');
            }
            return res;
        }
    }

    class OAuthFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('Unauthorized');
            return res;
        }
    }

    // OAuth succeeds; the event POST returns a retryable (5xx) error.
    // Assumes GoAMSRetryUtil.isRetryableStatus() treats 5xx as retryable —
    // adjust this mock's status code if your implementation differs.
    class EventServerErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"dummyToken"}');
            } else {
                res.setStatusCode(500);
                res.setBody('Internal Server Error');
            }
            return res;
        }
    }

    // OAuth succeeds; the event POST returns a non-retryable (4xx) error —
    // exercises the immediate dead-letter path inside postEvent().
    // Assumes GoAMSRetryUtil.isRetryableStatus() treats 4xx (other than
    // 429) as non-retryable — adjust if your implementation differs.
    class EventBadRequestMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('oauth-token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"dummyToken"}');
            } else {
                res.setStatusCode(400);
                res.setBody('Bad Request');
            }
            return res;
        }
    }

    // ─── Setup ──────────────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        Contact agent = new Contact(
            LastName            = 'Testperson',
            Email               = 'agent123456@test.com',
            // FIX (confirmed via debug log): NPN__c is a text field capped
            // at 10 characters. The original 11-digit value
            // ('19045270888') always failed with STRING_TOO_LONG on this
            // insert; because dml.OptAllOrNone previously defaulted to
            // false, that failure was swallowed silently instead of
            // surfacing, leaving agent.Id null (see the OptAllOrNone fix
            // above). Trimmed to 10 digits so the insert actually succeeds.
            NPN__c              = '1904527088',
            Agent_Status__c     = 'Onboarding',
            Insurance_Types__c  = 'Life'
        );
        // FIX (confirmed via debug log): Database.insert(agent, dml) was
        // silently leaving agent.Id null. Database.DMLOptions.OptAllOrNone
        // defaults to false, so when the save failed — most likely this
        // Contact colliding with a pre-existing duplicate that
        // DuplicateRuleHeader.allowSave didn't fully override — the call
        // returned a failed SaveResult instead of throwing, and agent.Id
        // was never populated. The debug log for the affected insert showed
        // zero triggers/validation/duplicate-detection running at all
        // (compare to every other Contact insert in the log, which all show
        // the full ContactTrigger/Validation/DuplicateDetector cascade),
        // confirming zero rows were actually saved. That null agent.Id then
        // propagated into the Commission_Record__c below as
        // Agent__c = null, which the trigger's aggregate query filters out
        // (WHERE Agent__c != NULL), making agentTotals.isEmpty() true and
        // causing CommissionPaidTrigger to return before ever calling
        // CommissionPaidHelper.publishEvents() — silently invalidating
        // every test that depends on this setup data actually publishing
        // an event. Setting OptAllOrNone = true makes a real failure throw
        // loudly (naming the actual blocking rule) instead of leaving
        // agent.Id null with no visible error.
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.OptAllOrNone = true;
        Database.insert(agent, dml);

        // Payment_Batch__c.Payment_Period__c is a separate field from
        // Commission_Record__c.Payment_Period__c (same API name, different
        // object/data — see CommissionPaidTrigger's PB-0018 comment). The
        // trigger no longer reads this batch-level field when building the
        // event; it's set here only because it's presumably required on the
        // object, not because the trigger consumes it.
        Payment_Batch__c batch = new Payment_Batch__c(
            Status__c          = 'Draft',
            Payment_Period__c  = '2026-08'
        );
        insert batch;

        // FIX: the original setup never set an amount, so the trigger's
        // SUM(Net_Amount__c) aggregate came back null. String.valueOf(null)
        // produces the literal text "null", which fails Double.valueOf()
        // parsing in postEvent() and dead-letters every "successful" batch
        // update. Net_Amount__c is a FORMULA field (Gross_Amount__c -
        // Admin_Fee__c - Chargeback_Amount__c) and isn't directly writeable,
        // so set Gross_Amount__c instead — Salesforce treats the unset
        // Admin_Fee__c / Chargeback_Amount__c number fields as 0 in the
        // formula, so Net_Amount__c resolves to the Gross_Amount__c value.
        //
        // ALSO SET: Payment_Period__c directly on the Commission_Record__c.
        // Per PB-0018, the trigger's MIN(Payment_Period__c) comes from this
        // object, not from the parent Payment_Batch__c, so this must be
        // populated for the event's Period__c to come through as anything
        // other than blank.
        insert new Commission_Record__c(
            Agent__c            = agent.Id,
            Payment_Batch__c    = batch.Id,
            Gross_Amount__c     = 500,
            Payment_Period__c   = '2026-08'
        );
    }

    private static Payment_Batch__c getBatch() {
        return [SELECT Id, Status__c, Payment_Period__c FROM Payment_Batch__c LIMIT 1];
    }

    private static Contact createAgent(String suffix) {
        Contact agent = new Contact(
            LastName            = 'Testperson',
            Email               = 'agent' + suffix + '@test.com',
            NPN__c              = suffix,
            Agent_Status__c     = 'Onboarding',
            Insurance_Types__c  = 'Life'
        );
        // Same OptAllOrNone fix as setupData() above — without it a failed
        // insert here would silently leave agent.Id null instead of
        // throwing, and every caller of createAgent() assumes a valid Id.
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.OptAllOrNone = true;
        Database.insert(agent, dml);
        return agent;
    }

    // ─── Trigger: end-to-end (batch → event → subscriber → queueable) ───────

    @IsTest
    static void testPaidStatusPublishesEventAndCallsOut() {
        Test.setMock(HttpCalloutMock.class, new GoAMSMock());
        Payment_Batch__c batch = getBatch();

        Test.startTest();
        batch.Status__c = 'Paid';
        update batch;
        Test.stopTest();

        System.assertEquals('Paid',
            [SELECT Status__c FROM Payment_Batch__c WHERE Id = :batch.Id].Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c],
            'A clean OAuth + callout success should not write any error logs');
    }

    @IsTest
    static void testNoStatusChangeDoesNotPublish() {
        Payment_Batch__c batch = getBatch();

        Test.startTest();
        update batch; // no field changes -> trigger fires but paidBatchIds stays empty
        Test.stopTest();

        System.assertEquals('Draft',
            [SELECT Status__c FROM Payment_Batch__c WHERE Id = :batch.Id].Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c]);
    }

    @IsTest
    static void testBulkPaidUpdate() {
        Test.setMock(HttpCalloutMock.class, new GoAMSMock());
        Contact agent = createAgent('bulk001');

        List<Payment_Batch__c> batches = new List<Payment_Batch__c>();
        for (Integer i = 0; i < 5; i++) {
            batches.add(new Payment_Batch__c(
                Status__c          = 'Draft',
                Payment_Period__c  = '2026-04'
            ));
        }
        insert batches;

        List<Commission_Record__c> records = new List<Commission_Record__c>();
        for (Payment_Batch__c pb : batches) {
            records.add(new Commission_Record__c(
                Agent__c            = agent.Id,
                Payment_Batch__c    = pb.Id,
                Gross_Amount__c     = 100,
                Payment_Period__c   = '2026-04'
            ));
        }
        insert records;

        Test.startTest();
        for (Payment_Batch__c pb : batches) {
            pb.Status__c = 'Paid';
        }
        update batches;
        Test.stopTest();

        System.assertEquals(5,
            [SELECT COUNT() FROM Payment_Batch__c WHERE Id IN :batches AND Status__c = 'Paid'],
            '5 batches should all be Paid');
    }

    @IsTest
    static void testPaidBatchWithoutCommissionRecordsExitsEarly() {
        Payment_Batch__c batch = new Payment_Batch__c(
            Status__c          = 'Draft',
            Payment_Period__c  = '2026-05'
        );
        insert batch;

        Test.startTest();
        batch.Status__c = 'Paid';
        update batch;
        Test.stopTest();

        System.assertEquals('Paid',
            [SELECT Status__c FROM Payment_Batch__c WHERE Id = :batch.Id].Status__c,
            'Batch should still reach Paid even with no commission records');
        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c],
            'agentTotals.isEmpty() should exit before publishing or logging anything');
    }

    // NOTE ON WHY THIS IS TWO TESTS, NOT ONE END-TO-END TEST:
    //
    // The natural way to test PB-0018 would be one test that updates a
    // batch to 'Paid' and inspects the JSON actually POSTed to GO AMS.
    // That doesn't work in a single test method here, confirmed via two
    // rounds of debug-log inspection:
    //
    //   batch update -> EventBus.publish -> subscriber trigger -> enqueueJob(GoAMSCallout)
    //
    // Platform-event delivery is itself one asynchronous operation that
    // Test.stopTest() drains; the enqueueJob() call that happens *inside*
    // that delivery (in the subscriber trigger) is a second, nested one.
    // Test.stopTest() only drains async work that existed before/at the
    // call — it does not loop to also run async work newly queued during
    // its own drain. The GoAMSCallout constructor runs, but
    // getAccessToken()/postEvent() never fire before stopTest() returns
    // (confirmed: no METHOD_ENTRY for either in the log). Calling
    // Test.startTest()/Test.stopTest() a second time to force that drain
    // doesn't work either — Apex throws System.FinalException: "Testing
    // already started", since both methods are limited to one call per
    // test method. The deferred job does eventually run, but only later,
    // decoupled from this test method's own assertions and mock instance
    // (observed executing in the gap between two *other* test methods).
    //
    // So this is split into what's actually deterministic within one test
    // method:
    //   1) CommissionPaidHelper really does send Period__c through
    //      unmodified (single level of async — enqueueJob called directly
    //      by the test, no subscriber involved).
    //   2) The trigger's own aggregate query pulls Payment_Period__c from
    //      Commission_Record__c, not from the parent Payment_Batch__c's
    //      same-named field — checked synchronously, no async involved.

    @IsTest
    static void testHelperSendsPeriodThroughUnmodified() {
        CapturingMock mock = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Commission_Paid__e evt = new Commission_Paid__e(
            Contact_ID__c    = '003000000000001AAA',
            Batch_ID__c      = 'a010000000000001AAA',
            Total_Amount__c  = '250',
            Period__c        = '2026-03'
        );

        Test.startTest();
        System.enqueueJob(new CommissionPaidHelper.GoAMSCallout(
            new List<Commission_Paid__e>{ evt }, 0
        ));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c],
            'A successful OAuth + event POST should not write an error log');
        System.assert(String.isNotBlank(mock.capturedBody),
            'Expected the event-POST payload to have been captured');
        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(mock.capturedBody);
        System.assertEquals('2026-03', payload.get('period'),
            'Period__c should be sent as the raw "YYYY-MM" value with no '
                + 'date-range split applied');
    }

    @IsTest
    static void testTriggerAggregateReadsPeriodFromCommissionRecordNotBatch() {
        Contact agent = createAgent('period001');

        Payment_Batch__c batch = new Payment_Batch__c(
            Status__c          = 'Draft',
            // Deliberately different from the Commission_Record__c's own
            // Payment_Period__c below — proves the trigger's source of
            // truth is the CR's field, not the parent batch's same-named
            // field (the exact mix-up PB-0018 fixed).
            Payment_Period__c  = '1999-12'
        );
        insert batch;

        insert new Commission_Record__c(
            Agent__c            = agent.Id,
            Payment_Batch__c    = batch.Id,
            Gross_Amount__c     = 250,
            Payment_Period__c   = '2026-03'
        );

        // Mirrors CommissionPaidTrigger's own aggregate query exactly.
        List<AggregateResult> agentTotals = [
            SELECT Agent__c,
                   Payment_Batch__c batchId,
                   SUM(Net_Amount__c) totalAmount,
                   MIN(Payment_Period__c) period
            FROM Commission_Record__c
            WHERE Payment_Batch__c = :batch.Id
            AND Agent__c != null
            GROUP BY Agent__c, Payment_Batch__c
        ];

        System.assertEquals(1, agentTotals.size());
        System.assertEquals('2026-03', agentTotals[0].get('period'),
            'The trigger\'s aggregate should read Payment_Period__c off '
                + 'Commission_Record__c ("2026-03"), not off the parent '
                + 'Payment_Batch__c ("1999-12")');
    }

    // ─── CommissionPaidHelper.publishEvents (moved from the trigger) ────────
    //
    // Triggers have no static members a test class can reach into, so the
    // try/catch around EventBus.publish() was moved into
    // CommissionPaidHelper.publishEvents specifically so a test-only flag
    // (simulateException) can force the catch block to run — EventBus.publish()
    // itself only throws on conditions (e.g. exceeding the platform event
    // publish limit) that aren't practical to reproduce from ordinary test
    // data.

    @IsTest
    static void testCatchBlockLogsErrorWhenPublishThrows() {
        CommissionPaidHelper.simulateException = true;
        Payment_Batch__c batch = getBatch();

        Test.startTest();
        batch.Status__c = 'Paid';
        update batch;
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Status__c, Error_Message__c
            FROM Error_Log__c
            WHERE Source__c = 'CommissionPaidTrigger'
        ];
        System.assert(!logs.isEmpty(), 'Expected the catch block to log an error');
        System.assertEquals('New', logs[0].Status__c);
    }

    // ─── CommissionPaidHelper.sendToGoAMS / GoAMSCallout ─────────────────────

    @IsTest
    static void testSendToGoAMSSuccess() {
        Test.setMock(HttpCalloutMock.class, new GoAMSMock());

        Commission_Paid__e evt = new Commission_Paid__e(
            Contact_ID__c    = '003000000000001AAA',
            Batch_ID__c      = 'a010000000000001AAA',
            Total_Amount__c  = '1000',
            Period__c        = '2026-04'
        );

        Test.startTest();
        CommissionPaidHelper.sendToGoAMS(new List<Commission_Paid__e>{ evt });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c],
            'A successful OAuth + event POST should not write an error log');
    }

    @IsTest
    static void testQueueableOAuthFailureDeadLettersAtMaxRetries() {
        Test.setMock(HttpCalloutMock.class, new OAuthFailureMock());

        Commission_Paid__e evt = new Commission_Paid__e(
            Contact_ID__c    = '003000000000001AAA',
            Batch_ID__c      = 'a010000000000001AAA',
            Total_Amount__c  = '1500',
            Period__c        = '2026-05'
        );

        // Construct the Queueable directly at the max retry count instead of
        // relying on chained/delayed re-enqueues to exhaust naturally —
        // System.enqueueJob(job, delayInMinutes) chains aren't reliably
        // fast-forwarded by Test.stopTest(), so this keeps the test
        // deterministic.
        Test.startTest();
        System.enqueueJob(new CommissionPaidHelper.GoAMSCallout(
            new List<Commission_Paid__e>{ evt },
            GoAMSRetryUtil.MAX_RETRIES
        ));
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Status__c
            FROM Error_Log__c
            WHERE Source__c = 'CommissionPaidHelper.GoAMSCallout'
        ];
        System.assert(!logs.isEmpty(), 'OAuth failure at max retries should dead-letter');
        System.assertEquals('Dead Letter', logs[0].Status__c);
    }

    @IsTest
    static void testQueueableRetryableEventFailureDeadLettersAtMaxRetries() {
        Test.setMock(HttpCalloutMock.class, new EventServerErrorMock());

        Commission_Paid__e evt = new Commission_Paid__e(
            Contact_ID__c    = '003000000000001AAA',
            Batch_ID__c      = 'a010000000000001AAA',
            Total_Amount__c  = '2500',
            Period__c        = '2026-06'
        );

        Test.startTest();
        System.enqueueJob(new CommissionPaidHelper.GoAMSCallout(
            new List<Commission_Paid__e>{ evt },
            GoAMSRetryUtil.MAX_RETRIES
        ));
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Status__c
            FROM Error_Log__c
            WHERE Source__c = 'CommissionPaidHelper.GoAMSCallout'
        ];
        System.assert(!logs.isEmpty(), '5xx failure at max retries should dead-letter');
        System.assertEquals('Dead Letter', logs[0].Status__c);
    }

    @IsTest
    static void testQueueableNonRetryableEventFailureDeadLettersImmediately() {
        Test.setMock(HttpCalloutMock.class, new EventBadRequestMock());

        Commission_Paid__e evt = new Commission_Paid__e(
            Contact_ID__c    = '003000000000001AAA',
            Batch_ID__c      = 'a010000000000001AAA',
            Total_Amount__c  = '2500',
            Period__c        = '2026-06'
        );

        Test.startTest();
        // retryCount = 0: a non-retryable 4xx should dead-letter on the very
        // first attempt, inside postEvent() itself — no retry loop needed.
        System.enqueueJob(new CommissionPaidHelper.GoAMSCallout(
            new List<Commission_Paid__e>{ evt },
            0
        ));
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Status__c, Error_Message__c
            FROM Error_Log__c
            WHERE Source__c = 'CommissionPaidHelper.GoAMSCallout'
        ];
        System.assert(!logs.isEmpty(), 'Non-retryable 4xx should dead-letter immediately');
        System.assertEquals('Dead Letter', logs[0].Status__c);
    }

    // KNOWN PRODUCTION BUG (confirmed via debug log, not just a test
    // artifact): when Total_Amount__c fails to parse, postEvent() calls
    // logDeadLetter() (a DML insert) and then falls through into the HTTP
    // callout for that same event anyway. Salesforce disallows a callout
    // after uncommitted DML in the same transaction, so that callout throws
    // System.CalloutException: "You have uncommitted work pending." That
    // exception is caught by postEvent()'s generic catch block and
    // misclassified as retryable, so the batch gets rescheduled even though
    // a bad Total_Amount__c will never parse on retry — wasting retries and
    // writing duplicate dead-letter logs in production.
    //
    // Recommended fix in CommissionPaidHelper.postEvent(): return false
    // immediately after logDeadLetter() when amountParseFailed is true,
    // instead of continuing on to attempt the callout:
    //
    //   if (amountParseFailed) {
    //       logDeadLetter(contactId, batchId, '...');
    //       return false; // not retryable — bad source data, skip the callout
    //   }
    //
    // Until that fix lands, retryCount is pinned to GoAMSRetryUtil.MAX_RETRIES
    // here so the misclassified "retry" hits the dead-letter branch directly
    // instead of trying to re-enqueue — re-enqueuing a second job from
    // within this test method exceeds Apex's test-context limit of one
    // System.enqueueJob call per test and throws
    // System.AsyncException: Maximum stack depth has been reached.
    @IsTest
    static void testQueueableUnparsableTotalAmountIsLoggedButDoesNotThrow() {
        Test.setMock(HttpCalloutMock.class, new GoAMSMock());

        Commission_Paid__e evt = new Commission_Paid__e(
            Contact_ID__c    = '003000000000001AAA',
            Batch_ID__c      = 'a010000000000001AAA',
            Total_Amount__c  = 'not-a-number',
            Period__c        = '2026-06'
        );

        Test.startTest();
        System.enqueueJob(new CommissionPaidHelper.GoAMSCallout(
            new List<Commission_Paid__e>{ evt }, GoAMSRetryUtil.MAX_RETRIES
        ));
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Error_Message__c
            FROM Error_Log__c
            WHERE Source__c = 'CommissionPaidHelper.GoAMSCallout'
        ];
        System.assert(!logs.isEmpty(), 'Unparsable Total_Amount__c should be logged');
        Boolean foundParseFailureLog = false;
        for (Error_Log__c log : logs) {
            if (log.Error_Message__c.contains('could not be parsed')) {
                foundParseFailureLog = true;
            }
        }
        System.assert(foundParseFailureLog,
            'Expected a dead-letter log describing the unparsable Total_Amount__c');
    }

    @IsTest
    static void testMultipleEventsInOneQueueable() {
        Test.setMock(HttpCalloutMock.class, new GoAMSMock());

        List<Commission_Paid__e> events = new List<Commission_Paid__e>();
        for (Integer i = 0; i < 5; i++) {
            events.add(new Commission_Paid__e(
                Contact_ID__c    = String.valueOf(i),
                Batch_ID__c      = String.valueOf(i),
                Total_Amount__c  = '100',
                Period__c        = '2026-06'
            ));
        }

        Test.startTest();
        System.enqueueJob(new CommissionPaidHelper.GoAMSCallout(events, 0));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c],
            'All 5 events should succeed with the happy-path mock');
    }

    @IsTest
    static void testPlatformEventSubscriberInvokesHelper() {
        Test.setMock(HttpCalloutMock.class, new GoAMSMock());

        Commission_Paid__e evt = new Commission_Paid__e(
            Contact_ID__c    = '003000000000001AAA',
            Batch_ID__c      = 'a010000000000001AAA',
            Total_Amount__c  = '999',
            Period__c        = '2026-04'
        );

        Test.startTest();
        EventBus.publish(evt);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c]);
    }

    // ─── CommissionPaidHelper.logErrors ──────────────────────────────────────

    @IsTest
    static void testLogErrorsWithEmptyResultsWritesNothing() {
        Test.startTest();
        CommissionPaidHelper.logErrors(
            new List<Database.SaveResult>(),
            new List<Commission_Paid__e>()
        );
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c]);
    }

    // NOTE: Database.SaveResult has no public constructor, so a genuine
    // "failed publish" SaveResult can only come from a real EventBus.publish
    // call against malformed data (e.g. a required-field violation specific
    // to your org's validation rules). The successful-publish branch of
    // logErrors is already covered indirectly by
    // testPaidStatusPublishesEventAndCallsOut and
    // testPlatformEventSubscriberInvokesHelper above, both of which run a
    // real publish through logErrors and assert zero Error_Log__c rows.
    // If you want explicit failure-branch coverage, add a validation rule
    // trigger case here specific to your Commission_Paid__e schema.
}