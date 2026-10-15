trigger OrderChangeTrigger on uLab_Order__c (after insert, after update) {

    if(Trigger.isAfter && Trigger.isInsert)
        ULabOrderStatusKPIHandler.handleAfterInsert(Trigger.new);

    if(Trigger.isAfter && Trigger.isUpdate)
        ULabOrderStatusKPIHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);

    if(Trigger.isAfter && Trigger.isUpdate)
        OrderChangeHandler.handleAfterUpdate(Trigger.new, Trigger.old);

}