public inherited sharing class AccountManualApproveController {

    @AuraEnabled
    public static void approveAccount(Id accountId, String statusValue) {
        if (accountId == null) {
            throw new AuraHandledException('AccountId is required.');
        }
        Account acc = [SELECT Id, Manual_Approval_Status__c FROM Account WHERE Id = :accountId LIMIT 1];
        acc.Manual_Approval_Status__c = statusValue;
        update acc;
    }
}