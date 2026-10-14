public class ShopifyR12SalesBatch
    implements Database.Batchable<SObject>,
               Schedulable {

    // ══════════════════════════════════════════════════════════════
    // SCHEDULE — weekly, every Sunday at 11:00 PM
    //
    // Set up through Setup → Schedule Apex, not in code:
    //   Job Name   : Shopify R12 Sales Weekly
    //   Frequency  : Weekly, Sunday
    //   Start Time : 11:00 PM
    //   Active     : 22 Jul 2026 → 21 Aug 2031
    //
    // Equivalent cron, if ever scheduled programmatically:
    //   0 0 23 ? * SUN
    //     0   = second 0
    //     0   = minute 0
    //     23  = hour 11 PM
    //     ?   = no specific day of month
    //     *   = every month
    //     SUN = Sunday
    //
    // ShopifyAtRiskNoticeBatch runs separately on Monday at 1:00 AM,
    // two hours later, so it reads finalised flag values.
    //
    // CALCULATION — year over year, same period
    //   TY YTD = 1 Jan this year → today
    //   PY YTD = 1 Jan last year → same day last year
    //   At risk when TY YTD is below 50% of PY YTD
    // See ShopifyR12SalesService for the detail.
    // ══════════════════════════════════════════════════════════════
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(
            new ShopifyR12SalesBatch(), 200
        );
    }

    // ── Batch start: all Store Location accounts ──────────────────
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {
        System.debug(
            'R12 Weekly Batch started: ' + DateTime.now()
        );
        return Database.getQueryLocator([
            SELECT Id FROM Account
            WHERE RecordType.Name     = 'Store Location'
            AND Shopify_Company_Id__c != null
        ]);
    }

    // ── Batch execute: calculate for each chunk of 200 ────────────
    public void execute(
        Database.BatchableContext bc,
        List<Account> accounts
    ) {
        List<Id> ids = new List<Id>();
        for (Account a : accounts) ids.add(a.Id);
        ShopifyR12SalesService.calculateR12(ids);
    }

    // ── Batch finish: log summary ─────────────────────────────────
    public void finish(Database.BatchableContext bc) {

        // ── Store Location summary ────────────────────────────────
        Integer total = [
            SELECT COUNT() FROM Account
            WHERE R12_Calculation_Last_Run__c != null
            AND RecordType.Name = 'Store Location'
        ];
        Integer flagged = [
            SELECT COUNT() FROM Account
            WHERE Shopify_Sales_At_Risk__c = true
            AND RecordType.Name = 'Store Location'
        ];
        Integer healthy = [
            SELECT COUNT() FROM Account
            WHERE Shopify_Sales_At_Risk__c = false
            AND R12_Calculation_Last_Run__c != null
            AND RecordType.Name = 'Store Location'
        ];

        // ── Company Account summary ───────────────────────────────
        Integer companiesUpdated = [
            SELECT COUNT() FROM Account
            WHERE R12_Calculation_Last_Run__c != null
            AND RecordType.Name = 'Company'
        ];
        Integer companiesFlagged = [
            SELECT COUNT() FROM Account
            WHERE Shopify_Sales_At_Risk__c = true
            AND RecordType.Name = 'Company'
        ];

        System.debug(
            'R12 Weekly Batch complete'               +
            ' | Stores total: '    + total            +
            ' | At Risk: '         + flagged          +
            ' | Healthy: '         + healthy          +
            ' | Companies updated: '+ companiesUpdated +
            ' | Companies at risk: '+ companiesFlagged
        );
    }
}