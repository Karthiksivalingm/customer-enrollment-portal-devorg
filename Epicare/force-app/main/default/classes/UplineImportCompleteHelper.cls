public class UplineImportCompleteHelper {

    public static void logErrors(
        List<Database.SaveResult> results,
        List<Upline_Policy_Import_Completed__e> events
    ) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errorLogs.add(new Error_Log__c(
                        Event_Type__c    = 'Upline_Policy_Import_Completed__e',
                        Error_Message__c = err.getMessage(),
                        Stack_Trace__c   = err.getMessage(),
                        Source__c        = 'UplineImportCompleteTrigger',
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

    public static void sendToGoAMS(List<Upline_Policy_Import_Completed__e> events) {
        System.enqueueJob(new GoAMSCallout(events, 0));
    }

    public class GoAMSCallout implements Queueable, Database.AllowsCallouts {

        private List<Upline_Policy_Import_Completed__e> events;
        private Integer retryCount;

        public GoAMSCallout(List<Upline_Policy_Import_Completed__e> events, Integer retryCount) {
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

            List<Upline_Policy_Import_Completed__e> toRetry = new List<Upline_Policy_Import_Completed__e>();
            for (Upline_Policy_Import_Completed__e evt : events) {
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

                System.debug('UplineImportCompleteHelper OAuth failed — HTTP '
                    + res.getStatusCode() + ': ' + res.getBody());
                return null;

            } catch (Exception e) {
                System.debug('UplineImportCompleteHelper OAuth exception: ' + e.getMessage()
                    + '\n' + e.getStackTraceString());
                return null;
            }
        }

        private Boolean postEvent(Upline_Policy_Import_Completed__e evt, String accessToken) {
            Map<String, Object> payload = new Map<String, Object>{
                'event_id'        => evt.EventUuid == null ? '' : evt.EventUuid,
                'import_log_id'   => evt.Import_Log_ID__c,
                'source'          => evt.Source__c,
                'report_type'     => evt.Report_Type__c,
                'records_created' => evt.Records_Created__c != null
                                    ? Integer.valueOf(evt.Records_Created__c) : 0,
                'records_updated' => evt.Records_Updated__c != null
                                    ? Integer.valueOf(evt.Records_Updated__c) : 0,
                'at_risk_count'   => evt.At_Risk_Count__c != null
                                    ? Integer.valueOf(evt.At_Risk_Count__c) : 0
            };
            String payloadJson = JSON.serialize(payload);
            System.debug('UplineImportCompleteHelper payload: ' + payloadJson);

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:EventAPI/sf-event-upline-policy-import-completed');
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
                        evt.Import_Log_ID__c,
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

        private void retryOrDeadLetterBatch(
            List<Upline_Policy_Import_Completed__e> failedEvents,
            String reason
        ) {
            if (retryCount < GoAMSRetryUtil.MAX_RETRIES) {
                Integer nextRetryCount = retryCount + 1;
                System.enqueueJob(
                    new GoAMSCallout(failedEvents, nextRetryCount),
                    GoAMSRetryUtil.backoffMinutes(nextRetryCount)
                );
            } else {
                for (Upline_Policy_Import_Completed__e evt : failedEvents) {
                    logDeadLetter(
                        evt.Import_Log_ID__c,
                        reason + ' — max retries (' + GoAMSRetryUtil.MAX_RETRIES + ') exceeded'
                    );
                }
            }
        }

        private void logDeadLetter(String importLogId, String message) {
            insert new Error_Log__c(
                Event_Type__c    = 'Upline_Policy_Import_Completed__e',
                Error_Message__c = message,
                Source__c        = 'UplineImportCompleteHelper.GoAMSCallout',
                Severity__c      = 'High',
                Status__c        = 'Dead Letter',
                Retry_Count__c   = retryCount
            );
        }
    }

    public class GoAMSCalloutFinalizer implements System.Finalizer {

        private List<Upline_Policy_Import_Completed__e> events;
        private Integer retryCount;

        public GoAMSCalloutFinalizer(List<Upline_Policy_Import_Completed__e> events, Integer retryCount) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                List<Error_Log__c> logs = new List<Error_Log__c>();
                for (Upline_Policy_Import_Completed__e evt : events) {
                    logs.add(new Error_Log__c(
                        Event_Type__c    = 'Upline_Policy_Import_Completed__e',
                        Error_Message__c = 'Unhandled exception in GoAMSCallout Queueable: '
                            + ctx.getException().getMessage(),
                        Source__c        = 'UplineImportCompleteHelper.GoAMSCallout.Finalizer',
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