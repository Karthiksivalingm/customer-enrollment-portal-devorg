# Shopify At-Risk Notices and Offboarding: how it works

This describes the sandbox build as of 13 Oct 2026. It was established by reading the code and querying the org (Session B, 29 Sep → 8 Oct). The change history is in `04_Change_Records/Change_Log.md` (CHG-01, CHG-12), and the production component list is `06_Deployment/Deployment_Documents/Shopify_AtRisk_Offboarding_Deployment_Document.xlsx`.

## In one paragraph
Shopify orders are synced into Salesforce, and each Store Location's **last order date** is tracked. A weekly job calculates R12 and YTD sales and flags stores whose YTD has fallen below 50% of last year as **at risk**; the account owner then gets a task. A daily job sends a series of **warm-off emails** to each store's contacts as the time since the last order grows:
- Email 1 at month 12
- Email 2 at month 15
- Email 3 at month 17
- Email 4 at month 17 + 15 days
- Email 5 at month 18, when the store is **deactivated**

If a store orders again, its open notices are closed as Recovered.

## Scheduled jobs (sandbox, time zone Asia/Kolkata)
| Job name | Class | Cron | What it does |
|---|---|---|---|
| Shopify Order Sync Night / Day | `ShopifyOrderSyncBatch` | `0 0 3 * * ?` / `0 0 10 * * ?` | Pulls orders. Sets `Last_Shopify_Order_Date__c` (latest order EffectiveDate) and `Last_Shopify_Order_Sync_Date__c` (today) |
| Shopify Last Order Date Refresh | `BackfillLastShopifyOrderDate` | `0 0 21 ? * SUN` | Weekly safety net that recalculates the last order date from Orders |
| Shopify R12 Sales Weekly | `ShopifyR12SalesBatch` → `ShopifyR12SalesService` | `0 0 23 ? * SUN` | Calculates R12 / YTD and the at-risk flag |
| Shopify At Risk Notices Daily | `ShopifyAtRiskNoticeBatch` | `0 0 5 * * ?` | Creates notices, which trigger the emails; deactivates stores at 18 months; cleans up notices |

⚠ The schedules run in IST. The code comment says 5 AM Pacific, so confirm the time zone with the client before creating the jobs in production.

## Calculations
- **Current R12** = sales in the last 365 days. **Prior R12** = the 365 days before that.
- **Current YTD** = 1 Jan to today. **Prior YTD** = the same period last year. **YTD %** = Current YTD ÷ Prior YTD × 100.
- **At risk** (`Shopify_Sales_At_Risk__c`) = YTD % < 50. It's never set when Prior YTD = 0. Companies get rolled-up totals and their own flag.
  Known issue: the company rollup is calculated per 200-record batch chunk, so a company split across two chunks can get partial totals.
- Account formulas: `Months_Since_Last_Order__c`, `Scheduled_Deactivation_Date__c` = `ADDMONTHS(Last_Shopify_Order_Date__c, 18)`,
  `Inactivity_Stage__c` = Never Ordered / Active / Month 12 / Month 15 / Month 17 / Month 18+.

## Flows
| Flow | Trigger | Action |
|---|---|---|
| Set At Risk Dates on Store Location | Account, before save | When the store becomes at risk: `At_Risk_Since__c = today` and adds 1 to `At_Risk_Episode_Count__c`. Clears `At_Risk_Since__c` when it recovers |
| Create At Risk Task for Account Owner | after save | Task "Shopify sales at risk — contact this store" for the owner, due today. Created once per episode |
| Send Shopify At Risk Notice | `Shopify_At_Risk_Notice__c` created with Status = Pending Send | Calls Apex `SendWarmOffEmail`, then sets Notice Sent or Send Failed |
| Account – Auto-Populate Offboarding Date and User | Account | Stamps the offboarding date and user |

## Notice batch logic (`ShopifyAtRiskNoticeBatch`)
- **Scope:** Store Locations with a parent Company, `Active__c = true`, a Shopify Company Id, last order 12 or more months ago, and a name matching `Test_Store_Name_Filter__c`.
  The sandbox filter is `R12 WOT%`. **Clear it in production**, or only test stores will be processed.
- **Stage** comes from the months since the last order. With At Risk Mode = **Every Stage**, Emails 1–4 go only to stores that are flagged at risk.
- **Notices:** one `Shopify_At_Risk_Notice__c` per contact (via AccountContactRelation) per stage, Status = Pending Send.
  `Notice_Key__c` (contact + store + stage + last order date) is unique, which blocks duplicates.
  To re-test a stage, delete the notices or change the last order date.
- **Email 3** also creates a task "Retailer inactivity: 30-day deactivation warning sent" for the owner, High priority, due in 7 days.
- **At 18 months**, only if Email 3 was sent and `Auto_Offboard__c` is on: sets `Active__c = false`, sends Email 5, and sets Offboarding Reason "Store At Risk", the date and the user (`Offboard_Owner_Username__c`). `AccountTriggerHelper` deactivates the Company when it has no active stores left.
- **finish():** open notices for stores that have ordered again → Recovered. Notices for inactive stores → Offboarded.
- Running `Database.executeBatch(new ShopifyAtRiskNoticeBatch(), 50)` by hand **sends real emails**, because the flow fires on every notice insert.

## Email sending (`SendWarmOffEmail`, invocable Apex)
The template is chosen by Stage: `Template_Stage_1..5__c` → Warm Off 1–5, or `Email_Template_Name__c` for legacy notices that have no Stage.
The email goes to the Contact from the org-wide address, with the notice as WhatId so merge fields fill in, and the activity is logged.
Apex is used because the flow's own Send Email action didn't fill merge fields from the notice (tested 28 Sep). Failed sends aren't retried.

## Config: `Shopify_At_Risk_Config__mdt.Default`
Active, At Risk Mode (Every Stage), Auto Offboard (on), Deactivation Months (18), Reminder Days (15; the code hard-codes 15), Org Wide Email,
Template Stage 1–5, Email Template Name, Legacy Notice Enabled (off), Require Opt-In, Exclude Bounced, Test Store Name Filter, Offboard Reason and Offboard Owner Username.

## Before production
- Clear the Test Store Name Filter.
- Decide the At Risk Mode for Emails 1–4. With Every Stage, stores can lose the flag in January and miss Email 3.
- Create the 4 scheduled jobs in the agreed time zone.
- Run all tests first: the org-wide coverage figure from partial runs isn't reliable.
- Use a production org-wide email address and production users.
