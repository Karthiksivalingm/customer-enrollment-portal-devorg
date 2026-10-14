public class OpportunityProductHandler {

    // ==========================================
    // BEFORE INSERT
    // ==========================================
    public static void handleBeforeInsert(List<OpportunityLineItem> newList) {

        Set<Id> pricebookEntryIds = new Set<Id>();

        for (OpportunityLineItem oli : newList) {
            if (oli.PricebookEntryId != null) {
                pricebookEntryIds.add(oli.PricebookEntryId);
            }
        }

        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>(
            [SELECT Id, Product2.Add_On_Product__c
             FROM PricebookEntry
             WHERE Id IN :pricebookEntryIds]
        );

        for (OpportunityLineItem oli : newList) {
            if (pbeMap.containsKey(oli.PricebookEntryId)) {
                oli.Add_On_Product__c =
                    pbeMap.get(oli.PricebookEntryId).Product2.Add_On_Product__c;
            }
        }
    }

    // ==========================================
    // AFTER INSERT
    // ==========================================
    public static void handleAfterInsert(List<OpportunityLineItem> newList) {

        Set<Id> oppIds = new Set<Id>();

        for (OpportunityLineItem oli : newList) {
            oppIds.add(oli.OpportunityId);
        }

        recalculateOpportunity(oppIds);
    }

    // ==========================================
    // AFTER DELETE  FIXED
    // ==========================================
    public static void handleAfterDelete(List<OpportunityLineItem> oldList) {

        Set<Id> oppIds = new Set<Id>();

        // IMPORTANT: Use Trigger.old
        for (OpportunityLineItem oli : oldList) {
            oppIds.add(oli.OpportunityId);
        }

        recalculateOpportunity(oppIds);
    }

    // ==========================================
    // COMMON RECALCULATION METHOD
    // ==========================================
    private static void recalculateOpportunity(Set<Id> oppIds) {

        Map<Id, List<OpportunityLineItem>> oppProductMap = new Map<Id, List<OpportunityLineItem>>();

        for (OpportunityLineItem oli : [
            SELECT OpportunityId,
                   PricebookEntry.Product2.Product_Type__c,
                   PricebookEntry.Product2.Add_On_Product__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ]) {

            if (!oppProductMap.containsKey(oli.OpportunityId)) {
                oppProductMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }

            oppProductMap.get(oli.OpportunityId).add(oli);
        }

        List<Opportunity> oppToUpdate = new List<Opportunity>();

        for (Id oppId : oppIds) {

            Opportunity opp = new Opportunity(Id = oppId);

            // No products left
            if (!oppProductMap.containsKey(oppId)) {
                opp.Product_Status__c = null;
                opp.Add_On_Product_Type__c = null;
            }
            else {

                String mainProductType;
                Set<String> addOnTypes = new Set<String>();

                for (OpportunityLineItem oli : oppProductMap.get(oppId)) {

                    if (oli.PricebookEntry.Product2.Add_On_Product__c == false) {
                        mainProductType =
                            oli.PricebookEntry.Product2.Product_Type__c;
                    }
                    else {
                        addOnTypes.add(
                            oli.PricebookEntry.Product2.Product_Type__c
                        );
                    }
                }

                // Set main product picklist
                opp.Product_Status__c = mainProductType;

                // Set multi picklist
                if (addOnTypes.isEmpty()) {
                    opp.Add_On_Product_Type__c = null;
                } else {
                    opp.Add_On_Product_Type__c =
                        String.join(new List<String>(addOnTypes), ';');
                }
            }

            oppToUpdate.add(opp);
        }

        if (!oppToUpdate.isEmpty()) {
            update oppToUpdate;
        }
    }
}