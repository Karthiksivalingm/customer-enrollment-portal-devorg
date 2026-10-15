trigger OpportunityLineTrigger on OpportunityLineItem (after insert, after update, after delete) {


    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OpportunityLineItemHandler.recalculateOpportunityAmounts(Trigger.new, null);
        }
        if (Trigger.isDelete) {
            OpportunityLineItemHandler.recalculateOpportunityAmounts(null, Trigger.old);
        }
    }

}