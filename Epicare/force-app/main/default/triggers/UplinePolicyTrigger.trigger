trigger UplinePolicyTrigger on Upline_Policy__c (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        UplinePolicyTriggerHandler.beforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        UplinePolicyToCommissionHandler.afterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        UplinePolicyToCommissionHandler.afterUpdate(Trigger.new);
    }
}