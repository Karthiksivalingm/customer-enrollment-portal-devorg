trigger OpportunityProductTrigger on OpportunityLineItem
(before insert, after insert, after delete) {

    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityProductHandler.handleBeforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityProductHandler.handleAfterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isDelete) {
        OpportunityProductHandler.handleAfterDelete(Trigger.old);
    }
}