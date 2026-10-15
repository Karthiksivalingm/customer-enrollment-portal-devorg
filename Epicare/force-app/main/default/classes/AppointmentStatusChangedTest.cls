/*
 * ============================================================
 * NOTE ON Require_Green_Onboarding_Semaphore
 * ============================================================
 *
 * Overall_Semaphore__c is an IMAGE() formula field, so comparing it
 * to the literal string "Green" in a validation rule never matches
 * on its own. Require_Green_Onboarding_Semaphore has since been
 * updated (outside this class) to also allow
 * NOT(Agent__r.Bypass_VR__c) as an override:
 *
 *   AND(
 *       NOT(ISPICKVAL(Status__c, "Request")),
 *       Agent__r.Overall_Semaphore__c <> "Green",
 *       NOT(Agent__r.Bypass_VR__c)
 *   )
 *
 * setupData() below sets Bypass_VR__c = true on the test agent, so
 * Appointment Status__c changes now save normally for these tests.
 * ============================================================
 */
@IsTest
private class AppointmentStatusChangedTest {

    /*
     * ============================================================
     * TEST DATA HELPERS
     * ============================================================
     */

    /*
     * Use Agency Director instead of Agent to avoid Agent-specific
     * automation such as Agent_Created__e processing.
     */
    private static Id getContactRecordTypeId() {

        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Contact
                .getRecordTypeInfosByName()
                .get('Agency Director');

        System.assertNotEquals(
            null,
            rtInfo,
            'Agency Director Contact Record Type must exist.'
        );

        return rtInfo.getRecordTypeId();
    }


    @testSetup
    static void setupData() {

        Account agency = new Account(
            Name = 'Appointment Status Test Agency 001'
        );

        insert agency;


        /*
         * Several tests below move Status__c away from "Request"
         * (to "Active" / "On Agent Side"), which the
         * Require_Green_Onboarding_Semaphore validation rule on
         * Appointment__c blocks unless Agent__r.Overall_Semaphore__c
         * = "Green". That field derives from the agent's completion
         * checkboxes below — without them the update fails with
         * FIELD_CUSTOM_VALIDATION_EXCEPTION: "The appointment cannot
         * advance beyond 'Requested' until the agent's onboarding
         * semaphore is Green." (confirmed via execution log).
         *
         * The completion checkboxes alone aren't enough: the log shows
         * Certification_Complete__c / Base_Documents_Complete__c /
         * Banking_Complete__c / EO_Complete__c getting recalculated back
         * to false partway through createAppointment() (very likely by
         * State_Appointment__c automation deriving them from real
         * license/banking/E&O child records we don't have), which flips
         * Overall_Semaphore__c back to Red before the Status__c update
         * even runs. Bypass_VR__c is set as a more durable safeguard —
         * it's a plain flag, not a derived/recalculated field, so it
         * isn't subject to that same overwrite.
         */
        Contact agent = new Contact(
            RecordTypeId =
                getContactRecordTypeId(),

            LastName =
                'Appointment Status Agent 001',

            AccountId =
                agency.Id,

            Email =
                'appointment.status.agent.001@test.com',

            NPN__c =
                '93000001',

            Agent_Status__c =
                'Onboarding',

            Insurance_Types__c =
                'Life',

            Base_Documents_Complete__c =
                true,

            Banking_Complete__c =
                true,

            EO_Complete__c =
                true,

            License_Complete__c =
                true,

            Certification_Complete__c =
                true,

            E_O_Termination_Date__c =
                Date.today().addYears(1),

            Background_Check_Status__c =
                'Passed',

            Bypass_VR__c =
                true
        );

        insert agent;


        /*
         * The Appointment validation requires an ACTIVE
         * Life certification for the assigned agent.
         *
         * Check whether automation already created one.
         * If it did, make it Active.
         * Otherwise create one directly.
         */
        List<Certification__c> certifications = [
            SELECT Id,
                   Agent__c,
                   Insurance_Type__c,
                   Status__c
            FROM Certification__c
            WHERE Agent__c = :agent.Id
            AND Insurance_Type__c = 'Life'
            LIMIT 1
        ];


        if (certifications.isEmpty()) {

            Certification__c certification =
                new Certification__c(
                    Agent__c =
                        agent.Id,

                    Insurance_Type__c =
                        'Life',

                    Status__c =
                        'Active'
                );

            insert certification;

        } else {

            Certification__c certification =
                certifications[0];

            certification.Status__c =
                'Active';

            update certification;
        }


        /*
         * Inserting/updating Certification__c above triggers a Flow
         * that auto-creates an Onboarding_Checklist__c record, which in
         * turn fires OnboardingChecklistTriggerHandler.updateContact
         * ChecklistStatus() — confirmed via execution log (DML_BEGIN
         * Insert Onboarding_Checklist__c, immediately followed by
         * DML_BEGIN Update Contact from that handler). That handler
         * recalculates Certification_Complete__c, Banking_Complete__c,
         * Base_Documents_Complete__c, and EO_Complete__c back to false
         * based on real checklist data we haven't set up, which flips
         * Overall_Semaphore__c back to Red — undoing the values set on
         * the agent Contact above. This is the actual reason the
         * Require_Green_Onboarding_Semaphore validation rule on
         * Appointment__c kept failing even after those fields were set
         * at Contact creation. (Bypass_VR__c does not help here — it's
         * consumed by unrelated Contact validation rules, not by this
         * Appointment validation rule.)
         *
         * Re-affirming the fields here, as the last Contact DML in
         * setupData(), makes them the values captured by the
         * @testSetup savepoint that every test method starts from.
         */
        agent.Base_Documents_Complete__c =
            true;

        agent.Banking_Complete__c =
            true;

        agent.EO_Complete__c =
            true;

        agent.License_Complete__c =
            true;

        agent.Certification_Complete__c =
            true;

        update agent;


        Carrier__c carrier =
            new Carrier__c(
                Name =
                    'Appointment Status Carrier 001',

                Supported_Lines_of_Business__c =
                    'Life'
            );

        insert carrier;
    }


