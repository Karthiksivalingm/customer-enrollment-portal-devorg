public with sharing class CreditRequestController {
    @AuraEnabled(cacheable=true)
    public static List<Credit_Request__c> getApprovedRequests() {
        return [
            SELECT Id, Name, Credit_Request_Status__c, Total_Amount_Requested__c, CreatedDate 
            FROM Credit_Request__c 
            WHERE Credit_Request_Status__c = 'Approved'
            ORDER BY CreatedDate DESC
        ];
    }
}