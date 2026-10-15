public class AppointmentStatusChangedHelper {

    public static void logErrors(
        List<Database.SaveResult> results,
        List<Appointment__c> appointments
    ) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errorLogs.add(new Error_Log__c(
                        Event_Type__c    = 'Appointment_Status_Changed__e',
                        Error_Message__c = err.getMessage(),
                        Stack_Trace__c   = err.getMessage(),
                        Source__c        = 'AppointmentStatusChangedTrigger',
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
        List<Appointment_Status_Changed__e> events
    ) {
        System.enqueueJob(
            new GoAMSCallout(events, 0)
        );
    }

    public class GoAMSCallout
        implements Queueable, Database.AllowsCallouts {

        private List<Appointment_Status_Changed__e> events;
        private Integer retryCount;

        /*
         * Backward-compatible constructor.
         *
         * Existing classes/tests that use:
         * new GoAMSCallout(events)
         *
         * will continue to work without any test-class changes.
         */
        public GoAMSCallout(
            List<Appointment_Status_Changed__e> events
        ) {
            this(events, 0);
        }

        /*
         * Existing retry-aware constructor.
         */
        public GoAMSCallout(
            List<Appointment_Status_Changed__e> events,
            Integer retryCount
        ) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(QueueableContext ctx) {

            System.attachFinalizer(
                new GoAMSCalloutFinalizer(
                    events,
                    retryCount
                )
            );

            String accessToken = getAccessToken();

            if (accessToken == null) {
                retryOrDeadLetterBatch(
                    events,
                    'OAuth token request failed'
                );
                return;
            }

            List<Appointment_Status_Changed__e> toRetry =
                new List<Appointment_Status_Changed__e>();

            for (
                Appointment_Status_Changed__e evt : events
            ) {
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

                    Map<String, Object> jsonMap =
                        (Map<String, Object>)
                        JSON.deserializeUntyped(
                            res.getBody()
                        );

                    return (String) jsonMap.get(
                        'access_token'
                    );
                }

                System.debug(
                    'AppointmentStatusChangedHelper OAuth failed — HTTP '
                    + res.getStatusCode()
                    + ': '
                    + res.getBody()
                );

                return null;

            } catch (Exception e) {

                System.debug(
                    'AppointmentStatusChangedHelper OAuth exception: '
                    + e.getMessage()
                    + '\n'
                    + e.getStackTraceString()
                );

                return null;
            }
        }

        private Boolean postEvent(
            Appointment_Status_Changed__e evt,
            String accessToken
        ) {

            /*
             * event_id uses EventUuid because ReplayId is not
             * available as a normal accessible field on the
             * Platform Event SObject in this Queueable context.
             */
            Map<String, Object> payload =
                new Map<String, Object>{
                    'event_id' =>
                        evt.EventUuid == null
                        ? ''
                        : evt.EventUuid,

                    'appointment_id' =>
                        evt.Appointment_ID__c == null
                        ? ''
                        : evt.Appointment_ID__c,

                    'new_status' =>
                        evt.New_Status__c == null
                        ? ''
                        : evt.New_Status__c,

                    'carrier_id' =>
                        evt.Carrier__c == null
                        ? ''
                        : evt.Carrier__c,

                    'writing_number' =>
                        evt.Writing_Number__c == null
                        ? ''
                        : evt.Writing_Number__c,

                    'contact_id' =>
                        evt.Contact_Id__c == null
                        ? ''
                        : evt.Contact_Id__c,

                    'npn' =>
                        evt.NPN__c == null
                        ? ''
                        : evt.NPN__c
                };

            String payloadJson =
                JSON.serialize(payload);

            System.debug(
                'AppointmentStatusChangedHelper payload: '
                + payloadJson
            );

            try {

                HttpRequest req = new HttpRequest();

                req.setEndpoint(
                    'callout:EventAPI/sf-event-appointment-status-changed'
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
                        evt.Appointment_ID__c,
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
            List<Appointment_Status_Changed__e> failedEvents,
            String reason
        ) {

            if (
                retryCount <
                GoAMSRetryUtil.MAX_RETRIES
            ) {

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

                for (
                    Appointment_Status_Changed__e evt :
                    failedEvents
                ) {

                    logDeadLetter(
                        evt.Appointment_ID__c,
                        reason
                        + ' — max retries ('
                        + GoAMSRetryUtil.MAX_RETRIES
                        + ') exceeded'
                    );
                }
            }
        }

        /*
         * NOTE:
         * appointmentId is written to Error_Log__c.Contact_ID__c,
         * same as the existing implementation.
         */
        private void logDeadLetter(
            String appointmentId,
            String message
        ) {

            insert new Error_Log__c(
                Event_Type__c =
                    'Appointment_Status_Changed__e',

                Error_Message__c =
                    message,

                Contact_ID__c =
                    appointmentId,

                Source__c =
                    'AppointmentStatusChangedHelper.GoAMSCallout',

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

        private List<Appointment_Status_Changed__e> events;
        private Integer retryCount;

        public GoAMSCalloutFinalizer(
            List<Appointment_Status_Changed__e> events,
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

                for (
                    Appointment_Status_Changed__e evt :
                    events
                ) {

                    logs.add(
                        new Error_Log__c(
                            Event_Type__c =
                                'Appointment_Status_Changed__e',

                            Error_Message__c =
                                'Unhandled exception in '
                                + 'GoAMSCallout Queueable: '
                                + ctx.getException().getMessage(),

                            Contact_ID__c =
                                evt.Appointment_ID__c,

                            Source__c =
                                'AppointmentStatusChangedHelper.GoAMSCallout.Finalizer',

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
}