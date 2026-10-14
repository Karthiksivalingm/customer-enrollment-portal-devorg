@isTest
public class TESTTouchPointBudgetIntegration {
    
    static Monthly_Budget__c getTestBudget(){
      Monthly_Budget__c budgetToCreate = new Monthly_Budget__c();
        
        budgetToCreate.Name = 'DEC2022';
        budgetToCreate.Quickbase_Record_ID__c  = '59109';
        budgetToCreate.Account__c = '0015f00000ROyEzAAL';
       
        upsert budgetToCreate;

        budgetToCreate.Name = 'JAN2023';
        
        update budgetToCreate;
        
        return budgetToCreate;
    }
    
    static testMethod void testCallout(){
      Monthly_Budget__c budgetToCreate = getTestBudget();
      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
      Test.stopTest();
    }
}