public class BackfillLastShopifyOrderDate
    implements Database.Batchable<SObject>,
               Database.Stateful,
               Schedulable {

    // ══════════════════════════════════════════════════════════════
    // LAST SHOPIFY ORDER DATE — refresh
    //
    // Sets Last_Shopify_Order_Date__c to the newest Shopify order
    // actually on each account, read from the Order records in
    // Salesforce.
    //
    // WHY THIS EXISTS
    //   The field was previously stamped with Date.today() after
    //   every successful sync call, so it held the last SYNC date
    //   rather than the last ORDER date. ShopifyOrderSyncService now
    //   sets it correctly, but only for accounts that job processes.
    //
    //   The daily sync only covers stores synced in the last 90
    //   days. A store that goes quiet is exactly the store whose
    //   date must stay accurate, and exactly the store most likely
    //   to fall outside that window. This class covers every account
    //   regardless.
    //
    // SAFE TO RE-RUN
    //   Records already holding the correct value are skipped, so a
    //   repeat run performs no DML on them. Accounts with no Shopify
    //   orders are set to null, which is the honest value and what
    //   identifies a store that has never ordered.
    //
    // SCHEDULE
    //   Sunday 9:00 PM — two hours before the R12 calculation, so
    //   the order dates are fresh going into the weekly at-risk
    //   evaluation, and well clear of both daily order syncs.
    //   Cron: 0 0 21 ? * SUN
    //
    // MANUAL RUN
    //   Database.executeBatch(new BackfillLastShopifyOrderDate(), 200);
    // ══════════════════════════════════════════════════════════════

    private Integer stamped = 0;
    private Integer cleared = 0;
    private Integer skipped = 0;
    private Integer failed  = 0;

    // ── Schedulable entry point ───────────────────────────────────
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new BackfillLastShopifyOrderDate(), 200);
    }

    // ── Start: every account carrying a Shopify ID ────────────────
    // Deliberately not filtered by record type or sync window. A
    // store outside the sync window still needs an accurate date.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(
            'Last Order Date refresh started: ' + DateTime.now()
        );
        return Database.getQueryLocator([
            SELECT Id, Last_Shopify_Order_Date__c
            FROM Account
            WHERE Shopify_Company_Id__c != null
        ]);
    }

    // ── Execute ───────────────────────────────────────────────────
    public void execute(
        Database.BatchableContext bc,
        List<Account> scope
    ) {
        Set<Id> ids = new Set<Id>();
        for (Account a : scope) ids.add(a.Id);

        // Newest Shopify order per account in this chunk
        Map<Id, Date> newest = new Map<Id, Date>();
        for (AggregateResult ar : [
            SELECT AccountId accId, MAX(EffectiveDate) maxDate
            FROM Order
            WHERE Shopify_Order_Id__c != null
            AND   AccountId IN :ids
            GROUP BY AccountId
        ]) {
            newest.put((Id) ar.get('accId'), (Date) ar.get('maxDate'));
        }

        List<Account> toUpdate = new List<Account>();
        for (Account a : scope) {
            Date d = newest.get(a.Id);   // null where no orders exist

            // Already correct — no DML needed. This is what makes
            // the weekly run cheap after the initial correction.
            if (a.Last_Shopify_Order_Date__c == d) {
                skipped++;
                continue;
            }

            toUpdate.add(new Account(
                Id = a.Id, Last_Shopify_Order_Date__c = d
            ));
            if (d == null) { cleared++; } else { stamped++; }
        }

        if (toUpdate.isEmpty()) return;

        for (Database.SaveResult r : Database.update(toUpdate, false)) {
            if (!r.isSuccess()) {
                failed++;
                System.debug(
                    'Last order date update failed: ' +
                    r.getErrors()[0].getMessage()
                );
            }
        }
    }

    // ── Finish ────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        System.debug(
            'Last Order Date refresh complete' +
            ' | Stamped: '            + stamped +
            ' | Cleared (no orders): '+ cleared +
            ' | Already correct: '    + skipped +
            ' | Failed: '             + failed
        );
    }
}