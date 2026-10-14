trigger ApiLogTrigger on API_Log__c (after insert) {

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
        	ApiLogTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}