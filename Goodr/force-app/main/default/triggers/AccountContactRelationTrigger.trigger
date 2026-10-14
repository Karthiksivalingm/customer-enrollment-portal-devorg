trigger AccountContactRelationTrigger on AccountContactRelation (after insert, after update) {

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AccountContactRelationHandler.handleAfterInsert(Trigger.new);
        }
    }
}