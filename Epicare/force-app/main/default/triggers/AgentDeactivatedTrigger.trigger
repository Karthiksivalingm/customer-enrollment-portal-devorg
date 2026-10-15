trigger AgentDeactivatedTrigger on Contact (after update) {
    List<Agent_Deactivated__e> events = new List<Agent_Deactivated__e>();
    List<Contact> deactivatedContacts = new List<Contact>();
    
    Set<String> deactivatedStatuses = new Set<String>{'Terminated', 'Suspended'};
    
    for (Contact c : Trigger.new) {
        Contact oldC = Trigger.oldMap.get(c.Id);
        
        if (c.RecordTypeId == AgentCreatedHelper.AGENT_RECORD_TYPE_ID
            && c.Agent_Status__c != oldC.Agent_Status__c
            && deactivatedStatuses.contains(c.Agent_Status__c)) {
                
            events.add(new Agent_Deactivated__e(
                Contact_ID__c = c.Id,
                New_Status__c = c.Agent_Status__c,
                Reason__c     = c.Deactivation_Reason__c
            ));
            deactivatedContacts.add(c);
        }
    }
    
    if (!events.isEmpty()) {
        try {
            List<Database.SaveResult> results = EventBus.publish(events);
            AgentDeactivatedHelper.logErrors(results, deactivatedContacts);
        } catch (Exception e) {
            AgentDeactivatedHelper.logTriggerError(e);
        }
    }
}