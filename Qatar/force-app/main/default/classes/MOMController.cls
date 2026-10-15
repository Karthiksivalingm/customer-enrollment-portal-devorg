public with sharing class MOMController {

    @AuraEnabled(cacheable=true)
    public static List<Minutes_Of_Meeting__c> getMOMRecords(String eventId) {
        return [
            SELECT Id, Name, Event_Name__c, Subject__c, Comments__c, Event_Id__c, CreatedDate
            FROM Minutes_Of_Meeting__c
            WHERE Event_Id__c = :eventId
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void deleteMOM(String momId) {
        Minutes_Of_Meeting__c mom = [SELECT Id FROM Minutes_Of_Meeting__c WHERE Id = :momId LIMIT 1];
        delete mom;
    }

    @AuraEnabled(cacheable=true)
    public static Event getEventDetails(String eventId) {
        return [SELECT Id, Subject, ActivityDateTime FROM Event WHERE Id = :eventId LIMIT 1];
    }
}