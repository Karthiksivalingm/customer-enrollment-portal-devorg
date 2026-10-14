// CHANGE 1: Added `inherited sharing` to class declaration
public inherited sharing class ShopifySalesSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    private List<Api_Log__c> logs = new List<Api_Log__c>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // ── CHANGED: added ShippingCountryCode — required by ShopifySalesSyncService.syncStoreLocationSales() ──
        // ── which now resolves Shopify config by country instead of Sales_Channel__c                          ──
        return Database.getQueryLocator([
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c, Active__c, ShippingCountryCode
            FROM Account
            WHERE RecordType.DeveloperName = 'Store_Location'
                  AND Shopify_Company_Id__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // ── NEW: explicitly set bypass flags at the BATCH level, not just inside the service's ──
        // ── own update block. This is a belt-and-suspenders fix for                            ──
        // ── "Too many queueable jobs added to the queue: 2" — AccountTriggerHandler's own      ──
        // ── !System.isBatch() guard should already prevent this, but setting the bypass flags  ──
        // ── explicitly here removes any dependency on trigger-timing/static-variable race       ──
        // ── conditions between when the service resets them and when the trigger actually fires.──
        AccountTriggerHelper.bypassActiveStatusSync = true;
        AccountTriggerHelper.bypassAddressSync      = true;

        try {
            ShopifySalesSyncService.syncStoreLocationSales(scope, logs);
        } catch (Exception e) {
            // ── NEW: catch per-chunk so one bad chunk doesn't fail the whole batch silently ──
            logs.add(new Api_Log__c(
                Context__c           = 'Shopify Sales Sync Batch - Chunk Exception',
                Response_Message__c  = e.getMessage(),
                Stack_Trace__c       = e.getStackTraceString(),
                Log_Type__c          = 'API Errors'
            ));
        } finally {
            AccountTriggerHelper.bypassActiveStatusSync = false;
            AccountTriggerHelper.bypassAddressSync      = false;
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!logs.isEmpty()) {
            insert logs;
        }
    }
}