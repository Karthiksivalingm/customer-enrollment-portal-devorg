@isTest
public class AccountManualApproveControllerTest {

    @IsTest
    static void testApproveAccountSuccess() {
        String franchiseId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchise').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', Tax_Id__c = 'test', RecordTypeId = franchiseId);
        insert acc;

        Test.startTest();
        AccountManualApproveController.approveAccount(acc.Id, 'Approved');
        Test.stopTest();

        Account updatedAcc = [SELECT Id, Manual_Approval_Status__c,sales_Channel__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Approved', updatedAcc.Manual_Approval_Status__c, 
            'Manual_Approval_Status__c field must be updated to "Approved"');
    }
    
    @IsTest
    static void testApproveAccountNullId() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            AccountManualApproveController.approveAccount(null, 'Rejected');
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'New AuraHandledException must be created');
    }
}