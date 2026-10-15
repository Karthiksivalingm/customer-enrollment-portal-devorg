public with sharing class HeNotesRelatedListController {
    @AuraEnabled(cacheable=true)
    public static List<HE_Notes__c> getNotesByEvent(Id eventId) {
        return [
            SELECT Id, Name, HE_Request__c, HE_Request_Status__c, Feedback__c
            FROM HE_Notes__c
            WHERE Event_Id__c = :eventId
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Event getEventSubject(Id eventId) {
        return [SELECT Id, Subject FROM Event WHERE Id = :eventId LIMIT 1];
    }
}