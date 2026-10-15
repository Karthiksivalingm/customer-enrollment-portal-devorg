public with sharing class ActionItemController {

    // Wrapper to flatten nested relationship field for LWC
    public class ActionItemWrapper {
        @AuraEnabled public String  recordId;
        @AuraEnabled public String  name;
        @AuraEnabled public String  eventName;
        @AuraEnabled public String  eventId;
        @AuraEnabled public String  momId;
        @AuraEnabled public String  momSubject;   // flattened from Minutes_of_Meeting__r.Subject__c
        @AuraEnabled public String  actionItem;
        @AuraEnabled public String  status;
        @AuraEnabled public String  notes;
        @AuraEnabled public String  createdDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<ActionItemWrapper> getActionItems(String eventId) {
        String eventId15 = eventId != null && eventId.length() >= 15 ? eventId.substring(0, 15) : eventId;
        Set<Id> aiIds = new Set<Id>();

        for (Action_Item__c ai : [
            SELECT Id FROM Action_Item__c
            WHERE Event_Id__c LIKE :('%' + eventId15 + '%')
        ]) { aiIds.add(ai.Id); }

        for (Action_Item__c ai : [
            SELECT Id FROM Action_Item__c
            WHERE Minutes_of_Meeting__r.Event_Id__c LIKE :('%' + eventId15 + '%')
        ]) { aiIds.add(ai.Id); }

        if (aiIds.isEmpty()) return new List<ActionItemWrapper>();

        List<Action_Item__c> records = [
            SELECT Id, Name, Event_Name__c, Event_Id__c,
                   Minutes_of_Meeting__c,
                   Minutes_of_Meeting__r.Subject__c,
                   Action_Item__c, Status__c, Notes__c, CreatedDate
            FROM Action_Item__c
            WHERE Id IN :aiIds
            ORDER BY CreatedDate DESC
        ];

        List<ActionItemWrapper> wrappers = new List<ActionItemWrapper>();
        for (Action_Item__c r : records) {
            ActionItemWrapper w = new ActionItemWrapper();
            w.recordId   = r.Id;
            w.name       = r.Name;
            w.eventName  = r.Event_Name__c;
            w.eventId    = r.Event_Id__c;
            w.momId      = r.Minutes_of_Meeting__c;
            // Flatten nested relationship field into a simple String
            w.momSubject = r.Minutes_of_Meeting__r != null ? r.Minutes_of_Meeting__r.Subject__c : '—';
            w.actionItem = r.Action_Item__c;
            w.status     = r.Status__c;
            w.notes      = r.Notes__c;
            w.createdDate = r.CreatedDate != null ? String.valueOf(r.CreatedDate) : '';
            wrappers.add(w);
        }
        return wrappers;
    }

    @AuraEnabled
    public static Action_Item__c createActionItem(String momId, String actionItem, String status, String notes) {
        Minutes_of_Meeting__c mom = [
            SELECT Id, Event_Id__c, Event_Name__c
            FROM Minutes_of_Meeting__c WHERE Id = :momId LIMIT 1
        ];
        Action_Item__c ai = new Action_Item__c();
        ai.Minutes_of_Meeting__c = momId;
        ai.Event_Id__c           = mom.Event_Id__c;
        ai.Event_Name__c         = mom.Event_Name__c;
        ai.Action_Item__c        = actionItem;
        ai.Status__c             = status;
        ai.Notes__c              = notes;
        insert ai;
        return ai;
    }

    @AuraEnabled
    public static void deleteActionItem(String recordId) {
        delete [SELECT Id FROM Action_Item__c WHERE Id = :recordId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry e : Action_Item__c.Status__c.getDescribe().getPicklistValues()) {
            if (e.isActive()) values.add(e.getValue());
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<Minutes_of_Meeting__c> getMOMsForEvent(String eventId) {
        return [
            SELECT Id, Name, Subject__c, Event_Id__c, Event_Name__c
            FROM Minutes_of_Meeting__c
            WHERE Event_Id__c = :eventId
            ORDER BY CreatedDate DESC
        ];
    }
}