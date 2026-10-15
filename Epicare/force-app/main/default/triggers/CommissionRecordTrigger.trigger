trigger CommissionRecordTrigger on Commission_Record__c (before insert, before update) {

    CommissionRecordTriggerHandler.beforeSave(Trigger.new);

    // Rollup Payment Batch totals
    CommissionPaymentBatchRollupHandler.updatePaymentBatchTotals(Trigger.new);
}