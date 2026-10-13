# Conflicts Log

Part A lists conflicts we **faced** and how each was resolved. Part B lists **possible** conflicts to check before
every change or deployment. Add new entries at the bottom of the matching table.

## A. Conflicts faced

| ID | Area | Conflict | Resolution |
|---|---|---|---|
| CF-01 | Production deploy | Production rejects `--test-level NoTestRun`, and `deploy validate` requires tests | Use `RunSpecifiedTests` with one `--tests` flag per class (a comma list is rejected) |
| CF-02 | Production deploy | Page validation failed on `Planned` and `Key Account` because the picklist values don't exist in production yet | Create the picklist values first, then deploy pages. Validate the non-page components separately (113 components, job `0AfPn000002N1BxKAK`, passed) |
| CF-03 | Pages | After the old Sector values were deactivated (8 Oct), Company and Lead page deploys failed: deactivated values can't be used in visibility filters | Rebuilt the filters using only the new mapping (Sellgoodr section = Specialty AND Self Service, Bridge section = Specialty AND Planned) |
| CF-04 | Sandbox vs production | Sandbox pages contain unapproved work (R12, Fulfillment, YTD/inactivity, Tiers fields) | Production packages are built from **production's own files** plus only the approved change |
| CF-05 | Sandbox vs production | Team records differ (production uses different users) | Built the 116 production team records from production files and kept production users |
| CF-06 | Sandbox vs production | `ShopifyAssociationRetryBatch` doesn't exist in production | Left out of the production package |
| CF-07 | Sandbox vs production | `AccountCascadeHandler` in the sandbox has `System.enqueueJob(new ContactTeamReassignQueueable(...))`, which isn't part of this work and isn't in production | Kept as is in the sandbox. Decision pending (REQ-022) |
| CF-08 | Logic | The cluster stayed at 5 when only the Sector changed (Specialty / Self Service should be 6) | `ClusterRuleEngine` now re-evaluates when Sales Channel **or** Sector changes |
| CF-09 | Logic | Saving an Account with open Opportunities failed with an invalid dependent Sector | `AccountCascadeHandler` and `LeadConversionHandler` now sync Sector to open Opportunities |
| CF-10 | Sandbox data | Sandbox Opportunity record types don't include Specialty CAN, so inserting an Opportunity failed | This was already the case before this work, and only in the sandbox. Not changed |
| CF-11 | Tests | 2 `ShopifyOrderSyncTest` methods fail in the sandbox | Already failing before this work, sandbox only. Not part of this change |
| CF-12 | Users | `planda@goodr.com` (Global, Cluster 7, Sales Director) is inactive, so the Global team has 4 members | `ClusterTeamEngine` skips inactive users by design. The user record needs an admin decision |
| CF-13 | Reports | Renaming a picklist value in Setup removes the old value from report filters | The Cluster 3 CAN reports were rebuilt with Billing Country = CA logic. Check the other reports after renames |
| CF-14 | Security | NetSuite credential custom metadata was committed to git (first two commits, old IDs 88fb123 and 246a9f2) | 2026-10-12: removed from tracking, git-ignored and force-ignored. 2026-10-13: placeholder templates and a pre-commit hook added. 2026-10-13: history purged and force-pushed (commit IDs changed). **Open: rotate the NetSuite sandbox keys; ask GitHub Support to purge the cached old commits** |

| CF-15 | Production | Sales Channel "Key Accounts" was renamed to "Key Account" by hand in **production** on 2026-10-06 11:48, before the rest of the Key Account package | Rename step is already done in prod. Deploy `KeyAccount_Rename_PROD` (cluster rules, team records) soon: prod cluster rules still say 'Key Accounts' and no longer match. Fix the report filters (REQ-020) |
| CF-16 | Picklist | Sector value **Development** was added on 2026-09-28 but is not in the approved mapping | Confirm with the client: keep, map or deactivate |
| CF-17 | Repo vs org | On 2026-10-13 the repo did not match the org: Shopify config, Warm-Off email text, Contact pages and an **undeployed** local edit of `Send_Shopify_At_Risk_Notice` | Repo re-synced from the org (CHG-21). Always retrieve before editing, and log Setup changes in the change log |
| CF-18 | API version | Retrieving with manifest version 59.0 dropped newer flow and page elements (styleProperties, areMetricsLoggedToDataCloud) | Use `<version>68.0</version>` in retrieve manifests |
| CF-19 | Data | Sandbox Account update: 2 of the 161 rows (Missoula Scheels, Test TVK) were later changed to other values; the exact load time is unknown because Sector has no history | Keep Data Loader success files. Consider field history on Sector during the migration |
| CF-20 | Shopify At-Risk | Sandbox-only settings: Test Store Name Filter `R12 WOT%`, schedules in IST | Clear the filter and set schedules in the agreed time zone before production |

## B. Possible conflicts (check before each change)

| ID | Risk | Where | What to do |
|---|---|---|---|
| PC-01 | **Order of the cluster fix and the data load in production.** 71 Key Account accounts with manual clusters 2/3/8 would be reset to Cluster 1 if the fix is deployed before the data load | Production | Load the data first, or restore the manual clusters afterwards |
| PC-02 | 346 production Specialty CAN companies have no Billing Country | Production data | Fill the country before the CAN reports / mapping rely on it |
| PC-03 | Several triggers on one object, and Salesforce doesn't guarantee their order | Account (AccountTrigger + AccountClusterTrigger), Lead (LeadTrigger + LeadClusterTrigger), Contact (2), Case (4), EmailMessage (3) | Don't rely on one trigger running before another. Test the full save |
| PC-04 | `ClusterRuleEngine` uses the **first matching rule** with no ordering | `Sales_Channel_Cluster__mdt` | Rules must never overlap for the same object |
| PC-05 | Flow `Opportunity_field_update_from_Account` (before-save) and `AccountCascadeHandler` both set Sales Channel / Sector / Cluster on Opportunity | Opportunity | Change both together, or the values may disagree |
| PC-06 | `Lead_From_US_Retailer_Form_Assignment_And_Email` is after-save with no fault path, so any failure rolls back the Lead insert from Typeform | Flow | Add a fault path before making further changes |
| PC-07 | The Shopify classes call four different Admin API versions (2023-10, 2024-01, 2024-04, 2026-04). Older versions get retired by Shopify | Shopify integration | Align them on a supported version |
| PC-08 | Flows in InvalidDraft / Obsolete status (e.g. `Account_Cluster_Automation`, `Map_Lead_Source_to_Account_on_Conversion`) | Flows | Don't activate them without review; they may duplicate Apex logic |
| PC-09 | Deactivated picklist values can't be used in page filters, and record types must list the new values | Pages, record types | Add the values to record types before data loads |
| PC-10 | Report filters lose renamed values silently | Reports / dashboards | Re-check the reports listed in the where-used workbook after each picklist change |
| PC-11 | Shopify company rollup is calculated per 200-record batch chunk; a company split across chunks gets partial R12/YTD totals | `ShopifyR12SalesBatch` | Fix before relying on company-level at-risk flags |
| PC-12 | With At Risk Mode = Every Stage, a store can lose the at-risk flag in January and never get Email 3, which blocks deactivation | Shopify At-Risk | Client decision: Every Stage vs Entry Only |
| PC-13 | Running `ShopifyAtRiskNoticeBatch` by hand sends real emails | Sandbox / production | Only run it with the test-store filter set, or with Deliverability off |
