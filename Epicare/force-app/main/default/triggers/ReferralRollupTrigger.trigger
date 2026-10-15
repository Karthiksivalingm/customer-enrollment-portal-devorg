trigger ReferralRollupTrigger on Commission_Record__c (after insert, after update) {
    ReferralRollupHandler.handleTrigger(Trigger.new, Trigger.isInsert, Trigger.isUpdate, Trigger.oldMap);
}