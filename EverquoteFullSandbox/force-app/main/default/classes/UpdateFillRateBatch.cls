/*
global class UpdateFillRateBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Uncapped_Fill_Rate__c, Low_Fill_Rate_Alert__c
            FROM Account
            WHERE Uncapped_Fill_Rate__c != NULL
            OR Low_Fill_Rate_Alert__c =TRUE
        ]);
    }
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        for (Account acc : scope) {
            if(acc.Uncapped_Fill_Rate__c!=Null)
                acc.Uncapped_Fill_Rate__c = null;
            if(acc.Low_Fill_Rate_Alert__c)
                acc.Low_Fill_Rate_Alert__c = false;
        }
        update scope;
    }
    global void finish(Database.BatchableContext BC) {
    }
}
*/
/**
 * @description Batch class that resets Fill Rate related fields on Account records.
 * Clears Uncapped_Fill_Rate__c and turns off Low_Fill_Rate_Alert__c for every
 * Account where either field currently holds a value.
 */
global class UpdateFillRateBatch implements Database.Batchable<SObject> {

    /**
     * @description Gathers all Account records that need their Fill Rate fields reset.
     * @param bc The batchable context provided by the platform.
     * @return A QueryLocator for the Accounts to process.
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Uncapped_Fill_Rate__c, Low_Fill_Rate_Alert__c
            FROM Account
            WHERE Uncapped_Fill_Rate__c != NULL
            OR Low_Fill_Rate_Alert__c = TRUE
        ]);
    }

    /**
     * @description Resets the Fill Rate fields for each Account in scope and saves the
     * changes. Uses a partial-success update so a failure on one record does not
     * prevent the rest of the chunk from being updated, and logs any failures.
     * @param bc The batchable context provided by the platform.
     * @param scope The list of Account records for the current batch chunk.
     */
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            if (acc.Uncapped_Fill_Rate__c != null) {
                acc.Uncapped_Fill_Rate__c = null;
            }
            if (acc.Low_Fill_Rate_Alert__c) {
                acc.Low_Fill_Rate_Alert__c = false;
            }
        }

        List<Database.SaveResult> saveResults = Database.update(scope, false);
        for (Integer i = 0; i < saveResults.size(); i++) {
            if (!saveResults.get(i).isSuccess()) {
                for (Database.Error err : saveResults.get(i).getErrors()) {
                    System.debug(
                        LoggingLevel.ERROR,
                        'UpdateFillRateBatch failed to update Account Id: ' + scope.get(i).Id +
                        ' - ' + err.getStatusCode() + ': ' + err.getMessage()
                    );
                }
            }
        }
    }

    /**
     * @description Logs the outcome of the batch run for monitoring purposes once
     * all chunks have completed processing.
     * @param bc The batchable context provided by the platform.
     */
    global void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        System.debug(
            LoggingLevel.INFO,
            'UpdateFillRateBatch finished with status: ' + job.Status +
            ', Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems +
            ', Errors: ' + job.NumberOfErrors
        );
    }
}