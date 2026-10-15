public with sharing class ContactEventsController {

    @AuraEnabled(cacheable=true)
    public static List<Event> getContactEvents(Id contactId) {
        return [
            SELECT 
                Id,
                Subject,
                StartDateTime,
                EndDateTime,
                Description,
                CRM_Notes__c,
                PA_Notes__c
            FROM Event
            WHERE WhoId = :contactId
            ORDER BY StartDateTime DESC
        ];
    }
}