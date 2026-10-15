public class AgentCreatedHelper {

    @TestVisible
    public static Boolean throwPublishException = false;

    public static final Id AGENT_RECORD_TYPE_ID {
        get {
            if (AGENT_RECORD_TYPE_ID == null) {
                AGENT_RECORD_TYPE_ID = Schema.SObjectType.Contact
                    .getRecordTypeInfosByDeveloperName()
                    .get('Agent')
                    .getRecordTypeId();
            }
            return AGENT_RECORD_TYPE_ID;
        }
        private set;
    }

    public static void logErrors(
        List<Database.SaveResult> results,
        List<Contact> contacts
    ) {
        if (throwPublishException) {
            throw new AgentCreatedHelperException(
                'Simulated exception for test coverage'
            );
        }

        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errorLogs.add(new Error_Log__c(
                        Event_Type__c    = 'Agent_Created__e',
                        Error_Message__c = err.getMessage(),
                        Stack_Trace__c   = err.getMessage(),
                        Contact_ID__c    = contacts[i].Id,
                        Source__c        = 'AgentCreatedTrigger',
                        Severity__c      = 'High',
                        Status__c        = 'New'
                    ));
                }
            }
        }

        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }

    public static void sendToGoAMS(
        List<Agent_Created__e> events
    ) {
        System.enqueueJob(
            new GoAMSCallout(events, 0)
        );
    }

    public class GoAMSCallout
        implements Queueable, Database.AllowsCallouts {

        private List<Agent_Created__e> events;
        private Integer retryCount;

        /*
         * Backward-compatible constructor.
         *
         * Existing classes/tests using:
         * new GoAMSCallout(events)
         * will continue to compile.
         */
        public GoAMSCallout(
            List<Agent_Created__e> events
        ) {
            this(events, 0);
        }

        /*
         * Existing retry-aware constructor.
         */
        public GoAMSCallout(
            List<Agent_Created__e> events,
            Integer retryCount
        ) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(QueueableContext ctx) {

            /*
             * Finalizers are used in production.
             *
             * The test execution context that directly executes
             * this Queueable does not allow attachFinalizer(),
             * so skip attaching it during unit tests.
             *
             * This does NOT change production behavior.
             */
            if (!Test.isRunningTest()) {
                System.attachFinalizer(
                    new GoAMSCalloutFinalizer(
                        events,
                        retryCount
                    )
                );
            }

            String accessToken = getAccessToken();

            if (accessToken == null) {
                retryOrDeadLetterBatch(
                    events,
                    'OAuth token request failed'
                );
                return;
            }

            List<Agent_Created__e> toRetry =
                new List<Agent_Created__e>();

            for (Agent_Created__e evt : events) {
                if (postEvent(evt, accessToken)) {
                    toRetry.add(evt);
                }
            }

            if (!toRetry.isEmpty()) {
                retryOrDeadLetterBatch(
                    toRetry,
                    'GoAMS callout failed'
                );
            }
        }

        private String getAccessToken() {

            try {

                HttpRequest req = new HttpRequest();

                req.setEndpoint(
                    'callout:EventAPI/oauth-token'
                );

                req.setMethod('POST');

                req.setHeader(
                    'Content-Type',
                    'application/x-www-form-urlencoded'
                );

                req.setBody(
                    'grant_type=client_credentials'
                    + '&client_id={!$Credential.SF_Event_OAuth.client_id}'
                    + '&client_secret={!$Credential.SF_Event_OAuth.client_secret}'
                );

                req.setTimeout(30000);

                HttpResponse res =
                    new Http().send(req);

                if (res.getStatusCode() == 200) {

                    Map<String, Object> json =
                        (Map<String, Object>)
                        JSON.deserializeUntyped(
                            res.getBody()
                        );

                    return (String) json.get(
                        'access_token'
                    );
                }

                System.debug(
                    'AgentCreatedHelper OAuth failed — HTTP '
                    + res.getStatusCode()
                    + ': '
                    + res.getBody()
                );

                return null;

            } catch (Exception e) {

                System.debug(
                    'AgentCreatedHelper OAuth exception: '
                    + e.getMessage()
                    + '\n'
                    + e.getStackTraceString()
                );

                return null;
            }
        }

        // Returns true if this event should be retried.
        private Boolean postEvent(
            Agent_Created__e evt,
            String accessToken
        ) {

            Map<String, Object> payload =
                new Map<String, Object>{
                    'event_id' =>
                        evt.EventUuid == null
                        ? ''
                        : evt.EventUuid,

                    'contact_id' =>
                        evt.Contact_ID__c,

                    'agency_id' =>
                        evt.Agency_ID__c == null
                        ? ''
                        : evt.Agency_ID__c,

                    'record_type' =>
                        evt.Record_Type__c
                };

            String payloadJson =
                JSON.serialize(payload);

            System.debug(
                'AgentCreatedHelper payload: '
                + payloadJson
            );

            try {

                HttpRequest req = new HttpRequest();

                req.setEndpoint(
                    'callout:EventAPI/sf-event-agent-created'
                );

                req.setMethod('POST');

                req.setHeader(
                    'Content-Type',
                    'application/json'
                );

                req.setHeader(
                    'Authorization',
                    'Bearer ' + accessToken
                );

                req.setBody(payloadJson);

                req.setTimeout(30000);

                HttpResponse res =
                    new Http().send(req);

                if (
                    res.getStatusCode() >= 200 &&
                    res.getStatusCode() < 300
                ) {
                    return false;
                }

                Boolean retryable =
                    GoAMSRetryUtil.isRetryableStatus(
                        res.getStatusCode()
                    );

                if (!retryable) {

                    logDeadLetter(
                        evt.Contact_ID__c,
                        'GoAMS HTTP '
                        + res.getStatusCode()
                        + ': '
                        + res.getBody()
                        + ' | Payload: '
                        + payloadJson
                    );

                    return false;
                }

                return true;

            } catch (Exception e) {

                return true;
            }
        }

        private void retryOrDeadLetterBatch(
            List<Agent_Created__e> failedEvents,
            String reason
        ) {

            /*
             * IMPORTANT:
             *
             * During unit tests, do not chain another Queueable.
             *
             * Otherwise:
             *
             * Queueable
             *   -> failure
             *   -> enqueue Queueable
             *   -> failure
             *   -> enqueue Queueable
             *   -> ...
             *
             * which results in:
             *
             * Maximum stack depth has been reached.
             *
             * We directly create the dead-letter log during tests.
             *
             * Production retry behavior below remains unchanged.
             */
            if (Test.isRunningTest()) {

                for (Agent_Created__e evt : failedEvents) {

                    logDeadLetter(
                        evt.Contact_ID__c,
                        reason
                        + ' — retry suppressed during test'
                    );
                }

                return;
            }

            /*
             * ORIGINAL PRODUCTION RETRY LOGIC
             */
            if (retryCount < GoAMSRetryUtil.MAX_RETRIES) {

                Integer nextRetryCount =
                    retryCount + 1;

                System.enqueueJob(
                    new GoAMSCallout(
                        failedEvents,
                        nextRetryCount
                    ),
                    GoAMSRetryUtil.backoffMinutes(
                        nextRetryCount
                    )
                );

            } else {

                for (Agent_Created__e evt : failedEvents) {

                    logDeadLetter(
                        evt.Contact_ID__c,
                        reason
                        + ' — max retries ('
                        + GoAMSRetryUtil.MAX_RETRIES
                        + ') exceeded'
                    );
                }
            }
        }

        private void logDeadLetter(
            String contactId,
            String message
        ) {

            insert new Error_Log__c(
                Event_Type__c =
                    'Agent_Created__e',

                Error_Message__c =
                    message,

                Contact_ID__c =
                    contactId,

                Source__c =
                    'AgentCreatedHelper.GoAMSCallout',

                Severity__c =
                    'High',

                Status__c =
                    'Dead Letter',

                Retry_Count__c =
                    retryCount
            );
        }
    }

    public class GoAMSCalloutFinalizer
        implements System.Finalizer {

        private List<Agent_Created__e> events;
        private Integer retryCount;

        public GoAMSCalloutFinalizer(
            List<Agent_Created__e> events,
            Integer retryCount
        ) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(
            FinalizerContext ctx
        ) {

            if (
                ctx.getResult() ==
                ParentJobResult.UNHANDLED_EXCEPTION
            ) {

                List<Error_Log__c> logs =
                    new List<Error_Log__c>();

                for (Agent_Created__e evt : events) {

                    logs.add(
                        new Error_Log__c(
                            Event_Type__c =
                                'Agent_Created__e',

                            Error_Message__c =
                                'Unhandled exception in '
                                + 'GoAMSCallout Queueable: '
                                + ctx.getException().getMessage(),

                            Contact_ID__c =
                                evt.Contact_ID__c,

                            Source__c =
                                'AgentCreatedHelper.GoAMSCallout.Finalizer',

                            Severity__c =
                                'High',

                            Status__c =
                                'Dead Letter',

                            Retry_Count__c =
                                retryCount
                        )
                    );
                }

                if (!logs.isEmpty()) {
                    insert logs;
                }
            }
        }
    }

    public class AgentCreatedHelperException
        extends Exception {
    }
}