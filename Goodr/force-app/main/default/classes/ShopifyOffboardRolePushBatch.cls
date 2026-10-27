/**
 * Removes the Shopify ordering role of stores deactivated by ShopifyAtRiskNoticeBatch.
 * The Account trigger skips its Shopify push when Active__c changes inside a batch, so the
 * role would stay in Shopify and the Shopify sales sync would set the store active again.
 * Calls the existing ShopifyActiveStatusPushService (the same push as a manual deactivation).
 *
 * Run with one store per chunk: the push makes about two Shopify calls per contact and falls
 * back to the Company's contacts when the store has none, so one store can need dozens of calls.
 * Each chunk is its own transaction, so a failing store does not stop the others.
 */
public inherited sharing class ShopifyOffboardRolePushBatch
    implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public static final Integer STORES_PER_CHUNK = 1;

    private Set<Id> storeIds;

    public ShopifyOffboardRolePushBatch(Set<Id> storeIds) {
        this.storeIds = storeIds == null ? new Set<Id>() : storeIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id FROM Account
            WHERE Id IN :storeIds AND Active__c = false AND Shopify_Company_Id__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Re-check: a store reactivated since the run started keeps its role
        List<Account> stores = [
            SELECT Id FROM Account
            WHERE Id IN :new Map<Id, SObject>(scope).keySet() AND Active__c = false
        ];
        if (!stores.isEmpty()) {
            ShopifyActiveStatusPushService.syncActiveStatusToShopify(stores);
        }
    }

    public void finish(Database.BatchableContext bc) {}
}
