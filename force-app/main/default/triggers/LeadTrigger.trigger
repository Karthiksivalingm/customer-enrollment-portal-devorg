trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LeadTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            LeadTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            // FIX: Removed checkIfEarlyStagesFilled from before insert
            // Validation now fires only when Status changes to Qualified (before update)
            LeadTriggerHandler.setLeadSources(Trigger.new);
            LeadTriggerHandler.setStateToStateCode(Trigger.new);
            LeadTriggerHandler.removeSymbolsFromTaxId(Trigger.new);
        }
        if (Trigger.isUpdate) {
            LeadTriggerHandler.handleBeforeUpdate(Trigger.new);
            // FIX: Added validation here — fires only when Status changes to Qualified
            LeadTriggerHandler.checkIfEarlyStagesFilled(Trigger.new, Trigger.oldMap);
        }
    }
}