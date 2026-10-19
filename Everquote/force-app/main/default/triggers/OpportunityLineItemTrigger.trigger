trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, after delete) {
    Set<Id> oppIds = new Set<Id>();
    
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (OpportunityLineItem oli : Trigger.new) {
            oppIds.add(oli.OpportunityId);
        }
    }
    if (Trigger.isDelete) {
        for (OpportunityLineItem oli : Trigger.old) {
            oppIds.add(oli.OpportunityId);
        }
    }
    
    Map<Id, Decimal> adSpendAmountMap = new Map<Id, Decimal>();
    Map<Id, Decimal> marketingServicesAmountMap = new Map<Id, Decimal>();
    
    for (Id oppId : oppIds) {
        adSpendAmountMap.put(oppId, 0);
        marketingServicesAmountMap.put(oppId, 0);
    }
    
    List<OpportunityLineItem> olis = [
        SELECT Id, TotalPrice, OpportunityId, Product2Id, Product2.Name
        FROM OpportunityLineItem
        WHERE OpportunityId IN :oppIds
    ];
    
    for (OpportunityLineItem oli : olis) {
        if (oli.Product2.Name == 'Ad spend') {
            adSpendAmountMap.put(oli.OpportunityId, adSpendAmountMap.get(oli.OpportunityId) + oli.TotalPrice);
        } else if (oli.Product2.Name == 'Search Boost' || oli.Product2.Name == 'Social Media Mgmt' || oli.Product2.Name == 'Multi-Channel Max') {
            marketingServicesAmountMap.put(oli.OpportunityId, marketingServicesAmountMap.get(oli.OpportunityId) + oli.TotalPrice);
        }
    }
    
    List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    for (Id oppId : oppIds) {
        Opportunity opp = new Opportunity(Id = oppId, DOCUSIGN_Ad_Spend_Amount__c = adSpendAmountMap.get(oppId), DOCUSIGN_Marketing_Services_Products__c = marketingServicesAmountMap.get(oppId));
        opportunitiesToUpdate.add(opp);
    }
    
    if (!opportunitiesToUpdate.isEmpty()) {
        update opportunitiesToUpdate;
    }
}