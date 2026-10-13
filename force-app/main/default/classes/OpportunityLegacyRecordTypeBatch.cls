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