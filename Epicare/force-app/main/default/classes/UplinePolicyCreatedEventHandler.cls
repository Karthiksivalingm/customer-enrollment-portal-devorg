/**
 * Subscriber for Upline_Policy_Created__e. Builds and inserts the
 * Commission_Record__c that used to be created synchronously inside
 * UplinePolicyToCommissionHandler.afterInsert. Because this now runs in
 * a separate transaction (fired after the publishing transaction commits),
 * a validation failure here — e.g. CommissionRecordTriggerHandler's
 * "Cancelled Still Paid" hard reject — can no longer roll back the
 * original Upline_Policy__c insert.
 *
 * No status filtering: a Commission_Record__c is attempted for every
 * event regardless of Status__c, same as the original behavior. If
 * validation rejects a row, the existing exception-logging path
 * (Commission_Exception_Event__e / Commission_Exception__c) still runs
 * exactly as it does today — CommissionRecordTriggerHandler's addError()
 * calls fire per-record on the way in, before Database.insert resolves,
 * so that logging is unaffected by the change below.
 *
 * Uses Database.insert(..., false) instead of a plain insert, so one bad
 * row in the batch (e.g. a Cancelled/Term policy that gets hard-rejected)
 * doesn't block the other rows in the same event batch from saving.
 *
 * Event fields are all Text, so numeric/date/Id fields are parsed back
 * to their real types here.
 */
public with sharing class UplinePolicyCreatedEventHandler {

    public static void handleAfterInsert(List<Upline_Policy_Created__e> events) {
        List<Commission_Record__c> commissionsToInsert = new List<Commission_Record__c>();
        // Parallel list so a failed SaveResult can be traced back to the
        // Upline_Policy__c Id it came from, for debug logging.
        List<Id> uplinePolicyIdsForInsert = new List<Id>();

        for (Upline_Policy_Created__e evt : events) {
            try {
                Commission_Record__c comm = new Commission_Record__c();
                comm.Upline_Policy__c  = (Id) evt.Upline_Policy__c;
                comm.Agent_Code__c     = evt.Agent_Code__c;
                comm.Agent__c          = String.isNotBlank(evt.Agent__c) ? (Id) evt.Agent__c : null;
                comm.Agency__c         = String.isNotBlank(evt.Agency__c) ? (Id) evt.Agency__c : null;
                comm.Carrier__c        = String.isNotBlank(evt.Carrier__c) ? (Id) evt.Carrier__c : null;
                comm.Policy_Number__c  = evt.Policy_Number__c;
                comm.Effective_Date__c = String.isNotBlank(evt.Effective_Date__c)
                                            ? Date.valueOf(evt.Effective_Date__c)
                                            : null;
                comm.Premium__c        = String.isNotBlank(evt.Premium__c)
                                            ? Decimal.valueOf(evt.Premium__c)
                                            : null;
                comm.Policy_Year__c    = String.isNotBlank(evt.Policy_Year__c)
                                            ? Decimal.valueOf(evt.Policy_Year__c)
                                            : null;
                comm.MBI__c            = evt.MBI__c;
                comm.Upline_Source__c  = evt.Upline_Source__c;

                commissionsToInsert.add(comm);
                uplinePolicyIdsForInsert.add((Id) evt.Upline_Policy__c);
            } catch (Exception ex) {
                // Malformed event payload (bad Id/date/number text) — log
                // and skip this one record rather than losing the whole batch.
                System.debug(LoggingLevel.ERROR,
                    'UplinePolicyCreatedEventHandler: failed to parse event for '
                    + 'Upline_Policy__c=' + evt.Upline_Policy__c + ' — ' + ex.getMessage());
            }
        }

        if (commissionsToInsert.isEmpty()) {
            return;
        }

        List<Database.SaveResult> results = Database.insert(commissionsToInsert, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.WARN,
                        'UplinePolicyCreatedEventHandler: Commission_Record__c insert failed for '
                        + 'Upline_Policy__c=' + uplinePolicyIdsForInsert[i]
                        + ' — ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }
}