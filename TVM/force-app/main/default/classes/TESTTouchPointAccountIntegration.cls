@isTest
public class TESTTouchPointAccountIntegration {
    
    static Account getTestAccount(){
    	Account acctToCreate = new Account();
        
        acctToCreate.Name = 'Test Account';
        acctToCreate.Quickbase_Record_ID__c  = '100077';
        acctToCreate.Phone = '3335551234';
        acctToCreate.Client_Team__c = 'a2tVb0000001CtZIAU';
        //acctToCreate.OEM_Enrolled_Approved_Bundle__c = true;
       
        insert acctToCreate;
        
        acctToCreate.Phone = '3335551233';
        
        update acctToCreate;
        
        return acctToCreate;
  	}
    
    static testMethod void testCallout(){
    	Account acctToCreate = getTestAccount();
    	Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
    	Test.stopTest();
  	}
}