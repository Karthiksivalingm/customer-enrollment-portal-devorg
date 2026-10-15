/**
 * Package 3.5 — 12-hour bidirectional reconciliation (Sec. 9.4 / 9.4.1)
 *
 * Matches Commission_Record__c against GO AMS commission data on
 * Policy_Number__c + Payment_Period__c + Agent_Code__c.
 *
 * Commission & financial data is SF-source-of-truth (9.4.1): on a
 * mismatch this batch NEVER overwrites the SF record. It only sets
 * Recon_Status__c and raises a Security_Incident__c
 * (Detection_Method__c = 'Sync_Discrepancy') for review.
 *
 * Amount comparison uses Gross_Amount__c (see class header history /
 * chat for why, not Chargeback/Expected/Net).
 *
 * RETRY BEHAVIOR (new): if the GO AMS callout or OAuth handshake
 * fails with a RETRYABLE condition (5xx, timeout, null/malformed
 * response — same classification as GoAMSRetryUtil.isRetryableStatus,
 * reused from the event-subscriber helpers), this batch reschedules
 * ITSELF via System.scheduleBatch with the same backoff schedule as
 * every other GoAMS integration point (2/4/6 min, capped at
 * GoAMSRetryUtil.MAX_RETRIES=3) instead of waiting for the next
 * 12-hour cycle. A 4xx (bad request/payload) is NOT retried — that's
 * a defect in the request itself, not a transient outage, and just
 * dead-letters to Error_Log__c immediately, same as the other helpers.
 * After MAX_RETRIES is exhausted, it also dead-letters and waits for
 * the next scheduled 2AM/2PM run.
 *
 * Recon_Status__c is a restricted picklist field on Commission_Record__c
 * (Recon_Status__c.field-meta.xml), modeled on the Detection_Method__c
 * pattern.
 *
 * Data mismatches log to Security_Incident__c using Affected_Object__c
 * (object API name) + Description__c (mismatch detail, including the
 * record Id since there's no dedicated related-record-Id field).
 *
 * KNOWN DEPENDENCY (Package 5, tracked separately): Agent_Code__c is
 * populated on only 1 of 243 Contacts today. Records whose
 * Agent_Code__c can't be resolved are tagged Unmatched - No Agent
 * Code rather than silently skipped.
 *
 * TODO before deploy — still unconfirmed:
 *   READ_PATH: exact GO AMS edge function path for reading commission
 *   data. Placeholder below follows the existing
 *   'sf-event-agent-created' naming convention — confirm the real path.
 */
