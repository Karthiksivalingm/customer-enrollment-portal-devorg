# Transcript c6dfcc34 – change record

Source: `C:\Users\UTIS LAPTOP 377\.claude\projects\c--Microsoft-VS-Code-GDRSandbox\c6dfcc34-dca0-4c56-b4cf-ef2ceeb71d02.jsonl`
Org: GDRSandbox / GDRSAND (sandipp@goodr.com.partial). Project: `C:\Microsoft VS Code\GDRSandbox`.
Times are UTC from the transcript; IST = UTC + 5:30. Last real activity 2026-10-08 10:24Z; lines dated 2026-10-09 / 2026-10-12 are only internal queue events (artifact watch lost), no work.

Summary: from 29 Sep to 8 Oct 2026 the session mostly read code and queried the org (SOQL, describe, retrieve to scratchpad). The only org change was one sandbox deploy of 4 test classes. Local file changes: 3 test classes edited, 1 new test class (+ meta), and 1 new xlsx in `deployment\`. It also published 1 private claude.ai artifact. It ran no anonymous Apex, scheduled or aborted no jobs, made no data DML outside tests, and changed no Setup settings or non-test classes.

## 1. Change table

| Date-time (UTC / IST) | Org/local | What changed | How | Why (user request) | Outcome |
|---|---|---|---|---|---|
| 2026-09-29 05:49–05:55Z (11:19–11:25 IST) | Org (read only) + local scratchpad | Nothing changed in the org. Retrieved 4 active flows into the session scratchpad `...\c6dfcc34-...\scratchpad\orgflows` (Account_Auto_Populate_Offboarding_Date_and_User, Create_At_Risk_Task_for_Account_Owner, Send_Shopify_At_Risk_Notice, Set_At_Risk_Dates_on_Store_Location) | `sf data query` (CronTrigger, Shopify_At_Risk_Config__mdt, FlowDefinitionView), `sf sobject describe` (Shopify_At_Risk_Notice__c, Account, config mdt), `sf project retrieve start --target-metadata-dir` (scratchpad, not force-app) | Document R12 calculation, notice creation, batch schedule, emails, tasks (09-29 05:48Z) | Found: all 4 org flows differ from local source. ShopifyAtRiskNoticeBatch was NOT scheduled on 09-29. Config was Test filter `R12%`, Auto_Offboard false, At_Risk_Mode Every Stage |
| 2026-09-29 06:00Z (11:30 IST) | Local scratchpad + claude.ai | `scratchpad\shopify-at-risk-process.html` written and published as private artifact "Shopify At-Risk Automation" https://claude.ai/artifact/55i3nQq6YhsSQVLdyfCTm1 (v1) | Write + Artifact publish | Same documentation request | Published. Later found out of date: it still shows the legacy offboarding step, Auto Offboard off, the `R12%` filter and "notice batch not scheduled". The assistant offered to update it twice and the user never asked, so it was not updated |
| 2026-09-30 07:53–08:11Z (13:23–13:41 IST) | Org (read only) | None | Grep on classes; `sf data query` CronTrigger + config + flows | Q&A: batch scope, inactive account with new order, task creation, source of Last Shopify Order Date | Answered. Re-check found Auto_Offboard__c = true, filter `R12 WOT%`, legacy 30-day step removed from batch, new "skip if Email 5 already sent" rule. Notice batch still unscheduled at 08:11Z |
| 2026-09-30 08:19Z, 10:18Z | None | None | Chat only | 15-line business process version; explain manual `Database.executeBatch(new ShopifyAtRiskNoticeBatch(), 50)` and email path | Explanation only (see Process knowledge) |
| 2026-10-08 09:56–09:59Z (15:26–15:29 IST) | Org (read only) | None | `sf data query` (Report, ObjectPermissions, SetupEntityAccess), `sf org list metadata` (CustomTab, ReportType), describe | Full component list for at-risk/offboarding/notice, matching the user's screenshot | Component list given in chat. Found Offboard_Days__c and Offboard_Due_Date__c removed from org. Local config mdt file is stale (has At_Risk_Threshold__c, Notice_Delay_Days__c, Offboard_Days__c) |
| 2026-10-08 10:02–10:06Z (15:32–15:36 IST) | Local | NEW `C:\Microsoft VS Code\GDRSandbox\deployment\Shopify_AtRisk_Offboarding_Deployment_Document.xlsx`. Build script in the old session scratchpad `build_atrisk_xlsx.ps1` | PowerShell + Excel 2007 COM (no Python/Node on the machine). Built, then deleted and rebuilt twice because an em-dash cut off cell text in Excel 2007. Em-dashes replaced with hyphens | "create this as a separate xlsx file in the same deployment folder" (10:00Z) | Sheet "Deployment Document" (113 rows, styled like KeyAccount_Rename_Deployment_Document.xlsx) + sheet "Open Items" (10 items) |
| 2026-10-08 10:10–10:12Z (15:40–15:42 IST) | Org (read only) + local xlsx | xlsx rebuilt: row 110 now names the job "Shopify At Risk Notices Daily". Open Item 1 changed from Blocking to Review (time-zone note) | `sf data query` CronTrigger/AsyncApexJob. Deleted and rebuilt the xlsx (after checking the user had not edited it; one retry for a file lock) | "verify notice batch has a scheduled job in sandbox" (10:10Z) | Confirmed the job exists: "Shopify At Risk Notices Daily", cron `0 0 5 * * ?`, Asia/Kolkata, created 2026-09-30 09:10:21Z by Ruben Smith (not by this session). Ran daily 10-01 to 10-07 at 23:30Z: 1 item each, 0 errors |
| 2026-10-08 10:15–10:17Z (15:45–15:47 IST) | Org (test run) | None | `sf apex run test` (ShopifyAtRiskNoticeBatchTest, ShopifyR12SalesTest, ShopifyOrderSyncTest, AccountTriggerHelperTest) `--code-coverage`, run 707dx00001ws7bd. Retrieve of test and main classes to scratchpad `orgtests` to compare with local | "check all test classes ... >80% ... update/create ... give test class deployment document" (10:15Z) | Failed: 103 run, 98 pass, 5 fail. Local test classes matched the org |
| 2026-10-08 10:18–10:19Z (15:48–15:49 IST) | Local | EDITED ShopifyAtRiskNoticeBatchTest.cls, ShopifyR12SalesTest.cls, ShopifyOrderSyncTest.cls. CREATED BackfillLastShopifyOrderDateTest.cls + .cls-meta.xml | Edit/Write in `force-app\main\default\classes` | Same | See Test classes section |
| 2026-10-08 10:19:37Z start → 10:21:06Z result (15:49 → 15:51 IST) | Org (DEPLOY) | ShopifyAtRiskNoticeBatchTest, ShopifyR12SalesTest, ShopifyOrderSyncTest (changed), BackfillLastShopifyOrderDateTest (new) | `sf project deploy start --source-dir <4 test classes> --test-level RunSpecifiedTests --tests ShopifyAtRiskNoticeBatchTest ShopifyR12SalesTest ShopifyOrderSyncTest BackfillLastShopifyOrderDateTest AccountTriggerHelperTest`. Deploy id **0Afdx00000GDn9lCAD** | Same | Succeeded. 105 tests run, 0 failures, no component errors |
| 2026-10-08 10:21–10:22Z (15:51–15:52 IST) | Org (test run) | None | `sf apex run test` same 4 classes + BackfillLastShopifyOrderDateTest `--code-coverage` | Get per-class coverage | Passed: 109 run, 109 pass. Test-run coverage 66%, org-wide 74%. The assistant said the org-wide figure is unreliable and recommended Run All Tests. The class breakdown adds up to 105, so where the other 4 of the 109 came from is (unverified) |
| 2026-10-08 10:22–10:24Z (15:52–15:54 IST) | Local | xlsx rebuilt again: Backfill row names its test class, test class rows describe their changes, new "Test Plan" sheet (before/after results + coverage), Open Item 3 Resolved, Open Item 11 added (Run All Tests before prod validation) | Edited build script, deleted and rebuilt the xlsx through Excel COM | Same ("give a proper test class updated deployment document") | Final xlsx has 3 sheets: Deployment Document, Open Items, Test Plan |

No non-test Apex, flows, metadata, config records, scheduled jobs or Setup settings were changed by this session.

## 2. Test classes

| Test class | Change | Classes covered: coverage before → after | Result |
|---|---|---|---|
| ShopifyAtRiskNoticeBatchTest (21 tests) | `inactiveStore_noticesSweptToOffboarded` was failing with AuraHandledException. Deactivating a store enqueues ShopifyActiveStatusSyncQueueable, which needs the `Shopify_Configuration__c` custom setting. Added the helper `insertShopifyConfig()`, which inserts the 'Specialty' and 'Specialty CAN' records with dummy test endpoint/token values [redacted]. Also added an `HttpCalloutMock` (`ShopifyNoDataMock`) and called both in the test | ShopifyAtRiskNoticeBatch 94% (269/286) → 94%. SendWarmOffEmail 88% (71/81) → 88% | 1 fail → all pass |
| ShopifyR12SalesTest (20 tests) | `testLateLastYearOrderExcludedFromPriorYtd` asserted the R12 fields, but the 31-Dec order is inside the rolling 12 months. It now asserts Prior_YTD_Sales__c = 5000 and Current_YTD_Sales__c = 0. Added a guard that returns early on 31 Dec. `getEmptyStore()` SOQL now selects Current_YTD_Sales__c and Prior_YTD_Sales__c | ShopifyR12SalesService 98% (118/120). ShopifyR12SalesBatch 100% (15/15). Unchanged | 1 fail → all pass |
| ShopifyOrderSyncTest (23 tests) | `testNoOrdersToday` and `testNoAccountMatch_OrderSkipped` expected the old behaviour (Last_Shopify_Order_Date__c = today). They now expect Last_Shopify_Order_Sync_Date__c = today and Last_Shopify_Order_Date__c = null. Added helper `getStoreDates()`. `activatePricebook()` now retries up to 3 times on UNABLE_TO_LOCK_ROW, which fixes `testAddressProvincePrefixFormat` failing on a lock when test classes run in parallel | ShopifyOrderSyncService 85% (312/366). ShopifyOrderSyncBatch 97% (35/36). Unchanged | 3 fail → all pass |
| BackfillLastShopifyOrderDateTest (NEW, 5 tests) | New class + meta. Uses the same standard price book retry helper. Tests: newest order date is set; date is cleared when the account has no orders; a correct date is left unchanged; orders without a Shopify Id are ignored; the scheduler works | BackfillLastShopifyOrderDate 0% → 97% (29/30) | 5/5 pass |
| AccountTriggerHelperTest (36 tests) | Not changed, only run | AccountTriggerHelper 86% (362/419, 361/419 on the second run). AccountTriggerHandler 98% (110/112) | All pass |

Overall: run 707dx00001ws7bd before the fixes was 103 run / 5 fail (test-run coverage 94%, org-wide 87%). Deploy 0Afdx00000GDn9lCAD ran 105 tests with 0 failures. The coverage run after the deploy was 109/109 pass (org-wide 74%, flagged as unreliable). All 5 failures were test-data or assertion problems, not bugs in the classes being tested.

## 3. Documents produced

- **`C:\Microsoft VS Code\GDRSandbox\deployment\Shopify_AtRisk_Offboarding_Deployment_Document.xlsx`** (created 10-08 10:03Z, final rebuild about 10:24Z). Same style as `KeyAccount_Rename_Deployment_Document.xlsx`.
  - Sheet "Deployment Document": title "Sales At Risk to send Notice & Offboarding process". Columns: Component Name, Description, Test Class, Component Type, Status, Deployment Status, Parent Object, New/Existing, Comments. Section rows: Apex Classes, Flows, Custom Object and UI, Shopify At Risk Notice Fields, Account Fields, Custom Metadata (Settings), Email Templates, Reports, Setup / Manual Steps. Default status values are "Built in Sandbox" and "Pending - Production". Rows marked "Confirm" need the team to fill them in.
  - Sheet "Open Items": 11 items. Blocking: `R12 WOT%` test filter still set. Decision: At_Risk_Mode for Emails 1–4. Review: time zone of the notice job (5 AM IST in the sandbox vs 5 AM Pacific in the code comment). Resolved: Backfill test class (item 3). Item 11: run Run All Tests before prod validation.
  - Sheet "Test Plan": before/after test results and coverage per class.
- **Build script** `C:\Users\UTISLA~1\AppData\Local\Temp\claude\c--Microsoft-VS-Code-GDRSandbox\c6dfcc34-dca0-4c56-b4cf-ef2ceeb71d02\scratchpad\build_atrisk_xlsx.ps1`. Session scratchpad, not in the project.
- **Artifact "Shopify At-Risk Automation"** https://claude.ai/artifact/55i3nQq6YhsSQVLdyfCTm1 (source `...\c6dfcc34-...\scratchpad\shopify-at-risk-process.html`). Covers R12/YTD calculation with worked numbers, the at-risk flag and At Risk Since, the schedule, the 5 warm-off emails, tasks, deactivation, the notice status lifecycle, config values, a field reference, and the classes and flows. It reflects the code and config as of 09-29, so it is now out of date (see table).
- New test class files in `C:\Microsoft VS Code\GDRSandbox\force-app\main\default\classes\`: `BackfillLastShopifyOrderDateTest.cls` and `.cls-meta.xml`.
- Chat-only deliverables: the component list (10-08 09:59Z), the 15-line technical process and the 14-step business process (09-30), and the email-path explanation (09-30 10:18Z).

## 4. Process knowledge (as established in this session)

- **Last Shopify Order Date** (`Account.Last_Shopify_Order_Date__c`) is the latest `EffectiveDate` among the account's Orders that have a `Shopify_Order_Id__c`. It is read from Salesforce orders, and order amount is ignored. It is set by:
  - `ShopifyOrderSyncService` after each successful Shopify call for a store. The service also stamps `Last_Shopify_Order_Sync_Date__c = today`.
  - `BackfillLastShopifyOrderDate` (weekly safety net), for every account with a Shopify Company Id. It only writes when the value differs, and blanks the date if the account has no orders.
- **Order sync** is `ShopifyOrderSyncBatch`, scheduled twice daily:
  - "Shopify Order Sync Night", cron `0 0 3 * * ?`
  - "Shopify Order Sync Day", cron `0 0 10 * * ?`

  It processes Store Locations synced in the last 90 days or never synced, filtered on the Sync Date field. It does not check `Active__c`.
- **Last Order Date Refresh** is "Shopify Last Order Date Refresh" (`BackfillLastShopifyOrderDate`), cron `0 0 21 ? * SUN`, Sunday 9 PM.
- **R12/YTD calculation** is "Shopify R12 Sales Weekly" (`ShopifyR12SalesBatch` → `ShopifyR12SalesService`), cron `0 0 23 ? * SUN`, Sunday 11 PM. It covers all Store Locations with a Shopify Company Id, active or inactive. It calculates:
  - Current R12 = sales in the last 365 days
  - Prior R12 = sales in the 365 days before that
  - Decline ratio and R12 % = Current R12 / Prior R12. These are for scoring only.
  - Current YTD = 1 Jan to today
  - Prior YTD = 1 Jan last year to the same day last year
  - YTD % = Current YTD / Prior YTD × 100
  - `R12_Calculation_Last_Run__c` is stamped on each run.
- **At-risk flag**: `Shopify_Sales_At_Risk__c = true` when YTD % < 50. It is never set when Prior YTD = 0. Companies get rolled-up totals and their own flag. Known issue: the rollup is computed per 200-record batch chunk, so a company whose stores span two chunks can get a partial total.
- **Flow "Set At Risk Dates on Store Location"** (before-save, Account) runs when the R12 batch updates the account:
  - Newly at risk: sets `At_Risk_Since__c = today` and adds 1 to `At_Risk_Episode_Count__c`.
  - No longer at risk: clears `At_Risk_Since__c`.
- **Flow "Create At Risk Task for Account Owner"** (after-save) runs when the flag is true and `At_Risk_Since__c` has changed. It creates the task "Shopify sales at risk — contact this store" for the account `OwnerId`, Normal priority, due today. This happens once per episode. Company owners get one too, because the flow has no record-type filter. Ticking the checkbox by hand does not create a task.
- **Notice batch** `ShopifyAtRiskNoticeBatch` (Batch + Schedulable) is the scheduled job "Shopify At Risk Notices Daily", cron `0 0 5 * * ?`, time zone Asia/Kolkata (05:00 IST = 23:30Z the day before). It was created 2026-09-30 09:10Z by Ruben Smith. Before that it was unscheduled (09-29/09-30 checks). It selects:
  - Store Locations with a parent Company
  - `Active__c = true` and a Shopify Company Id
  - Last order 12 or more months ago
  - Name matching `Shopify_At_Risk_Config__mdt.Test_Store_Name_Filter__c` (`R12 WOT%` in the sandbox, which must be cleared for production)
- **Email stages** are counted from the last order date:
  - Email 1 = Month 12
  - Email 2 = Month 15
  - Email 3 = Month 17 (quotes the deactivation date = last order + 18 months)
  - Email 4 = Month 17 + 15 days ("15-Day Reminder")
  - Email 5 = Deactivation, at 18 months

  With `At_Risk_Mode__c = Every Stage`, Emails 1–4 are sent only if the store is flagged at risk. Risk: stores whose last order fell in the second half of a year can lose the flag in January and never get Email 3. "Entry Only" is a client decision.
- **Notice records**: the batch inserts one `Shopify_At_Risk_Notice__c` per contact per stage (via AccountContactRelation) with Status = Pending Send.
  - `Notice_Key__c` = contact + store + stage + last order date. It prevents duplicates, including after failed sends. To re-test a stage, delete the notices or change the last order date.
  - It snapshots YTD/R12 values, Months Inactive and Deactivation Date.
- **Email sending**:
  - Record-triggered flow "Send Shopify At Risk Notice" (after-create, Status = Pending Send) calls the invocable Apex `SendWarmOffEmail`.
  - `SendWarmOffEmail` picks the template by Stage (Template_Stage_1..5__c → "Warm Off 1..5"; legacy template if Stage is blank). It sends to the Contact from the org-wide address (sandbox: retailsupportuat@goodr.com) with the notice as WhatId, so merge fields fill in. It logs the activity and returns success or failure without throwing.
  - The flow then sets the notice to Notice Sent (Email_Sent__c, Notice_Date__c, Email_Subject__c) or Send Failed. Failed sends are not retried.
  - Apex is used because the flow's Send Email action did not fill merge fields from the notice (tested 28 Sep).
  - All of this happens in the same transaction as each batch chunk. So a manual `Database.executeBatch(new ShopifyAtRiskNoticeBatch(), 50)` sends emails too: the batch inserts notices and the flow sends them.
  - If notices are marked Sent but nothing arrives, check Setup → Deliverability.
- **Email 3 task**: when Email 3 notices are created, the batch creates "Retailer inactivity: 30-day deactivation warning sent" for the store owner, High priority, due in 7 days.
- **Deactivation** at 18 months, only if Email 3 was sent and `Auto_Offboard__c = true` (true since 09-30):
  - Sets `Active__c = false` and sends Email 5.
  - Sets Offboarding_Reason__c = "Store At Risk", Section 22 notes, Offboarding_Date__c, and Offboarded_By__c (from Offboard_Owner_Username__c).
  - Flow "Account – Auto-Populate Offboarding Date and User" also stamps the date and user. Its active org version is not in source.
  - `AccountTriggerHelper` sets the Company inactive if no active stores remain.
  - Stores without Email 3 are held. With Auto_Offboard off, notices go to Offboard Due.
- **Notice clean-up in `finish()`** covers all open notices:
  - Active store that has ordered again → Recovered (Recovered_Date__c).
  - Inactive store → Offboarded.
  - A store already sent Email 5 is skipped.
  - A store reactivated by hand without a new order gets no more emails.
  - Nothing reactivates an account automatically when a new order arrives. `ShopifyActivateStoreLocationQueueable` is only called from lead conversion.
- **Config** `Shopify_At_Risk_Config__mdt.Default` fields: Active__c, At_Risk_Mode__c, Auto_Offboard__c, Deactivation_Months__c (18), Reminder_Days__c (15, not read by the code, which hard-codes the value), Org_Wide_Email__c, Template_Stage_1..5__c, Email_Template_Name__c, Legacy_Notice_Enabled__c (false), Require_Opt_In__c, Exclude_Bounced__c, Test_Store_Name_Filter__c, Offboard_Reason__c, Offboard_Owner_Username__c.
- **Time zone**: all Shopify jobs are scheduled in Asia/Kolkata. "Sunday 11 PM" is about 10:30 AM Sunday Pacific, and the notice job's code comment says 5 AM Pacific. Re-create the production schedules in the intended time zone (unverified which one the client wants).

## 5. User requests (chronological, UTC)

1. 2026-09-29 05:48Z: Document how R12 sales calculation works, when Shopify At Risk Notice is created, when the batch runs and updates, when emails are sent, and when tasks are created and who they are assigned to. Verify all related flows, Apex, batches, fields and automations.
2. 2026-09-30 07:52Z: Questions: does the batch run for all or selected records; what if an account went inactive yesterday and has a new order today; when is the task created when Shopify At Risk is checked; where does Last Shopify Order Date come from.
3. 2026-09-30 08:09Z: Answer again based on the updated code, plus the process in 10–15 lines.
4. 2026-09-30 08:19Z: Pasted the 15-line process (assistant rewrote it as a 14-step business-reader version).
5. 2026-09-30 10:17Z: When running `Database.executeBatch(new ShopifyAtRiskNoticeBatch(), 50)` manually, why is email sent; explain SendWarmOffEmail, the flow and the notice batch.
6. 2026-10-08 09:55Z: List all flows, Apex classes, fields and components used for at-risk/offboard/notice, with names and comments, matching a shared screenshot.
7. 2026-10-08 10:00Z: Create it as a separate xlsx in the same deployment folder.
8. 2026-10-08 10:10Z: Verify the notice batch has a scheduled job in the sandbox.
9. 2026-10-08 10:15Z: Check all test classes exist and cover more than 80% without errors; update or create them as needed and produce an updated test-class deployment document.
