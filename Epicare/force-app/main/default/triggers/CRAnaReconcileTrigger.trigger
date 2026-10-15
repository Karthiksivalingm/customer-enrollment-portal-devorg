trigger CRAnaReconcileTrigger on Commission_Record__c (after update) {
    CRAnaReconcileHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}