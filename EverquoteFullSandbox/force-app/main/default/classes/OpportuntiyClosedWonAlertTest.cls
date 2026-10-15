@isTest
public class OpportuntiyClosedWonAlertTest {

    @TestSetup
	static void createTestData() {
     RecordType contactType =    [select id,DeveloperName from RecordType where SobjectType = 'Contact' AND DeveloperName = 'Agency'];

   Contact con = new Contact(lastName = 'test',RecordTypeId = contactType.Id,Email = 'test@test.com');
        insert con;
}
    
    @isTest
    static void sendEmailAlertTest() {
        List<Id> lstOfIds = new List<Id>();
        for(Contact con: [SELECT Id FROM Contact]){
            lstOfIds.add(con.Id);
        }
        Test.StartTest();
        
        OpportuntiyClosedWonAlert.sendEmailAlert(lstOfIds);
        
        Test.stopTest();
    } 
}