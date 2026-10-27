/**
 * Removes the Shopify ordering role of stores deactivated by ShopifyAtRiskNoticeBatch.
 * The Account trigger skips its Shopify push when Active__c changes inside a batch, so the
 * role would stay in Shopify and the Shopify sales sync would set the store active again.
 * Calls the existing ShopifyActiveStatusPushService (the same push as a manual deactivation),
 * a few stores per job to stay within the callout limit, chaining the rest.
 */
public inherited sharing class ShopifyOffboardRolePushQueueable implements Queueable, Database.AllowsCallouts {

    // About two Shopify calls per contact; 5 stores per job stays well under 100 callouts
    @TestVisible private static final Integer STORES_PER_JOB = 5;

    private List<Id> storeIds;

    public ShopifyOffboardRolePushQueueable(List<Id> storeIds) {
        this.storeIds = storeIds == null ? new List<Id>() : storeIds;
    }

    public void execute(QueueableContext ctx) {
        List<Id> thisJob = new List<Id>();
        List<Id> nextJob = new List<Id>();
        for (Id storeId : storeIds) {
            if (thisJob.size() < STORES_PER_JOB) thisJob.add(storeId);
            else nextJob.add(storeId);
        }

        // Only stores that are still inactive: a store reactivated in the meantime keeps its role
        List<Account> stores = [
            SELECT Id FROM Account
            WHERE Id IN :thisJob AND Active__c = false AND Shopify_Company_Id__c != null
        ];
        if (!stores.isEmpty()) {
            ShopifyActiveStatusPushService.syncActiveStatusToShopify(stores);
        }

        // Chained jobs cannot run inside a test
        if (!nextJob.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new ShopifyOffboardRolePushQueueable(nextJob));
        }
    }
}
