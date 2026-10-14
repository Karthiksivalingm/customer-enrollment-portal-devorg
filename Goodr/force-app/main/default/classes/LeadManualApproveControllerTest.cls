@isTest
public class LeadManualApproveControllerTest {

    /*@IsTest
    static void testApproveLead_Approved() {
        Lead l = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Tax_ID__c = '123456789',
            Status = 'New',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;

        Test.startTest();
        LeadManualApproveController.approveLead(l.Id, 'Approved');
        Test.stopTest();

        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :l.Id];
        System.assertEquals(
            'Qualified',
            updatedLead.Status,
            'Status should be set to Qualified when action = Approved'
        );
    }

    @IsTest
    static void testApproveLead_Rejected() {
        Lead l = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'New',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;

        Test.startTest();
        LeadManualApproveController.approveLead(l.Id, 'Rejected');
        Test.stopTest();

        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :l.Id];
        System.assertEquals(
            'Manual Rejection',
            updatedLead.Status,
            'Status should be set to Manual Rejection when action = Rejected'
        );
    }*/

    @IsTest
    static void testApproveLead_InvalidAction() {
        Lead l = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'New',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert l;

        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            LeadManualApproveController.approveLead(l.Id, 'Something');
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception should be thrown for invalid action');
    }

    @IsTest
    static void testApproveLeadNullId() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            LeadManualApproveController.approveLead(null, 'Approved');
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception should be thrown when Lead Id is null');
    }
}