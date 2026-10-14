trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContactTriggerHandler.handleAfterInsert(Trigger.new);
        } 
        if (Trigger.isUpdate) {
            ContactTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ContactTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            ContactTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}