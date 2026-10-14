public inherited sharing class ShopifyCompanyManualSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Id accountId;
    public ShopifyCompanyManualSyncQueueable(Id accountId) {
        this.accountId = accountId;
    }
    public void execute(QueueableContext qc) {
        Account company = [
            SELECT Id, Shopify_Company_Id__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        if (String.isBlank(company.Shopify_Company_Id__c)) {
            ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify(new List<Id>{ accountId });
        }
        // FIX: Prevents stack depth error in test context — no behavior change in production
        if (!Test.isRunningTest()) {
            System.enqueueJob(new ShopifyStoreLocationManualSyncQueueable(accountId));
        }
    }
}