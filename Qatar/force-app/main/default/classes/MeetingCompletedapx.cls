public class MeetingCompletedapx {

    public static void meetcomplt(Id ids) {
        // Create and insert a new Minutes_Of_Meeting__c record
        Meetings__c mm=[select name from Meetings__c where id=:ids];
        Minutes_Of_Meeting__c m = new Minutes_Of_Meeting__c();
        m.Meeting_Allocation__c = ids;
        m.Name=mm.name;
        insert m;

        // Fetch and update Agenda__c records
        List<Agenda__c> agendasToUpdate = new List<Agenda__c>();
        List<Agenda__c> agendas = [SELECT Minutes_Of_Meeting__c, Meetings__c FROM Agenda__c WHERE Meetings__c = :ids];
        for (Agenda__c ag : agendas) {
            ag.Minutes_Of_Meeting__c = m.Id;
            agendasToUpdate.add(ag);
        }

        // Fetch and update Action_Item__c records
        List<Action_Item__c> actionItemsToUpdate = new List<Action_Item__c>();
        List<Action_Item__c> actionItems = [SELECT Minutes_Of_Meeting__c, Meetings__c FROM Action_Item__c WHERE Meetings__c = :ids];
        for (Action_Item__c ai : actionItems) {
            ai.Minutes_Of_Meeting__c = m.Id;
            actionItemsToUpdate.add(ai);
        }

        // Perform the update operations outside the loops
        if (!agendasToUpdate.isEmpty()) {
            update agendasToUpdate;
        }

        if (!actionItemsToUpdate.isEmpty()) {
            update actionItemsToUpdate;
        }
    }
}