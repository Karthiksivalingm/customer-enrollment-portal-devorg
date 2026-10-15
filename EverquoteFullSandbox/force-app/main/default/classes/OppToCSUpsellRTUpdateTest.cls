@isTest public class OppToCSUpsellRTUpdateTest {
    @isTest
    static void testOpportunityLegacyRecordTypeBatch() {
        List<RecordType> recordTypes = [SELECT Id, Name 
                                        FROM RecordType 
                                        WHERE SobjectType = 'Opportunity' AND Name='Cross-Sell'
                                       ];
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (RecordType rt : recordTypes) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + rt.Name,
                CloseDate = System.today().addDays(30),
                StageName = 'Prospecting', 
                RecordTypeId = rt.Id,
                Legacy_Record_Type__c = rt.Name
            );
            testOpportunities.add(opp);
        }
        insert testOpportunities;
        OppToCSUpsellRTUpdate batchClass = new OppToCSUpsellRTUpdate();
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }
}