global class OppToCSUpsellRTUpdate implements Database.Batchable<sObject>, Database.Stateful {
    public Id CSUpsellRecordTypeId;

    global Database.QueryLocator start(Database.BatchableContext BC) 
    {        
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'CS Upsell' LIMIT 1];
        if (!recordTypes.isEmpty()) {
            CSUpsellRecordTypeId = recordTypes[0].Id;
        }
        
        return Database.getQueryLocator([SELECT Id, RecordTypeId 
                                         FROM Opportunity 
                                         WHERE(RecordType.Name = 'Cross-Sell' AND Legacy_Record_Type__c = 'Cross-Sell')]);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> records) 
    {
        for (Opportunity opp : records) 
        {
            opp.RecordTypeId = CSUpsellRecordTypeId;
        }
        update records;
    }

    global void finish(Database.BatchableContext BC) {
    }
}