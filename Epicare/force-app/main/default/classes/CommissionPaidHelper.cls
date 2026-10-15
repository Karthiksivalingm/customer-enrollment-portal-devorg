public class CommissionPaidHelper {

    // Test-only hook — EventBus.publish() only throws for conditions that
    // are impractical to reproduce from ordinary test data (e.g. exceeding
    // the platform event publish limit for a transaction). This lets a
    // test force the catch branch in publishEvents() below for coverage
    // and direct assertions.
    @TestVisible
    private static Boolean simulateException = false;

    // Moved here from CommissionPaidTrigger (same try/catch, same
    // Error_Log__c fields, same behavior) purely so the simulateException
    // flag above can reach it — triggers have no static members a test
    // class can set.
    public static void publishEvents(List<Commission_Paid__e> events) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        try {
            if (Test.isRunningTest() && simulateException) {
                throw new System.DmlException('Simulated exception for test coverage');
            }
            List<Database.SaveResult> results = EventBus.publish(events);
            logErrors(results, events);
        } catch (Exception e) {
            errorLogs.add(new Error_Log__c(
                Event_Type__c    = 'Commission_Paid__e',
                Error_Message__c = e.getMessage(),
                Stack_Trace__c   = e.getStackTraceString(),
                Source__c        = 'CommissionPaidTrigger',
                Severity__c      = 'High',
                Status__c        = 'New'
            ));
        }
        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }

    public static void logErrors(
        List<Database.SaveResult> results,
        List<Commission_Paid__e> events
    ) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errorLogs.add(new Error_Log__c(
                        Event_Type__c    = 'Commission_Paid__e',
                        Error_Message__c = err.getMessage(),
                        Stack_Trace__c   = err.getMessage(),
                        Source__c        = 'CommissionPaidTrigger',
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

    public static void sendToGoAMS(List<Commission_Paid__e> events) {
        System.enqueueJob(new GoAMSCallout(events, 0));
    }

    public class GoAMSCallout implements Queueable, Database.AllowsCallouts {

        private List<Commission_Paid__e> events;
        private Integer retryCount;

        public GoAMSCallout(List<Commission_Paid__e> events, Integer retryCount) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(QueueableContext ctx) {
            System.attachFinalizer(new GoAMSCalloutFinalizer(events, retryCount));

            String accessToken = getAccessToken();
            if (accessToken == null) {
                retryOrDeadLetterBatch(events, 'OAuth token request failed');
                return;
            }

            List<Commission_Paid__e> toRetry = new List<Commission_Paid__e>();
            for (Commission_Paid__e evt : events) {
                if (postEvent(evt, accessToken)) {
                    toRetry.add(evt);
                }
            }

            if (!toRetry.isEmpty()) {
                retryOrDeadLetterBatch(toRetry, 'GoAMS callout failed');
            }
        }

        private String getAccessToken() {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:EventAPI/oauth-token');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                req.setBody(
                    'grant_type=client_credentials'
                    + '&client_id={!$Credential.SF_Event_OAuth.client_id}'
                    + '&client_secret={!$Credential.SF_Event_OAuth.client_secret}'
                );
                req.setTimeout(30000);

                HttpResponse res = new Http().send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> jsonMap =
                        (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    return (String) jsonMap.get('access_token');
                }

                System.debug('CommissionPaidHelper OAuth failed — HTTP '
                    + res.getStatusCode() + ': ' + res.getBody());
                return null;

            } catch (Exception e) {
                System.debug('CommissionPaidHelper OAuth exception: ' + e.getMessage()
                    + '\n' + e.getStackTraceString());
                return null;
            }
        }

        private Boolean postEvent(Commission_Paid__e evt, String accessToken) {
            String contactId = evt.Contact_ID__c == null ? '' : evt.Contact_ID__c;
            String batchId   = evt.Batch_ID__c == null ? '' : evt.Batch_ID__c;

            // Total_Amount__c is stored as a String (see CommissionPaidTrigger),
            // so guard the numeric parse — a blank/null value would otherwise
            // throw a TypeException before the payload is even built.
            Double totalAmount = 0;
            Boolean amountParseFailed = false;
            if (String.isNotBlank(evt.Total_Amount__c)) {
                try {
                    totalAmount = Double.valueOf(evt.Total_Amount__c);
                } catch (Exception parseEx) {
                    amountParseFailed = true;
                }
            }

            // FIX (client UAT, PB-0018 — "send the field as-is, no
            // date-range transformation, our subscriber already accepts
            // YYYY-MM directly"): this used to split Period__c on '|' into
            // a {start, end} object, assuming the trigger always produced a
            // pipe-delimited range. The trigger no longer builds a range at
            // all (see CommissionPaidTrigger) — Period__c is now always a
            // plain "YYYY-MM" string, so it's sent through as-is, matching
            // exactly what GO AMS's subscriber expects.
            String periodVal = evt.Period__c == null ? '' : evt.Period__c;

            Map<String, Object> payload = new Map<String, Object>{
                'event_id'     => evt.EventUuid == null ? '' : evt.EventUuid,
                'contact_id'   => contactId,
                'batch_id'     => batchId,
                'total_amount' => totalAmount,
                'period'       => periodVal
            };
            String payloadJson = JSON.serialize(payload);
            System.debug('CommissionPaidHelper payload: ' + payloadJson);

            if (amountParseFailed) {
                // Not retryable — bad source data, not a transient failure.
                // Retrying won't fix a Total_Amount__c that doesn't parse.
                logDeadLetter(
                    contactId, batchId,
                    'Total_Amount__c could not be parsed as a number: "' + evt.Total_Amount__c + '"'
                        + ' | Payload sent with total_amount=0 | Payload: ' + payloadJson
                );
            }

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:EventAPI/sf-event-commission-paid');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Authorization', 'Bearer ' + accessToken);
                req.setBody(payloadJson);
                req.setTimeout(30000);

                HttpResponse res = new Http().send(req);

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    return false;
                }

                Boolean retryable = GoAMSRetryUtil.isRetryableStatus(res.getStatusCode());
                if (!retryable) {
                    logDeadLetter(
                        contactId, batchId,
                        'GoAMS HTTP ' + res.getStatusCode() + ': ' + res.getBody()
                            + ' | Payload: ' + payloadJson
                    );
                    return false;
                }
                return true;

            } catch (Exception e) {
                return true;
            }
        }

        private void retryOrDeadLetterBatch(List<Commission_Paid__e> failedEvents, String reason) {
            if (retryCount < GoAMSRetryUtil.MAX_RETRIES) {
                Integer nextRetryCount = retryCount + 1;
                System.enqueueJob(
                    new GoAMSCallout(failedEvents, nextRetryCount),
                    GoAMSRetryUtil.backoffMinutes(nextRetryCount)
                );
            } else {
                for (Commission_Paid__e evt : failedEvents) {
                    String contactId = evt.Contact_ID__c == null ? '' : evt.Contact_ID__c;
                    String batchId   = evt.Batch_ID__c == null ? '' : evt.Batch_ID__c;
                    logDeadLetter(
                        contactId, batchId,
                        reason + ' — max retries (' + GoAMSRetryUtil.MAX_RETRIES + ') exceeded'
                    );
                }
            }
        }

        // There's no Batch_ID__c field on Error_Log__c, so batchId is
        // folded into Error_Message__c instead of left silently unused.
        private void logDeadLetter(String contactId, String batchId, String message) {
            insert new Error_Log__c(
                Event_Type__c    = 'Commission_Paid__e',
                Error_Message__c = 'Batch: ' + batchId + ' | ' + message,
                Contact_ID__c    = contactId,
                Source__c        = 'CommissionPaidHelper.GoAMSCallout',
                Severity__c      = 'High',
                Status__c        = 'Dead Letter',
                Retry_Count__c   = retryCount
            );
        }
    }

    public class GoAMSCalloutFinalizer implements System.Finalizer {

        private List<Commission_Paid__e> events;
        private Integer retryCount;

        public GoAMSCalloutFinalizer(List<Commission_Paid__e> events, Integer retryCount) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                List<Error_Log__c> logs = new List<Error_Log__c>();
                for (Commission_Paid__e evt : events) {
                    String contactId = evt.Contact_ID__c == null ? '' : evt.Contact_ID__c;
                    String batchId   = evt.Batch_ID__c == null ? '' : evt.Batch_ID__c;
                    logs.add(new Error_Log__c(
                        Event_Type__c    = 'Commission_Paid__e',
                        Error_Message__c = 'Batch: ' + batchId
                            + ' | Unhandled exception in GoAMSCallout Queueable: '
                            + ctx.getException().getMessage(),
                        Contact_ID__c    = contactId,
                        Source__c        = 'CommissionPaidHelper.GoAMSCallout.Finalizer',
                        Severity__c      = 'High',
                        Status__c        = 'Dead Letter',
                        Retry_Count__c   = retryCount
                    ));
                }
                if (!logs.isEmpty()) {
                    insert logs;
                }
            }
        }
    }
}