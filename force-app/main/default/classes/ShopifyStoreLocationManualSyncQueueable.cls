public inherited sharing class ShopifyStoreLocationManualSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Id accountId;
    private Boolean salesSyncPhase; // ── NEW: false = phase 1 (create+DML), true = phase 2 (callout-only sales sync) ──

    // ── UNCHANGED signature — every existing caller (ShopifyCompanyManualSyncQueueable, etc.) ──
    // ── keeps working exactly as before, defaulting to phase 1 ──
    public ShopifyStoreLocationManualSyncQueueable(Id accountId) {
        this.accountId = accountId;
        this.salesSyncPhase = false;
    }

    // ── NEW: private constructor, used only internally by this class to enqueue its own phase 2 ──
    private ShopifyStoreLocationManualSyncQueueable(Id accountId, Boolean salesSyncPhase) {
        this.accountId = accountId;
        this.salesSyncPhase = salesSyncPhase;
    }

    public void execute(QueueableContext context) {

        if (!salesSyncPhase) {
            // ══════════════ PHASE 1: create store locations (does DML) ══════════════
            List<Account> storeLocations = [
                SELECT Id, Shopify_Company_Id__c
                FROM Account
                WHERE ParentId = :accountId
            ];
            List<Id> locIdsToCreate = new List<Id>();
            for (Account loc : storeLocations) {
                if (String.isBlank(loc.Shopify_Company_Id__c)) {
                    locIdsToCreate.add(loc.Id);
                }
            }
            if (!locIdsToCreate.isEmpty()) {
                ShopifyAccountIntegration.createStoreLocations(locIdsToCreate);
            }

            // ── CHANGED: instead of calling ShopifySalesSyncService directly here in the same   ──
            // ── transaction (which throws "You have uncommitted work pending" because DML just   ──
            // ── ran above via createStoreLocations(), and the next step makes HTTP callouts),    ──
            // ── enqueue a second instance of this SAME class with salesSyncPhase=true. No new    ──
            // ── class needed — the fresh transaction from re-enqueueing is what separates the     ──
            // ── DML from the callout, which is what Salesforce actually requires here.            ──
            System.enqueueJob(new ShopifyStoreLocationManualSyncQueueable(accountId, true));

        } else {
            // ══════════════ PHASE 2: sales sync (callout-only, runs in a fresh transaction) ══════════════
            // ── CHANGED: added ShippingCountryCode — required by ShopifySalesSyncService.syncStoreLocationSales() ──
            // ── which now resolves Shopify config by country instead of Sales_Channel__c. Without this field,   ──
            // ── acc.ShippingCountryCode would be null there, throwing:                                          ──
            // ── "SObject row was retrieved via SOQL without querying the requested field: Account.ShippingCountryCode" ──
            List<Account> locationsToSync = [
                SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c, ShippingCountryCode
                FROM Account
                WHERE ParentId = :accountId
                AND Shopify_Company_Id__c != null
            ];
            if (!locationsToSync.isEmpty()) {
                List<Api_Log__c> logs = new List<Api_Log__c>();
                ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
                if (!logs.isEmpty()) {
                    insert logs;
                }
            }

            // FIX: Test.isRunningTest() prevents double-chaining in test context
            // In production this is always false — no behavior change
            if (!Test.isRunningTest()) {
                System.enqueueJob(new ShopifyContactManualSyncQueueable(accountId));
            }
        }
    }
}