public class OpportunityLineItemHandler {

    public static Boolean hasAlreadyRun = false;  

    public static void updateOppProducts(List<OpportunityLineItem> newLineItems) {

        if (hasAlreadyRun) {
            return; 
        }
        hasAlreadyRun = true;
        System.debug('updateOppProducts runs');

        List<OpportunityLineItem> updateList = new List<OpportunityLineItem>();

        List<OpportunityLineItem> lineItemsWithProducts = [
            SELECT Id, Product2Id, Product2.Profit_center_new__c, Product2.Licensing_fee__c,
                   Product2.Profit_center_service__c, Product2.Profit_center_used__c,
                   Product2.MRR__c, Product2.Set_up_Fee__c, OpportunityId 
            FROM OpportunityLineItem 
            WHERE Id IN :newLineItems
        ];

        for (OpportunityLineItem oli : lineItemsWithProducts) {
            if (oli.Product2Id != null) {
                OpportunityLineItem upd = new OpportunityLineItem();
                upd.Id = oli.Id;
                upd.MRR__c = oli.Product2.MRR__c;
                upd.Setup_Fee__c = oli.Product2.Set_up_Fee__c;
                upd.Profit_center_new__c = oli.Product2.Profit_center_new__c;
                upd.Profit_center_service__c = oli.Product2.Profit_center_service__c;
                upd.Profit_center_used__c = oli.Product2.Profit_center_used__c;
                upd.Licensing_fee__c = oli.Product2.Licensing_fee__c;
                updateList.add(upd);
            }
        }

        if (!updateList.isEmpty()) {
            update updateList;
        }
    }

    // Hybrid Product Checkbox Logic 
    public static void updateHybridProductFlag(
        List<OpportunityLineItem> newList,
        List<OpportunityLineItem> oldList,
        Boolean isDelete
    ) {
         Set<Id> oppIds = new Set<Id>();

        if (!isDelete && newList != null) {
            for (OpportunityLineItem oli : newList) {
                oppIds.add(oli.OpportunityId);
            }
        } else if (isDelete && oldList != null) {
            for (OpportunityLineItem oli : oldList) {
                oppIds.add(oli.OpportunityId);
            }
        }

        if (oppIds.isEmpty()) return;

        List<OpportunityLineItem> relatedLineItems = [
            SELECT Id, Product2.Name, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];

        Map<Id, Boolean> hybridFlagMap = new Map<Id, Boolean>();

        for (Id oppId : oppIds) {
            Boolean foundHybridProduct = false;

            for (OpportunityLineItem item : relatedLineItems) {
                if (item.OpportunityId == oppId &&
                    item.Product2.Name != null &&
                    item.Product2.Name.contains('Hybrid')) {

                    foundHybridProduct = true;
                    break;
                }
            }

            hybridFlagMap.put(oppId, foundHybridProduct);
        }

        List<Opportunity> oppToUpdate = new List<Opportunity>();

        for (Id oppId : hybridFlagMap.keySet()) {
            oppToUpdate.add(new Opportunity(
                Id = oppId,
                Hybrid_Product__c = hybridFlagMap.get(oppId)
            ));
        }

        if (!oppToUpdate.isEmpty()) {
            update oppToUpdate;
        }
    }

    // New Logic – Set Opportunity_Product_Updated__c = TRUE
 /*   public static void updateOpportunityProductUpdatedFlag(
        List<OpportunityLineItem> newList,
        List<OpportunityLineItem> oldList,
        Boolean isDelete
    ) {
      
        Set<Id> oppIds = new Set<Id>();

        if (!isDelete && newList != null) {
            for (OpportunityLineItem oli : newList) {
                if (oli.OpportunityId != null) {
                    oppIds.add(oli.OpportunityId);
                }
            }
        }

        if (isDelete && oldList != null) {
            for (OpportunityLineItem oli : oldList) {
                if (oli.OpportunityId != null) {
                    oppIds.add(oli.OpportunityId);
                }
            }
        }

        if (oppIds.isEmpty()) return;

        List<Opportunity> oppToUpdate = new List<Opportunity>();

        for (Id oppId : oppIds) {
            oppToUpdate.add(new Opportunity(
                Id = oppId,
                Opportunity_Product_Updated__c = true
            ));
        }

        if (!oppToUpdate.isEmpty()) {
            update oppToUpdate;
        }
    }
*/
}