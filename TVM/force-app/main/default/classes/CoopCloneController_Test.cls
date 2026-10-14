@isTest
public class CoopCloneController_Test {
  
    public static void testmtd(){
        RecordType accRT = [SELECT Id  FROM RecordType  WHERE SObjectType = 'Account' AND DeveloperName = 'Foundation_Dealership' LIMIT 1 ];
        Account acc = new Account(
            Name = 'Test Account',
            RecordTypeId = accRT.Id
        );
        insert acc;
        //customLookUpController.fetchLookUpValues('test','Account');
    }
     @IsTest
    static void testUpdate() {
        testmtd();
        Test.startTest();
        customLookUpController.fetchLookUpValues('test','Account');
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
    }
    
}