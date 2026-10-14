@isTest
public class AccNoteUpdateController_Test {

    static Account testMthd(){
        Account acc = new Account();
        acc.Notes__c = 'Note';
        acc.Name ='test';
             
        insert acc;
        AccNoteUpdateController.getEntity(acc.Id);
        AccNoteUpdateController.saveData(acc.Id,acc.Notes__c );
        return acc;
    }
    
      static testMethod void testCallout(){
    	Account acctToCreate = testMthd();
    	Test.startTest();
    	Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
    	Test.stopTest();
  	}

}