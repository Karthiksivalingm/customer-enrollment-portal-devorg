@isTest
public class BulkAccountLastOppUpdateTest {
    @TestSetup
    static void createTestData() {
        Carrier__c car = new Carrier__c();
        car.Name = 'test';
        insert car;
        Account acc = new Account();
        acc.Name = 'testName1';
        acc.Last_Opportunity_was_Close_Lost__c = false;
        acc.Carrier__c = car.Id;
        insert acc;
        system.debug('acc****'+acc);
        Opportunity o = new Opportunity();
        o.Name = 'testOpp';
        o.AccountId = acc.Id;
        //o.RecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        o.CloseDate = System.today().addMonths(1);
        o.StageName = 'Open';
        o.LeadSource = 'Outbound Call';
        insert o;
        system.debug('o****'+o);
    }
    
    @isTest
    static void testLoadData() {
		Opportunity opp = [SELECT Id,StageName FROM Opportunity  ];
        opp.StageName = 'Closed Lost';
        update opp;
        Account acc = [SELECT Id,Last_Opportunity_was_Close_Lost__c FROM Account];
        acc.Last_Opportunity_was_Close_Lost__c = false;
        update acc;
        Test.startTest();
        BulkAccountLastOppUpdate ba= new BulkAccountLastOppUpdate();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    } 
}