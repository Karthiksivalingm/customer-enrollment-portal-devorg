@isTest
public class ContactManualApproveControllerTest {

    @IsTest
    static void testApproveContactSuccess() {
        Contact c = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com'
        );
        insert c;

        Test.startTest();
        ContactManualApproveController.approveContact(c.Id, 'Approved');
        Test.stopTest();

        Contact updatedC = [SELECT Id, Manual_Approval_Status__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('Approved', updatedC.Manual_Approval_Status__c, 'Manual_Approval_Status__c field must be updated to "Approved"');
    }

    @IsTest
    static void testApproveContactNullId() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            ContactManualApproveController.approveContact(null, 'Rejected');
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'New AuraHandledException must be created');
    }
}