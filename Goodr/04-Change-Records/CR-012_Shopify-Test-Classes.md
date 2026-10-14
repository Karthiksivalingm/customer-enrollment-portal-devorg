# CR-012 — Shopify test classes

| | |
|---|---|
| **Change ID** | CR-012 |
| **Date** | 2026-10-08 (8 Oct 15:49, Session B) |
| **Requirement** | [REQ-032](../03-Requirements/REQ-032_Shopify-Test-Class-Coverage.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GDn9lCAD` |
| **By** | Session B |
| **Status** | Done |

## What changed
Deploy `0Afdx00000GDn9lCAD`, 105 tests, 0 failures:
- **New** `BackfillLastShopifyOrderDateTest` (5 tests). Coverage of BackfillLastShopifyOrderDate: 0% → 97%.
- `ShopifyAtRiskNoticeBatchTest`: inserts the `Shopify_Configuration__c` test records and an HTTP mock.
- `ShopifyR12SalesTest`: corrected the assertion for the 31-Dec order (Prior YTD) and added a year-end guard.
- `ShopifyOrderSyncTest`: now expects `Last_Shopify_Order_Sync_Date__c`; the pricebook activation retries on row lock.

All 5 earlier failures were in the tests, not the classes. Detail: [Session-Logs/2026-09-29_to_10-08_Session_B_Shopify_AtRisk.md](Session-Logs/2026-09-29_to_10-08_Session_B_Shopify_AtRisk.md).


## Rollback
Redeploy the previous test classes from git history and delete `BackfillLastShopifyOrderDateTest`.
