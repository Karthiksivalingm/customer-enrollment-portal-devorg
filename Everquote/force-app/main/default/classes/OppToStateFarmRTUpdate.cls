global class OppToStateFarmRTUpdate implements Database.Batchable<sObject>, Database.Stateful {
    public Id acceleratedAGPRecordTypeId;

    global Database.QueryLocator start(Database.BatchableContext BC) 
    {        
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Accelerated-AGP' LIMIT 1];
        if (!recordTypes.isEmpty()) {
            acceleratedAGPRecordTypeId = recordTypes[0].Id;
        }
        
        return Database.getQueryLocator([
            							SELECT Id, RecordTypeId FROM Opportunity WHERE 
            							(
                                            (RecordType.Name = 'Accelerated' AND Legacy_Record_Type__c = 'Accelerated')
                                            OR
                                            (RecordType.Name = 'Accelerated-State Farm' AND Legacy_Record_Type__c = 'Accelerated-State Farm')
                                        )
                                        ]);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> records) 
    {
        for (Opportunity opp : records) 
        {
            opp.RecordTypeId = acceleratedAGPRecordTypeId;
        }
        update records;
    }

    global void finish(Database.BatchableContext BC) {
    }
}