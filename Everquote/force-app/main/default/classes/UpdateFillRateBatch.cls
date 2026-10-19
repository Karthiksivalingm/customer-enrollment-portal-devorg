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