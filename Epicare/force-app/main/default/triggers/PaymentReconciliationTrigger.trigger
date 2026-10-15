trigger PaymentReconciliationTrigger on Commission_Record__c (after insert) {
    PaymentReconciliationHandler.handleAfterInsert(Trigger.new);
}