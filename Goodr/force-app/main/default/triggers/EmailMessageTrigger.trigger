trigger EmailMessageTrigger on EmailMessage (after insert) {

    if (trigger.isAfter) {
        if (trigger.isInsert) {
            EmailMessageTriggerHandler.handleAfterInsert(trigger.new);
        }
    }
}