public with sharing class CommissionReconciliationEngine {

 /*paste this loine above :  implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful    
// TODO: confirm real path with GO AMS / integration doc
    private static final String READ_PATH = 'callout:EventAPI/sf-read-commissions';
    private static final Integer SCOPE_SIZE = 50;

    private static final String STATUS_MATCHED          = 'Matched';
    private static final String STATUS_DISCREPANCY       = 'Discrepancy';
    private static final String STATUS_NO_MATCH          = 'No Match Found';
    private static final String STATUS_UNMATCHED_AGENT   = 'Unmatched - No Agent Code';
    private static final String STATUS_INTEGRATION_ERROR = 'Integration Error - Not Reconciled';

    public Integer recordsProcessed = 0;
    public Integer discrepanciesRaised = 0;

    // Retry state — carried across a chain of self-scheduled reruns,
    // NOT across separate 2AM/2PM cycles (those always start at 0).
    private Integer retryCount;
    private Boolean hadRetryableFailure = false;

    public CommissionReconciliationEngine() {
        this(0);
    }

    public CommissionReconciliationEngine(Integer retryCount) {
        this.retryCount = retryCount;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Policy_Number__c, Payment_Period__c, Recon_Status__c,
                   Gross_Amount__c,
                   Agent__r.Agent_Code__c
            FROM Commission_Record__c
            WHERE Policy_Number__c != null
              AND Payment_Period__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Commission_Record__c> scope) {
        List<Commission_Record__c> toUpdate = new List<Commission_Record__c>();
        List<Security_Incident__c> incidentsToInsert = new List<Security_Incident__c>();
        List<Commission_Record__c> matchable = new List<Commission_Record__c>();

        for (Commission_Record__c cr : scope) {
            if (String.isBlank(cr.Agent__r?.Agent_Code__c)) {
                cr.Recon_Status__c = STATUS_UNMATCHED_AGENT;
                toUpdate.add(cr);
            } else {
                matchable.add(cr);
            }
        }

        if (!matchable.isEmpty()) {
            TokenResult tokenResult = getAccessToken();

            if (tokenResult.accessToken == null) {
                logErrorLog(
                    'CommissionReconciliationEngine',
                    'OAuth token request failed — chunk of ' + matchable.size()
                        + ' records skipped for this run (retryCount=' + retryCount + ')'
                );
                if (tokenResult.retryable) {
                    hadRetryableFailure = true;
                }
                for (Commission_Record__c cr : matchable) {
                    cr.Recon_Status__c = STATUS_INTEGRATION_ERROR;
                    toUpdate.add(cr);
                }
            } else {
                FetchResult fetchResult = fetchGoAmsCommissions(matchable, tokenResult.accessToken);

                if (fetchResult.data == null) {
                    if (fetchResult.retryable) {
                        hadRetryableFailure = true;
                    }
                    for (Commission_Record__c cr : matchable) {
                        cr.Recon_Status__c = STATUS_INTEGRATION_ERROR;
                        toUpdate.add(cr);
                    }
                } else {
                    for (Commission_Record__c cr : matchable) {
                        String key = buildKey(cr.Policy_Number__c, cr.Payment_Period__c, cr.Agent__r.Agent_Code__c);
                        GoAmsCommissionRecord goAmsRecord = fetchResult.data.get(key);

                        if (goAmsRecord == null) {
                            cr.Recon_Status__c = STATUS_NO_MATCH;
                            incidentsToInsert.add(buildIncident(cr, 'No matching GO AMS record found for key ' + key));
                        } else if (!amountsMatch(cr.Gross_Amount__c, goAmsRecord.amount)) {
                            // SF wins per 9.4.1 — cr.Gross_Amount__c is never touched.
                            cr.Recon_Status__c = STATUS_DISCREPANCY;
                            incidentsToInsert.add(buildIncident(
                                cr,
                                'Gross amount mismatch for key ' + key +
                                ' — SF=' + cr.Gross_Amount__c + ', GO AMS=' + goAmsRecord.amount +
                                '. SF value retained per 9.4.1 (SF source of truth).'
                            ));
                        } else {
                            cr.Recon_Status__c = STATUS_MATCHED;
                        }
                        toUpdate.add(cr);
                    }
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        if (!incidentsToInsert.isEmpty()) {
            insert incidentsToInsert;
            discrepanciesRaised += incidentsToInsert.size();
        }
        recordsProcessed += scope.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'CommissionReconciliationEngine finished. retryCount=' + retryCount +
            ', processed=' + recordsProcessed +
            ', discrepancies/no-match incidents raised=' + discrepanciesRaised +
            ', hadRetryableFailure=' + hadRetryableFailure);

        if (!hadRetryableFailure) {
            return;
        }

        if (retryCount < GoAMSRetryUtil.MAX_RETRIES) {
            Integer nextRetryCount = retryCount + 1;
            Integer delayMinutes = GoAMSRetryUtil.backoffMinutes(nextRetryCount);
            String jobName = 'CommissionRecon Retry ' + nextRetryCount + ' ' + System.now().getTime();
            System.scheduleBatch(
                new CommissionReconciliationEngine(nextRetryCount),
                jobName,
                delayMinutes,
                SCOPE_SIZE
            );
        } else {
            logErrorLog(
                'CommissionReconciliationEngine',
                'Max retries (' + GoAMSRetryUtil.MAX_RETRIES + ') exceeded — dead-lettering '
                    + 'until the next scheduled 2AM/2PM run'
            );
        }
    }

    // ---------------------------------------------------------------
    // GO AMS OAuth + callout — mirrors AgentCreatedHelper.GoAMSCallout
    // ---------------------------------------------------------------

    private TokenResult getAccessToken() {
        TokenResult result = new TokenResult();
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
                result.accessToken = (String) json.get('access_token');
                return result;
            }

            System.debug('CommissionReconciliationEngine OAuth failed — HTTP '
                + res.getStatusCode() + ': ' + res.getBody());
            result.retryable = GoAMSRetryUtil.isRetryableStatus(res.getStatusCode());
            return result;

        } catch (Exception e) {
            System.debug('CommissionReconciliationEngine OAuth exception: ' + e.getMessage()
                + '\n' + e.getStackTraceString());
            // Timeouts/connection errors have no status code — treat as retryable,
            // same convention as GoAMSRetryUtil's null-status handling.
            result.retryable = true;
            return result;
        }
    }

    private FetchResult fetchGoAmsCommissions(List<Commission_Record__c> matchable, String accessToken) {
        FetchResult result = new FetchResult();
        Set<String> policyNumbers = new Set<String>();
        for (Commission_Record__c cr : matchable) {
            policyNumbers.add(cr.Policy_Number__c);
        }

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(READ_PATH + '?policy_numbers=' + EncodingUtil.urlEncode(
                String.join(new List<String>(policyNumbers), ','), 'UTF-8'));
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeout(30000);

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                logErrorLog(
                    'CommissionReconciliationEngine',
                    'GoAMS commission read failed — HTTP ' + res.getStatusCode() + ': ' + res.getBody()
                );
                result.retryable = GoAMSRetryUtil.isRetryableStatus(res.getStatusCode());
                return result;
            }

            Map<String, GoAmsCommissionRecord> data = new Map<String, GoAmsCommissionRecord>();
            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(res.getBody());
            for (Object o : rawList) {
                Map<String, Object> row = (Map<String, Object>) o;
                GoAmsCommissionRecord rec = new GoAmsCommissionRecord();
                rec.policyNumber = (String) row.get('policy_number');
                rec.paymentPeriod = (String) row.get('payment_period');
                rec.agentCode = (String) row.get('agent_code');
                rec.amount = (Decimal) row.get('amount');

                data.put(buildKey(rec.policyNumber, rec.paymentPeriod, rec.agentCode), rec);
            }
            result.data = data;
            return result;

        } catch (Exception e) {
            logErrorLog(
                'CommissionReconciliationEngine',
                'GoAMS commission read exception: ' + e.getMessage() + '\n' + e.getStackTraceString()
            );
            result.retryable = true;
            return result;
        }
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private String buildKey(String policyNumber, String paymentPeriod, String agentCode) {
        return String.valueOf(policyNumber).trim().toUpperCase() + '|' +
               String.valueOf(paymentPeriod).trim().toUpperCase() + '|' +
               String.valueOf(agentCode).trim().toUpperCase();
    }

    private Boolean amountsMatch(Decimal sfAmount, Decimal goAmsAmount) {
        if (sfAmount == null && goAmsAmount == null) return true;
        if (sfAmount == null || goAmsAmount == null) return false;
        return (sfAmount - goAmsAmount).abs() < 0.01;
    }

    private Security_Incident__c buildIncident(Commission_Record__c cr, String details) {
        return new Security_Incident__c(
            Detection_Method__c = 'Sync_Discrepancy',
            Affected_Object__c = 'Commission_Record__c',
            Description__c = 'Commission_Record__c Id: ' + cr.Id + ' — ' + details
        );
    }

    private void logErrorLog(String source, String message) {
        insert new Error_Log__c(
            Event_Type__c    = 'Commission_Reconciliation',
            Error_Message__c = message,
            Source__c        = source,
            Severity__c      = 'High',
            Status__c        = 'New'
        );
    }

    private class TokenResult {
        String accessToken;
        Boolean retryable = false;
    }

    private class FetchResult {
        Map<String, GoAmsCommissionRecord> data;
        Boolean retryable = false;
    }

    private class GoAmsCommissionRecord {
        String policyNumber;
        String paymentPeriod;
        String agentCode;
        Decimal amount;
    }*/
}