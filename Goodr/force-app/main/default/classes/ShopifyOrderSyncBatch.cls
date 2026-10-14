public class ShopifyOrderSyncBatch
    implements Database.Batchable<SObject>,
               Database.AllowsCallouts,
               Schedulable {

    private Boolean fullSync;
    private Date    syncFromDate;

    // ── Constructor 1: default daily sync ─────────────────────────
    public ShopifyOrderSyncBatch() {
        this.fullSync     = false;
        this.syncFromDate = Date.today();
    }

    // ── Constructor 2: full or daily sync from today ───────────────
    public ShopifyOrderSyncBatch(Boolean fullSync) {
        this.fullSync     = fullSync;
        this.syncFromDate = Date.today();
    }

    // ── Constructor 3: sync from specific date ─────────────────────
    // e.g. new ShopifyOrderSyncBatch(false, Date.today().addDays(-10))
    public ShopifyOrderSyncBatch(Boolean fullSync, Date syncFromDate) {
        this.fullSync     = fullSync;
        this.syncFromDate = syncFromDate;
    }

    // ── Schedulable: always daily sync ────────────────────────────
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(
            new ShopifyOrderSyncBatch(false, Date.today()), 1
        );
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(
            'Batch started: ' + DateTime.now() +
            ' | fullSync: '   + fullSync +
            ' | syncFrom: '   + syncFromDate
        );

        if (fullSync) {
            // Full sync: ALL store locations — historical orders
            System.debug('FULL SYNC — all store locations');
            // ── CHANGED: added ShippingCountryCode — required by ShopifyOrderSyncService.syncOrders() ──
            // ── which now resolves Shopify config by country instead of Sales_Channel__c              ──
            // ── CHANGED: added Last_Shopify_Order_Sync_Date__c — the sync watermark, kept separate    ──
            // ── from Last_Shopify_Order_Date__c which now holds the real last order date              ──
            return Database.getQueryLocator([
                SELECT Id, Name, Sales_Channel__c,
                       Shopify_Company_Id__c, ShippingCountryCode,
                       Last_Shopify_Order_Date__c,
                       Last_Shopify_Order_Sync_Date__c,
                       ParentId,
                       Parent.Shopify_Company_Id__c,
                       Parent.Sales_Channel__c
                FROM Account
                WHERE RecordType.Name            = 'Store Location'
                AND Shopify_Company_Id__c        != null
                AND Sales_Channel__c             != null
                AND Parent.Shopify_Company_Id__c != null
                ORDER BY Name ASC
            ]);
        } else {
            // Daily sync: only stores synced in the last 90 days
            //
            // CHANGED: filters on Last_Shopify_Order_Sync_Date__c,
            // not Last_Shopify_Order_Date__c. The order date now
            // holds the customer's genuine last order, so filtering
            // on it would permanently drop any store that has not
            // ordered in 90 days out of the sync — and a store that
            // never syncs can never come back.
            Date ninetyDaysAgo = Date.today().addDays(-90);
            System.debug(
                'DAILY/DATE SYNC — from: ' + syncFromDate +
                ' | synced since: ' + ninetyDaysAgo
            );
            // ── CHANGED: added ShippingCountryCode — required by ShopifyOrderSyncService.syncOrders() ──
            return Database.getQueryLocator([
                SELECT Id, Name, Sales_Channel__c,
                       Shopify_Company_Id__c, ShippingCountryCode,
                       Last_Shopify_Order_Date__c,
                       Last_Shopify_Order_Sync_Date__c,
                       ParentId,
                       Parent.Shopify_Company_Id__c,
                       Parent.Sales_Channel__c
                FROM Account
                WHERE RecordType.Name            = 'Store Location'
                AND Shopify_Company_Id__c        != null
                AND Sales_Channel__c             != null
                AND Parent.Shopify_Company_Id__c != null
                AND (Last_Shopify_Order_Sync_Date__c  >= :ninetyDaysAgo
                     OR Last_Shopify_Order_Sync_Date__c = null)
                ORDER BY Last_Shopify_Order_Sync_Date__c DESC NULLS FIRST
            ]);
        }
    }

    public void execute(
        Database.BatchableContext bc,
        List<Account> accounts
    ) {
        try {
            List<Api_Log__c> logs = new List<Api_Log__c>();
            ShopifyOrderSyncService.syncOrders(
                accounts, logs, fullSync, syncFromDate
            );
            if (!logs.isEmpty()) insert logs;
        } catch (Exception e) {
            System.debug(
                'Batch error: ' + e.getMessage() +
                ' | ' + accounts[0].Name
            );
            try {
                insert new Api_Log__c(
                    Context__c          = 'Order Sync - Batch Error',
                    Response_Message__c =
                        e.getMessage() +
                        ' | Account: ' + accounts[0].Name,
                    Stack_Trace__c      = e.getStackTraceString(),
                    Log_Type__c         = 'API Errors'
                );
            } catch (Exception logEx) {
                System.debug('Log failed: ' + logEx.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        Integer total = [
            SELECT COUNT() FROM Order
            WHERE Shopify_Order_Id__c != null
        ];
        Integer todayCount = [
            SELECT COUNT() FROM Order
            WHERE Shopify_Order_Id__c != null
            AND LastModifiedDate = TODAY
        ];
        System.debug(
            'Batch complete — Total SF orders: ' + total +
            ' | Synced today: '                  + todayCount
        );
    }
}