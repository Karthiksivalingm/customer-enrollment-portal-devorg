trigger ProgramBundleAssociationTrigger on Program_Bundle_Associations__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ProgramBundleAssociationTriggerHandler.handleAfterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        ProgramBundleAssociationTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}