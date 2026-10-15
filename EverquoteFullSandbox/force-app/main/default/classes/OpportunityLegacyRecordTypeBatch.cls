/*
global class OpportunityLegacyRecordTypeBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        return Database.getQueryLocator([SELECT Id, RecordType.Name, Legacy_Record_Type__c 
                                         FROM Opportunity 
                                         WHERE (
                                             (RecordType.Name = 'Agency CS Upsell' OR RecordType.Name = 'Cross-Sell' OR RecordType.Name = 'Accelerated') 
                                             AND Legacy_Record_Type__c = null
                                         )
                                        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> records) 
    {        
        for(Opportunity opp : records) 
        {
            opp.Legacy_Record_Type__c = opp.RecordType.Name;
        }
        update records;
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}
*/

/**********************************
Class Name    : OpportunityLegacyRecordTypeBatch
Description     : Batch that backfills Legacy_Record_Type__c on Opportunities whose RecordType is
                   Agency CS Upsell / Cross-Sell / Accelerated and that field is still blank.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.0                                                            Original implementation (see commented-out
                                                                block above).
1.1              (refactor)                                    Status of each flagged finding:
                                                                 - "DML statement inside a for/while loop" -
                                                                   NOT PRESENT. The for-loop only sets the
                                                                   field in memory; `update records;` already
                                                                   ran once, after the loop, on the whole
                                                                   chunk - i.e. the bulk pattern the
                                                                   recommendation asks for was already in
                                                                   place. No change needed for this finding.
                                                                 - "DML present but no try/catch error
                                                                   handling - unhandled DmlException surfaces
                                                                   raw errors or fails silently in async
                                                                   contexts" - FIXED. `update records;` is
                                                                   replaced with
                                                                   `Database.update(records, false)`
                                                                   (partial-success mode), so one record
                                                                   failing validation no longer aborts the
                                                                   whole chunk. Every failed row is logged
                                                                   (via logDmlErrors) with the record Id and
                                                                   error message instead of the exception
                                                                   propagating unhandled and failing the
                                                                   batch job silently.
                                                                 - logDmlErrors() currently logs via
                                                                   System.debug(LoggingLevel.ERROR, ...); if
                                                                   this org has a custom Error_Log__c object
                                                                   or an error-logging Platform Event, swap
                                                                   the body of that one method to write to it
                                                                   - the call site doesn't need to change.
                                                                All public method signatures are unchanged,
                                                                so OpportunityLegacyRecordTypeBatchTest
                                                                continues to work; a new test was added to
                                                                cover the partial-failure path specifically.
***********************************/
global class OpportunityLegacyRecordTypeBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, RecordType.Name, Legacy_Record_Type__c
            FROM Opportunity
            WHERE (
                (RecordType.Name = 'Agency CS Upsell' OR RecordType.Name = 'Cross-Sell' OR RecordType.Name = 'Accelerated')
                AND Legacy_Record_Type__c = null
            )
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> records) {
        for (Opportunity opp : records) {
            opp.Legacy_Record_Type__c = opp.RecordType.Name;
        }

        // Partial-success mode: a validation-rule failure on one record no longer throws an
        // unhandled DmlException that would abort every other record in this chunk.
        List<Database.SaveResult> saveResults = Database.update(records, false);
        logDmlErrors(records, saveResults);
    }

    global void finish(Database.BatchableContext BC) {
    }

    /**
     * Logs every failed SaveResult with the related record Id and error message(s), so a failed
     * update is visible instead of being silently swallowed in this async (batch) context.
     * Swap the body of this method to write to a custom Error_Log__c record or publish a
     * Platform Event if this org has one - the call site in execute() does not need to change.
     */
    private void logDmlErrors(List<Opportunity> records, List<Database.SaveResult> saveResults) {
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult sr = saveResults[i];
            if (!sr.isSuccess()) {
                List<String> errorMessages = new List<String>();
                for (Database.Error err : sr.getErrors()) {
                    errorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                }
                System.debug(
                    LoggingLevel.ERROR,
                    'OpportunityLegacyRecordTypeBatch: failed to update Opportunity ' +
                        records[i].Id + ' - ' + String.join(errorMessages, '; ')
                );
            }
        }
    }
}