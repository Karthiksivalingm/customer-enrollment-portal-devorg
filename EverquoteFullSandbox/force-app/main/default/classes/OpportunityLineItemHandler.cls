/*
 * OpportunityLineItemHandler.cls
 * Recalculates rollup fields on the parent Opportunity whenever its
 * OpportunityLineItems are inserted, updated, or deleted:
 *   - DOCUSIGN_Ad_Spend_Amount__c            -> sum of 'Ad spend' line items
 *   - DOCUSIGN_Marketing_Services_Products__c -> sum of 'Search Boost',
 *       'Social Media Mgmt', and 'Multi-Channel Max' line items
 *
 * Migrated from OpportunityLineItemTrigger (after insert/update/delete).
 * Logic unchanged during trigger consolidation.
 */
public class OpportunityLineItemHandler {

    private static final String PRODUCT_AD_SPEND = 'Ad spend';
    private static final Set<String> MARKETING_SERVICE_PRODUCTS = new Set<String>{
        'Search Boost',
        'Social Media Mgmt',
        'Multi-Channel Max'
    };

    /*
     * Recalculates Ad Spend / Marketing Services rollup amounts on the parent
     * Opportunities affected by the triggering OpportunityLineItem records.
     * Pass newLineItems for insert/update, oldLineItems for delete (one will be null).
     */
    public static void recalculateOpportunityAmounts(List<OpportunityLineItem> newLineItems, List<OpportunityLineItem> oldLineItems) {
        Set<Id> oppIds = new Set<Id>();

        if (newLineItems != null) {
            for (OpportunityLineItem oli : newLineItems) {
                oppIds.add(oli.OpportunityId);
            }
        }
        if (oldLineItems != null) {
            for (OpportunityLineItem oli : oldLineItems) {
                oppIds.add(oli.OpportunityId);
            }
        }

        if (oppIds.isEmpty()) {
            return;
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
            if (oli.Product2.Name == PRODUCT_AD_SPEND) {
                adSpendAmountMap.put(oli.OpportunityId, adSpendAmountMap.get(oli.OpportunityId) + oli.TotalPrice);
            } else if (MARKETING_SERVICE_PRODUCTS.contains(oli.Product2.Name)) {
                marketingServicesAmountMap.put(oli.OpportunityId, marketingServicesAmountMap.get(oli.OpportunityId) + oli.TotalPrice);
            }
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Id oppId : oppIds) {
            opportunitiesToUpdate.add(new Opportunity(
                Id = oppId,
                DOCUSIGN_Ad_Spend_Amount__c = adSpendAmountMap.get(oppId),
                DOCUSIGN_Marketing_Services_Products__c = marketingServicesAmountMap.get(oppId)
            ));
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
}