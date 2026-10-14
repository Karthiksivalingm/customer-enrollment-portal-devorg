trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, after delete ) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityLineItemHandler.updateOppProducts(Trigger.new);
    }
    
    OpportunityLineItemHandler.updateHybridProductFlag( Trigger.new, Trigger.old, Trigger.isDelete );
    
    // New Logic – Set Opportunity_Product_Updated__c = TRUE
  //  OpportunityLineItemHandler.updateOpportunityProductUpdatedFlag( Trigger.new, Trigger.old, Trigger.isDelete );
}