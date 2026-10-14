# DEP-002 — Shopify At-Risk notices and offboarding: production deployment

| | |
|---|---|
| **ID** | DEP-002 |
| **Status** | ⚠ Prepared, **not deployed**. Waiting on client decisions ([REQ-026](../03-Requirements/REQ-026_Shopify-At-Risk-Go-Live.md)) |
| **Target** | GDRPROD |
| **Requirements** | [REQ-030](../03-Requirements/REQ-030_Document-Shopify-R12-And-At-Risk-Process.md) · [REQ-031](../03-Requirements/REQ-031_Shopify-At-Risk-Component-List.md) · [REQ-032](../03-Requirements/REQ-032_Shopify-Test-Class-Coverage.md) |
| **Detailed workbook** | [Deployment-Documents/Shopify_AtRisk_Offboarding_Deployment_Document.xlsx](Deployment-Documents/Shopify_AtRisk_Offboarding_Deployment_Document.xlsx) (sheets: Deployment Document, Open Items, Test Plan) |

## 1. Summary
This is the warm-off email series and the 18-month deactivation for Shopify stores that stop ordering. How it works: [KB-002](../02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding.md).
The sandbox build is [CR-001](../04-Change-Records/CR-001_Shopify-At-Risk-Warm-Off-Offboarding-Sandbox-Build.md) and the tests are [CR-012](../04-Change-Records/CR-012_Shopify-Test-Classes.md).

## 2. Component inventory
Listed with descriptions in the workbook, in these groups:
- Apex classes: `ShopifyAtRiskNoticeBatch`, `SendWarmOffEmail`, `ShopifyR12SalesBatch` / `Service`, `ShopifyOrderSyncBatch` / `Service`, `BackfillLastShopifyOrderDate`, plus their tests;
- flows (4);
- the `Shopify_At_Risk_Notice__c` object and its fields;
- Account fields;
- `Shopify_At_Risk_Config__mdt`;
- 5 Warm-Off email templates;
- reports;
- manual setup steps.

## 3. Pre-deployment steps
- Clear `Test_Store_Name_Filter__c` (sandbox value `R12 WOT%`) ([CON-020](../05-Conflicts/CON-020_Shopify-At-Risk-Sandbox-Only-Settings.md)).
- Client decision: At Risk Mode, Every Stage vs Entry Only ([CON-032](../05-Conflicts/CON-032_With-At-Risk-Mode-Every-Stage-A-Store.md)).
- Production org-wide email address and production offboard owner user.
- Run **all** tests in the sandbox first: coverage from partial runs isn't reliable.

## 4. Deployment sequence
Objects and fields → custom metadata type and record → email templates → Apex classes and tests → flows (activate) → reports.

## 5. Tests to run during validation
`ShopifyAtRiskNoticeBatchTest`, `ShopifyR12SalesTest`, `ShopifyOrderSyncTest`, `BackfillLastShopifyOrderDateTest`, `AccountTriggerHelperTest`.

## 6. Post-deployment steps
Create the 4 scheduled jobs in the agreed time zone ([KB-002](../02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding.md#scheduled-jobs-sandbox-time-zone-asiakolkata)):
- Shopify Order Sync Night / Day
- Shopify Last Order Date Refresh
- Shopify R12 Sales Weekly
- Shopify At Risk Notices Daily

## 7. Post-deployment verification
- Run the R12 batch for one test store and check the at-risk flag and task.
- Run the notice batch only with the test filter set ([CON-033](../05-Conflicts/CON-033_Running-ShopifyAtRiskNoticeBatch-By-Hand-Sends-Real-Emails.md)).
- Check the notice status and the email.

## 8. Rollback
Deactivate the flows, delete the scheduled jobs, and set `Active__c = false` on the config record. Emails already sent can't be recalled.

## 9. Risk notes
- The company rollup is calculated per batch chunk ([CON-031](../05-Conflicts/CON-031_Shopify-Company-Rollup-Is-Calculated-Per-200-Record.md)).
- The classes call mixed Shopify API versions ([CON-027](../05-Conflicts/CON-027_The-Shopify-Classes-Call-Four-Different-Admin-API.md)).
