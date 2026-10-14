@isTest
public class TESTTouchPointAutoGroupIntegration {
    
    static Auto_Group__c getTestAutoGroup(){
    	Auto_Group__c agToCreate = new Auto_Group__c();
        
        agToCreate.Name = 'Test Auto Group';
        agToCreate.Quickbase_Record_ID__c  = '100076';
        agToCreate.Main_Phone__c = '1235550001';      
       
        insert agToCreate;
        
        agToCreate.Main_Phone__c = '1235550002';
        update agToCreate;
        
        return agToCreate;
  	}
    
    static testMethod void testCallout(){
    	Auto_Group__c agToCreate = getTestAutoGroup();
    	Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
    	Test.stopTest();
  	}
}