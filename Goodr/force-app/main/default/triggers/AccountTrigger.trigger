trigger AccountTrigger on Account (after insert, after update, after delete, before insert, before update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AccountTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            AccountTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AccountTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AccountTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}