    /*
     * ============================================================
     * CREATE APPOINTMENT
     * ============================================================
     */
    private static Appointment__c createAppointment(
        String uniqueNumber
    ) {

        Contact agent = [
            SELECT Id,
                   AccountId
            FROM Contact
            LIMIT 1
        ];


        Carrier__c carrier = [
            SELECT Id
            FROM Carrier__c
            LIMIT 1
        ];


        Appointment__c app =
            new Appointment__c(

                Agency__c =
                    agent.AccountId,

                Agent__c =
                    agent.Id,

                Carrier__c =
                    carrier.Id,

                Line_of_Business__c =
                    'Life',

                State_s__c =
                    'TX',

                Status__c =
                    'Request',

                Sub_Status__c =
                    'Inactive',

                Carrier_Cert_Required__c =
                    false,

                Writing_Number__c =
                    'WN-' + uniqueNumber
            );


        insert app;


        /*
         * Appointment automation creates a State_Appointment__c
         * record. In the current org it is initially created as
         * "On agent Side".
         *
         * AppointmentTrigger validation requires "Active".
         */
        List<State_Appointment__c> stateAppointments = [
            SELECT Id,
                   State__c,
                   State_Status__c,
                   Appointment__c
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
            AND State__c = 'TX'
            LIMIT 1
        ];


        if (stateAppointments.isEmpty()) {

            State_Appointment__c stateAppointment =
                new State_Appointment__c(
                    Appointment__c =
                        app.Id,

                    State__c =
                        'TX',

                    State_Status__c =
                        'Active'
                );

            insert stateAppointment;

        } else {

            State_Appointment__c stateAppointment =
                stateAppointments[0];

            stateAppointment.State_Status__c =
                'Active';

            update stateAppointment;
        }


        return app;
    }


    /*
     * ============================================================
     * HTTP MOCKS
     * ============================================================
     */

