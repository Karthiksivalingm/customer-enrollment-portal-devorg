trigger AgentCreatedTrigger on Contact (after insert) {
    List<Agent_Created__e> events = new List<Agent_Created__e>();
   
    for (Contact c : Trigger.new) {
        if (c.RecordTypeId == AgentCreatedHelper.AGENT_RECORD_TYPE_ID) {
            events.add(new Agent_Created__e(
                Contact_ID__c  = c.Id,
                Agency_ID__c   = c.AccountId,
                Record_Type__c = 'Agent'
            ));
        }
    }
    
    if (!events.isEmpty()) {
        try {
          
            List<Database.SaveResult> results = EventBus.publish(events);
            AgentCreatedHelper.logErrors(results, Trigger.new);
        } catch (Exception e) {
            insert new Error_Log__c(
                Event_Type__c    = 'Agent_Created__e',
                Error_Message__c = e.getMessage(),
                Stack_Trace__c   = e.getStackTraceString(),
                Source__c        = 'AgentCreatedTrigger',
                Severity__c      = 'High',
                Status__c        = 'New'
            );
        }
    }
}