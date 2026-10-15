@isTest public class OpportunityLegacyRecordTypeBatchTest {

    @isTest
    static void testOpportunityLegacyRecordTypeBatch() {
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Opportunity' AND Name IN ('Agency CS Upsell', 'Cross-Sell', 'Accelerated')];
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (RecordType rt : recordTypes) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + rt.Name,
                CloseDate = System.today().addDays(30),
                StageName = 'Prospecting', 
                RecordTypeId = rt.Id,
                Legacy_Record_Type__c = null
            );
            testOpportunities.add(opp);
        }
        insert testOpportunities;
        OpportunityLegacyRecordTypeBatch batchClass = new OpportunityLegacyRecordTypeBatch();
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
        List<Opportunity> updatedOpportunities = [SELECT Id, Legacy_Record_Type__c FROM Opportunity WHERE Id IN :testOpportunities];
    }
}