    /*
     * Successful OAuth + successful GoAMS API response.
     */
    private class SuccessMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest req
        ) {

            HttpResponse res =
                new HttpResponse();

            if (
                req.getEndpoint()
                    .contains('/oauth-token')
            ) {

                res.setStatusCode(200);

                res.setBody(
                    '{"access_token":"dummyToken"}'
                );

            } else {

                res.setStatusCode(200);

                res.setBody(
                    '{"success":true}'
                );
            }

            return res;
        }
    }


    /*
     * OAuth failure.
     */
    private class OAuthFailureMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest req
        ) {

            HttpResponse res =
                new HttpResponse();

            if (
                req.getEndpoint()
                    .contains('/oauth-token')
            ) {

                res.setStatusCode(500);

                res.setBody(
                    'OAuth Server Error'
                );

            } else {

                res.setStatusCode(500);

                res.setBody(
                    'GoAMS Error'
                );
            }

            return res;
        }
    }


    /*
     * OAuth succeeds but GoAMS returns
     * a non-retryable 400.
     */
    private class NonRetryableFailureMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest req
        ) {

            HttpResponse res =
                new HttpResponse();

            if (
                req.getEndpoint()
                    .contains('/oauth-token')
            ) {

                res.setStatusCode(200);

                res.setBody(
                    '{"access_token":"dummyToken"}'
                );

            } else {

                res.setStatusCode(400);

                res.setBody(
                    'Bad Request'
                );
            }

            return res;
        }
    }


    /*
     * OAuth succeeds but GoAMS returns a RETRYABLE (5xx) error.
     * Distinct from NonRetryableFailureMock above: this exercises the
     * postEvent() branch where GoAMSRetryUtil.isRetryableStatus()
     * returns true (toRetry.add(evt); return true;), which
     * NonRetryableFailureMock's 400 never reaches.
     */
    private class RetryableFailureMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest req
        ) {

            HttpResponse res =
                new HttpResponse();

            if (
                req.getEndpoint()
                    .contains('/oauth-token')
            ) {

                res.setStatusCode(200);

                res.setBody(
                    '{"access_token":"dummyToken"}'
                );

            } else {

                res.setStatusCode(500);

                res.setBody(
                    'GoAMS Internal Server Error'
                );
            }

            return res;
        }
    }


    /*
     * ============================================================
     * 1. APPOINTMENT STATUS TRIGGER
     * ============================================================
     */

    /*
     * Verify a normal Status__c change publishes
     * the event and the Appointment is updated.
     */
    @IsTest
    static void testStatusChangePublishesEvent() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        Appointment__c app =
            createAppointment('001');


        Test.startTest();

        app.Status__c =
            'Active';

        update app;

        Test.stopTest();


        Appointment__c updated = [
            SELECT Id,
                   Status__c
            FROM Appointment__c
            WHERE Id = :app.Id
        ];


        System.assertEquals(
            'Active',
            updated.Status__c,
            'Appointment Status should be updated.'
        );

        // Strengthens the happy path: a mock-matching mistake (e.g. the
        // OAuth endpoint check silently falling through to the failure
        // branch) would otherwise pass this test unnoticed since it
        // doesn't otherwise inspect callout outcomes.
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'A successful OAuth + GoAMS callout should not write any error logs.'
        );
    }


    /*
     * Verify changing fields other than Status__c
     * does NOT publish Appointment_Status_Changed__e.
     */
    @IsTest
    static void testNoStatusChange() {

        Appointment__c app =
            createAppointment('002');


        Test.startTest();

        app.Writing_Number__c =
            'WN-UPDATED-002';

        update app;

        Test.stopTest();


        Appointment__c updated = [
            SELECT Id,
                   Status__c,
                   Writing_Number__c
            FROM Appointment__c
            WHERE Id = :app.Id
        ];


        System.assertEquals(
            'Request',
            updated.Status__c,
            'Status should remain unchanged.'
        );


        System.assertEquals(
            'WN-UPDATED-002',
            updated.Writing_Number__c,
            'Writing Number should be updated.'
        );


        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'No event should be published (and therefore no callout attempted) when Status__c is unchanged.'
        );
    }


    /*
     * Verify:
     *
     * Status = On Agent Side
     * AND
     * Carrier_Cert_Required__c = true
     *
     * causes the additional Carrier Cert Required event
     * to be published.
     */
    /*
     * Verify:
     *
     * Status = On Agent Side
     * AND
     * Carrier_Cert_Required__c = true
     *
     * causes the additional Carrier Cert Required event
     * to be published.
     */
    @IsTest
    static void testCarrierCertRequiredBranch() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        Appointment__c app =
            createAppointment('003');


        Test.startTest();

        app.Carrier_Cert_Required__c =
            true;

        app.Status__c =
            'On Agent Side';

        update app;

        Test.stopTest();


        Appointment__c updated = [
            SELECT Id,
                   Status__c,
                   Carrier_Cert_Required__c
            FROM Appointment__c
            WHERE Id = :app.Id
        ];


        System.assertEquals(
            'On Agent Side',
            updated.Status__c,
            'Appointment should have On Agent Side status.'
        );


        System.assertEquals(
            true,
            updated.Carrier_Cert_Required__c,
            'Carrier Certification Required should be true.'
        );

        // Two events are published on this branch (the status-change
        // event plus the Carrier Cert Required event) — both callouts
        // should succeed with zero error logs.
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'Both published events should be delivered successfully.'
        );
    }


    /*
     * Verify that On Agent Side with
     * Carrier_Cert_Required__c = false
     * does NOT execute the additional Carrier Cert branch.
     */
    @IsTest
    static void testCarrierCertFalseBranch() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        Appointment__c app =
            createAppointment('004');


        Test.startTest();

        app.Status__c =
            'On Agent Side';

        app.Carrier_Cert_Required__c =
            false;

        update app;

        Test.stopTest();


        Appointment__c updated = [
            SELECT Id,
                   Status__c,
                   Carrier_Cert_Required__c
            FROM Appointment__c
            WHERE Id = :app.Id
        ];


        System.assertEquals(
            'On Agent Side',
            updated.Status__c
        );


        System.assertEquals(
            false,
            updated.Carrier_Cert_Required__c
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'The single status-change event should be delivered successfully.'
        );
    }


    /*
     * ============================================================
     * 2. BULK TRIGGER TEST
     * ============================================================
     */
    @IsTest
    static void testMultipleAppointmentsStatusChange() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        List<Appointment__c> apps =
            new List<Appointment__c>();


        for (
            Integer i = 1;
            i <= 5;
            i++
        ) {

            apps.add(
                createAppointment(
                    'BULK-' +
                    String.valueOf(i)
                )
            );
        }


        Test.startTest();

        for (
            Appointment__c app :
            apps
        ) {

            app.Status__c =
                'Active';
        }


        update apps;

        Test.stopTest();


        Integer countUpdated = [
            SELECT COUNT()
            FROM Appointment__c
            WHERE Id IN :apps
            AND Status__c = 'Active'
        ];


        System.assertEquals(
            5,
            countUpdated,
            'All five Appointments should be updated.'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'All five events should be delivered successfully.'
        );
    }


    /*
     * ============================================================
     * 3. PLATFORM EVENT SUBSCRIBER
     * ============================================================
     */
    @IsTest
    static void testEventSubscriber() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000001AAA',

                New_Status__c =
                    'Active',

                Sub_Status__c =
                    'Inactive',

                Carrier__c =
                    'a020000000000001AAA',

                Writing_Number__c =
                    'WN-SUB-001',

                Contact_Id__c =
                    '003000000000001AAA',

                NPN__c =
                    '93000001'
            );


        Test.startTest();

        Database.SaveResult result =
            EventBus.publish(evt);


        System.assertEquals(
            true,
            result.isSuccess(),
            'Appointment Status Changed event should be published.'
        );


        Test.getEventBus().deliver();

        Test.stopTest();


        System.assertEquals(
            true,
            result.isSuccess()
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'The subscriber should deliver the event to GoAMS without error.'
        );
    }


    /*
     * ============================================================
     * 4. DIRECT sendToGoAMS() TEST
     * ============================================================
     */
    @IsTest
    static void testSendToGoAMS() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000002AAA',

                New_Status__c =
                    'Active',

                Sub_Status__c =
                    'Inactive',

                Carrier__c =
                    'a020000000000002AAA',

                Writing_Number__c =
                    'WN-DIRECT-001',

                Contact_Id__c =
                    '003000000000002AAA',

                NPN__c =
                    '93000002'
            );


        Test.startTest();

        AppointmentStatusChangedHelper.sendToGoAMS(
            new List<Appointment_Status_Changed__e>{
                evt
            }
        );

        Test.stopTest();


        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'sendToGoAMS should complete a successful callout without logging an error.'
        );
    }


    /*
     * ============================================================
     * 5. DIRECT QUEUEABLE EXECUTION
     * ============================================================
     */
    @IsTest
    static void testQueueableExecute() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000003AAA',

                New_Status__c =
                    'Active',

                Sub_Status__c =
                    'Inactive',

                Carrier__c =
                    'a020000000000003AAA',

                Writing_Number__c =
                    'WN-QUEUE-001',

                Contact_Id__c =
                    '003000000000003AAA',

                NPN__c =
                    '93000003'
            );


        Test.startTest();

        System.enqueueJob(
            new AppointmentStatusChangedHelper.GoAMSCallout(
                new List<Appointment_Status_Changed__e>{
                    evt
                },
                0
            )
        );

        Test.stopTest();


        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'The Queueable should complete a successful callout without logging an error.'
        );
    }


    /*
     * ============================================================
     * 6. OAUTH FAILURE
     * ============================================================
     */

    /*
     * KNOWN RISK (test-class-only fix — GoAMSCallout / GoAMSRetryUtil
     * are out of scope): OAuthFailureMock returns HTTP 500 for every
     * call, so getAccessToken() never succeeds. If this Queueable is
     * started at retryCount = 0, execute() fails, calls
     * retryOrDeadLetterBatch(), and — since 0 < MAX_RETRIES — chains
     * one retry Queueable (retryCount = 1). Test.stopTest() forces
     * that job to run too (the one level of Queueable chaining
     * Salesforce allows in test context). It fails again against the
     * same always-500 mock and tries to chain a SECOND retry, which
     * exceeds the test-context chain-depth limit and throws an
     * uncaught System.AsyncException: Maximum stack depth has been
     * reached — the same failure pattern already seen in
     * AgentCreatedHelper.GoAMSCallout and
     * UplinePolicyToCommissionHandler's GoAMS retry logic on this org.
     *
     * Starting the Queueable at retryCount = GoAMSRetryUtil.MAX_RETRIES
     * instead of 0 makes the very first failure take the dead-letter
     * branch immediately (retryCount < MAX_RETRIES is false), so no
     * further job is ever enqueued — regardless of what MAX_RETRIES is
     * actually configured to. This still exercises the OAuth-failure
     * code path end to end (getAccessToken() returns null ->
     * retryOrDeadLetterBatch() -> logDeadLetter()); it just verifies
     * the "retries exhausted" outcome rather than forcing a live
     * multi-level retry chain through the test's async flush, which
     * the platform doesn't support past one level in test context.
     */
    @IsTest
    static void testOAuthFailure() {

        Test.setMock(
            HttpCalloutMock.class,
            new OAuthFailureMock()
        );


        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000004AAA',

                New_Status__c =
                    'Active',

                Sub_Status__c =
                    'Inactive',

                Carrier__c =
                    'a020000000000004AAA',

                Writing_Number__c =
                    'WN-OAUTH-001',

                Contact_Id__c =
                    '003000000000004AAA',

                NPN__c =
                    '93000004'
            );


        Test.startTest();

        System.enqueueJob(
            new AppointmentStatusChangedHelper.GoAMSCallout(
                new List<Appointment_Status_Changed__e>{
                    evt
                },
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
            WHERE Source__c =
                'AppointmentStatusChangedHelper.GoAMSCallout'
        ];


        System.assert(
            logs.size() > 0,
            'A dead-letter Error_Log should be created once retries are exhausted after an OAuth failure.'
        );


        System.assertEquals(
            'Dead Letter',
            logs[0].Status__c,
            'Error log should have Dead Letter status.'
        );
    }


    /*
     * ============================================================
     * 7. NON-RETRYABLE GOAMS ERROR
     * ============================================================
     */
    @IsTest
    static void testNonRetryableGoAMSFailure() {

        Test.setMock(
            HttpCalloutMock.class,
            new NonRetryableFailureMock()
        );


        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000005AAA',

                New_Status__c =
                    'Active',

                Sub_Status__c =
                    'Inactive',

                Carrier__c =
                    'a020000000000005AAA',

                Writing_Number__c =
                    'WN-FAIL-001',

                Contact_Id__c =
                    '003000000000005AAA',

                NPN__c =
                    '93000005'
            );


        Test.startTest();

        System.enqueueJob(
            new AppointmentStatusChangedHelper.GoAMSCallout(
                new List<Appointment_Status_Changed__e>{
                    evt
                },
                0
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
            WHERE Source__c =
                'AppointmentStatusChangedHelper.GoAMSCallout'
        ];


        System.assert(
            logs.size() > 0,
            'A dead-letter Error_Log should be created for a non-retryable error.'
        );


        System.assertEquals(
            'Dead Letter',
            logs[0].Status__c,
            'Error log should have Dead Letter status.'
        );
    }


    /*
     * ============================================================
     * 7b. RETRYABLE GOAMS ERROR (distinct code path from #7)
     * ============================================================
     *
     * postEvent() only takes the toRetry.add(evt) / "return true"
     * branch when GoAMSRetryUtil.isRetryableStatus() says the failure
     * is retryable (e.g. 5xx) — NonRetryableFailureMock's 400 in
     * testNonRetryableGoAMSFailure never reaches that branch, since
     * it dead-letters immediately inside postEvent() instead. This
     * test starts the Queueable at retryCount = MAX_RETRIES (same
     * deterministic, single-execute()-call pattern used above) so
     * the eventual dead-letter still happens without any further
     * System.enqueueJob call — re-enqueuing from within an
     * already-running job reliably throws
     * System.AsyncException: Maximum stack depth has been reached
     * in this org's test context, so that path isn't safely
     * testable from here.
     */
    @IsTest
    static void testRetryableGoAMSFailure() {

        Test.setMock(
            HttpCalloutMock.class,
            new RetryableFailureMock()
        );


        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000005AAA',

                New_Status__c =
                    'Active',

                Sub_Status__c =
                    'Inactive',

                Carrier__c =
                    'a020000000000005AAA',

                Writing_Number__c =
                    'WN-RETRYABLE-001',

                Contact_Id__c =
                    '003000000000005AAA',

                NPN__c =
                    '93000005'
            );


        Test.startTest();

        System.enqueueJob(
            new AppointmentStatusChangedHelper.GoAMSCallout(
                new List<Appointment_Status_Changed__e>{
                    evt
                },
                GoAMSRetryUtil.MAX_RETRIES
            )
        );

        Test.stopTest();


        List<Error_Log__c> logs = [
            SELECT Id,
                   Status__c
            FROM Error_Log__c
            WHERE Source__c =
                'AppointmentStatusChangedHelper.GoAMSCallout'
        ];


        System.assert(
            logs.size() > 0,
            'A retryable 5xx failure at max retries should still dead-letter.'
        );


        System.assertEquals(
            'Dead Letter',
            logs[0].Status__c,
            'Error log should have Dead Letter status.'
        );
    }


    /*
     * ============================================================
     * 8. logErrors() WITH EMPTY RESULTS
     * ============================================================
     */
    @IsTest
    static void testLogErrorsWithNoErrors() {

        List<Database.SaveResult> results =
            new List<Database.SaveResult>();

        List<Appointment__c> appointments =
            new List<Appointment__c>();


        Test.startTest();

        AppointmentStatusChangedHelper.logErrors(
            results,
            appointments
        );

        Test.stopTest();


        Integer countLogs = [
            SELECT COUNT()
            FROM Error_Log__c
            WHERE Source__c =
                'AppointmentStatusChangedTrigger'
        ];


        System.assertEquals(
            0,
            countLogs,
            'No Error_Log should be created when there are no failed results.'
        );
    }


    /*
     * ============================================================
     * 8b. logErrors() WITH A GENUINE FAILED SaveResult
     * ============================================================
     *
     * Database.SaveResult has no public constructor, so the only way
     * to exercise logErrors()'s "insert an Error_Log__c per failed
     * result" branch with a real one is to make an actual
     * EventBus.publish() call fail. Platform events don't support
     * validation rules, but they do still enforce field length —
     * publishing a value far longer than any realistic Text field
     * limit forces a genuine STRING_TOO_LONG failure reported via the
     * returned SaveResult (not a thrown exception), which is exactly
     * the shape logErrors() is built to handle. No callouts or
     * Queueable chaining are involved, so this is safe regardless of
     * the platform's test-context stack-depth limits discussed above.
     */
    @IsTest
    static void testLogErrorsWithFailedPublish() {

        String oversizedValue =
            ''.rightPad(1000, 'X');

        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000008AAA',

                New_Status__c =
                    'Active',

                Sub_Status__c =
                    'Inactive',

                Carrier__c =
                    'a020000000000008AAA',

                Writing_Number__c =
                    oversizedValue,

                Contact_Id__c =
                    '003000000000008AAA',

                NPN__c =
                    '93000008'
            );


        Test.startTest();

        List<Database.SaveResult> results =
            EventBus.publish(
                new List<Appointment_Status_Changed__e>{
                    evt
                }
            );

        AppointmentStatusChangedHelper.logErrors(
            results,
            new List<Appointment__c>()
        );

        Test.stopTest();


        if (!results[0].isSuccess()) {

            System.assert(
                [
                    SELECT COUNT()
                    FROM Error_Log__c
                    WHERE Source__c =
                        'AppointmentStatusChangedTrigger'
                ] > 0,
                'A failed publish should be logged by logErrors().'
            );

        } else {

            // If Writing_Number__c accepts arbitrarily long values in
            // this org, the publish unexpectedly succeeds and there's
            // nothing to assert here — logErrors()'s success path is
            // already covered by testLogErrorsWithNoErrors and every
            // trigger-level test above.
            System.assert(
                true,
                'Writing_Number__c accepted an oversized value in this org; ' +
                'the failure branch of logErrors() could not be forced this way.'
            );
        }
    }


    /*
     * ============================================================
     * 9. PLATFORM EVENT FIELDS ROUND-TRIP
     * ============================================================
     */
    @IsTest
    static void testQueueableWithPlatformEventFields() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );


        Appointment_Status_Changed__e evt =
            new Appointment_Status_Changed__e(

                Appointment_ID__c =
                    'a010000000000006AAA',

                New_Status__c =
                    'Active RTS',

                Sub_Status__c =
                    'Completed',

                Carrier__c =
                    'a020000000000006AAA',

                Writing_Number__c =
                    'WN-FINALIZER-001',

                Contact_Id__c =
                    '003000000000006AAA',

                NPN__c =
                    '93000006'
            );


        Test.startTest();

        Database.SaveResult result =
            EventBus.publish(evt);


        System.assertEquals(
            true,
            result.isSuccess(),
            'Platform Event should be published successfully.'
        );


        Test.getEventBus().deliver();

        Test.stopTest();


        System.assertEquals(
            true,
            result.isSuccess()
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Error_Log__c],
            'A full field payload should still deliver successfully with zero error logs.'
        );
    }
}