public with sharing class ContactManualApproveController {

    @AuraEnabled
    public static void approveContact(Id contactId, String statusValue) {
        if (contactId == null) {
            throw new AuraHandledException('ContactId is required.');
        }
        Contact c = [SELECT Id, Manual_Approval_Status__c FROM Contact WHERE Id = :contactId LIMIT 1];
        c.Manual_Approval_Status__c = statusValue;
        update c;
    }
}