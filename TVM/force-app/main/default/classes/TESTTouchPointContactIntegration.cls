@isTest
public class TESTTouchPointContactIntegration {
	
    static Contact getTestContact(){
    	Contact conToCreate = new Contact();
        
        conToCreate.FirstName = 'Test';
        conToCreate.LastName = 'Contact';
        conToCreate.Quickbase_Record_ID__c  = '100078';
        conToCreate.Phone = '3333333333';
       
        insert conToCreate;
        
        conToCreate.Phone = '4444444444';
        update conToCreate;
        
        return conToCreate;
  	}
    
    static testMethod void testCallout(){
    	Contact conToCreate = getTestContact();
    	Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
    	Test.stopTest();
  	}
}