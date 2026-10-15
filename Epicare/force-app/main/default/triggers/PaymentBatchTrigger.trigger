trigger PaymentBatchTrigger on Payment_Batch__c (before update) {

    PaymentBatchTriggerHandler.validateOnSubmit(
        Trigger.new,
        Trigger.oldMap
    );

}