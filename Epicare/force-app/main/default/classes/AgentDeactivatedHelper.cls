public class AgentDeactivatedHelper {

    public static void logErrors(
        List<Database.SaveResult> results,
        List<Contact> contacts
    ) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errorLogs.add(new Error_Log__c(
                        Event_Type__c    = 'Agent_Deactivated__e',
                        Error_Message__c = err.getMessage(),
                        Stack_Trace__c   = err.getMessage(),
                        Contact_ID__c    = contacts[i].Id,
                        Source__c        = 'AgentDeactivatedTrigger',
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

    public static void logTriggerError(Exception e) {
        insert new Error_Log__c(
            Event_Type__c    = 'Agent_Deactivated__e',
            Error_Message__c = e.getMessage(),
            Stack_Trace__c   = e.getStackTraceString(),
            Source__c        = 'AgentDeactivatedTrigger',
            Severity__c      = 'High',
            Status__c        = 'New'
        );
    }

    public static void sendToGoAMS(List<Agent_Deactivated__e> events) {
        System.enqueueJob(new GoAMSCallout(events, 0));
    }

    public class GoAMSCallout implements Queueable, Database.AllowsCallouts {

        private List<Agent_Deactivated__e> events;
        private Integer retryCount;

        public GoAMSCallout(List<Agent_Deactivated__e> events, Integer retryCount) {
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

            List<Agent_Deactivated__e> toRetry = new List<Agent_Deactivated__e>();
            for (Agent_Deactivated__e evt : events) {
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
                    Map<String, Object> json =
                        (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    return (String) json.get('access_token');
                }

                System.debug('AgentDeactivatedHelper OAuth failed — HTTP '
                    + res.getStatusCode() + ': ' + res.getBody());
                return null;

            } catch (Exception e) {
                System.debug('AgentDeactivatedHelper OAuth exception: ' + e.getMessage()
                    + '\n' + e.getStackTraceString());
                return null;
            }
        }

        private Boolean postEvent(Agent_Deactivated__e evt, String accessToken) {
            Map<String, Object> payload = new Map<String, Object>{
                'event_id'   => evt.EventUuid == null ? '' : evt.EventUuid,
                'contact_id' => evt.Contact_ID__c == null ? '' : evt.Contact_ID__c,
                'agency_id'  => evt.Agency_ID__c == null ? '' : evt.Agency_ID__c,
                'new_status' => evt.New_Status__c == null ? '' : evt.New_Status__c,
                'reason'     => evt.Reason__c == null ? '' : evt.Reason__c
            };
            String payloadJson = JSON.serialize(payload);
            System.debug('AgentDeactivatedHelper payload: ' + payloadJson);

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:EventAPI/sf-event-agent-deactivated');
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

        private void retryOrDeadLetterBatch(List<Agent_Deactivated__e> failedEvents, String reason) {
            if (retryCount < GoAMSRetryUtil.MAX_RETRIES) {
                Integer nextRetryCount = retryCount + 1;
                System.enqueueJob(
                    new GoAMSCallout(failedEvents, nextRetryCount),
                    GoAMSRetryUtil.backoffMinutes(nextRetryCount)
                );
            } else {
                for (Agent_Deactivated__e evt : failedEvents) {
                    logDeadLetter(
                        evt.Contact_ID__c,
                        reason + ' — max retries (' + GoAMSRetryUtil.MAX_RETRIES + ') exceeded'
                    );
                }
            }
        }

        private void logDeadLetter(String contactId, String message) {
            insert new Error_Log__c(
                Event_Type__c    = 'Agent_Deactivated__e',
                Error_Message__c = message,
                Contact_ID__c    = contactId,
                Source__c        = 'AgentDeactivatedHelper.GoAMSCallout',
                Severity__c      = 'High',
                Status__c        = 'Dead Letter',
                Retry_Count__c   = retryCount
            );
        }
    }

    public class GoAMSCalloutFinalizer implements System.Finalizer {

        private List<Agent_Deactivated__e> events;
        private Integer retryCount;

        public GoAMSCalloutFinalizer(List<Agent_Deactivated__e> events, Integer retryCount) {
            this.events = events;
            this.retryCount = retryCount;
        }

        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                List<Error_Log__c> logs = new List<Error_Log__c>();
                for (Agent_Deactivated__e evt : events) {
                    logs.add(new Error_Log__c(
                        Event_Type__c    = 'Agent_Deactivated__e',
                        Error_Message__c = 'Unhandled exception in GoAMSCallout Queueable: '
                            + ctx.getException().getMessage(),
                        Contact_ID__c    = evt.Contact_ID__c,
                        Source__c        = 'AgentDeactivatedHelper.GoAMSCallout.Finalizer',
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