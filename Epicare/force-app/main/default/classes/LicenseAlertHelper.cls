public class LicenseAlertHelper {

    public static void logErrors(
        List<Database.SaveResult> results,
        List<DOI__c> dois
    ) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errorLogs.add(new Error_Log__c(
                        Event_Type__c    = 'License_Alert__e',
                        Error_Message__c = err.getMessage(),
                        Stack_Trace__c   = err.getMessage(),
                        Contact_ID__c    = dois[i].Contact__c,
                        Source__c        = 'LicenseAlertBatch',
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

    public static void sendToGoAMS(List<License_Alert__e> events) {
        System.enqueueJob(new GoAMSCallout(events, 0));
    }

    public class GoAMSCallout implements Queueable, Database.AllowsCallouts {

        private List<License_Alert__e> events;
        private Integer retryCount;

        public GoAMSCallout(List<License_Alert__e> events, Integer retryCount) {
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

            List<License_Alert__e> toRetry = new List<License_Alert__e>();
            for (License_Alert__e evt : events) {
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

                System.debug('LicenseAlertHelper OAuth failed — HTTP '
                    + res.getStatusCode() + ': ' + res.getBody());
                return null;

            } catch (Exception e) {
                System.debug('LicenseAlertHelper OAuth exception: ' + e.getMessage()
                    + '\n' + e.getStackTraceString());
                return null;
            }
        }

        private Boolean postEvent(License_Alert__e evt, String accessToken) {
            // event_id: switched from evt.ReplayId to evt.EventUuid — see
            // note in the other GoAMS helper classes on why ReplayId doesn't
            // work reliably here.
            Map<String, Object> payload = new Map<String, Object>{
                'event_id'   => evt.EventUuid == null ? '' : evt.EventUuid,
                'contact_id' => evt.Contact_ID__c,
                'state'      => evt.State__c,
                'alert_type' => evt.Alert_Type__c,
                'alert_date' => evt.Alert_Date__c
            };
            String payloadJson = JSON.serialize(payload);
            System.debug('LicenseAlertHelper payload: ' + payloadJson);

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:EventAPI/sf-event-license-alert');
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
                        evt.Contact_ID__c,
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

        private void retryOrDeadLetterBatch(List<License_Alert__e> failedEvents, String reason) {
            if (retryCount < GoAMSRetryUtil.MAX_RETRIES) {
                Integer nextRetryCount = retryCount + 1;
                System.enqueueJob(
                    new GoAMSCallout(failedEvents, nextRetryCount),
                    GoAMSRetryUtil.backoffMinutes(nextRetryCount)
                );
            } else {
                for (License_Alert__e evt : failedEvents) {
                    logDeadLetter(
                        evt.Contact_ID__c,
                        reason + ' — max retries (' + GoAMSRetryUtil.MAX_RETRIES + ') exceeded'
                    );
                }
            }
        }

        private void logDeadLetter(String contactId, String message) {
            insert new Error_Log__c(
                Event_Type__c    = 'License_Alert__e',
                Error_Message__c = message,
                Contact_ID__c    = contactId,
                Source__c        = 'LicenseAlertHelper.GoAMSCallout',
                Severity__c      = 'High',
                Status__c        = 'Dead Letter',
                Retry_Count__c   = retryCount
            );
        }
    }

    public class GoAMSCalloutFinalizer implements System.Finalizer {

        private List<License_Alert__e> events;
        private Integer retryCount;

        public GoAMSCalloutFinalizer(List<License_Alert__e> events, Integer retryCount) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                List<Error_Log__c> logs = new List<Error_Log__c>();
                for (License_Alert__e evt : events) {
                    logs.add(new Error_Log__c(
                        Event_Type__c    = 'License_Alert__e',
                        Error_Message__c = 'Unhandled exception in GoAMSCallout Queueable: '
                            + ctx.getException().getMessage(),
                        Contact_ID__c    = evt.Contact_ID__c,
                        Source__c        = 'LicenseAlertHelper.GoAMSCallout.Finalizer',
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