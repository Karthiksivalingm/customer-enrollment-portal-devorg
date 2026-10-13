# Goodr Salesforce: Change Log

Every change made to the Goodr orgs from **25 Sep 2026** onward, in date order. Times are **IST**.
Sources, cross-checked on 2026-10-13:
1. Each org's **DeployRequest** history: every deploy and validation, with its components.
2. The **Setup Audit Trail**: changes made in Setup.
3. The two **Claude Code session** transcripts.
4. Live **SOQL** checks of record data.

Raw evidence: [Org_Change_History/](Org_Change_History/) (generated CSVs and timeline) and [Session_Logs/](Session_Logs/) (per-session detail).

**Who / how**, used in the "By" column:
- **Session A**: Claude Code session on the Sales Channel / Sector work.
- **Session B**: Claude Code session on the Shopify At-Risk documentation and tests.
- **User (Setup)**: done by hand in Setup or Data Loader under the shared login `sandipp@goodr.com[.partial]` (shown as "Ruben Smith" in the org).

**Deploy process used by Session A:** check-only dry run → user approval ("Deploy to Sandbox") → deploy → verify.
Each dry-run ID is listed next to its deploy.

---

## Summary

| ID | Date | Org | Change | By | Status |
|---|---|---|---|---|---|
| CHG-01 | 09-25 → 10-01 | GDRSAND | Shopify At-Risk / Warm-Off offboarding build (fields, formulas, config, flow v2, 5 email templates) | User (Setup) + VS Code deploys | Done in sandbox |
| CHG-02 | 09-28 | GDRSAND | New Sector values added + field dependencies (4 objects) | User (Setup) | Done |
| CHG-03 | 09-28 → 10-05 | n/a | Impact analysis (read-only) | Session A | Done |
| CHG-04 | 09-30 | GDRSAND | Account field history tracking changed | User (Setup) | Done |
| CHG-05 | 10-05 | GDRSAND | New field Account.Order_Channel__c | User (Setup) | Done |
| CHG-06 | 10-06 | GDRSAND | Sales Channel value renamed Key Accounts → Key Account | User (Setup) | Done |
| CHG-07 | 10-06 | **GDRPROD** | Sales Channel value renamed Key Accounts → Key Account | User (Setup) | **Done in PRODUCTION** |
| CHG-08 | 10-06 | GDRSAND | Key Account references updated (5 deploys) | Session A | Done |
| CHG-09 | 10-06 | GDRSAND | New Sector values: 8 cluster rules + page filters | Session A | Done |
| CHG-10 | 10-07 | GDRPROD | Production validation (check-only, nothing saved) | Session A | Validated |
| CHG-11 | 10-08 | GDRSAND | Specialty CAN → Specialty (flow, tests, reports) | Session A | Done |
| CHG-12 | 10-08 | GDRSAND | Shopify test classes fixed + new BackfillLastShopifyOrderDateTest | Session B | Done |
| CHG-13 | 10-08 | **GDRPROD** | Lightning page "Case Record" changed | User (Setup) | Done in PRODUCTION (not in this repo's scope) |
| CHG-14 | 10-08 | GDRSAND | Old Sector values + Specialty CAN **deactivated**, dependencies updated | User (Setup) | Done |
| CHG-15 | 10-09 | GDRSAND | V1 backup fields created + admin FLS | Session A | Done |
| CHG-16 | 10-09 | GDRSAND | **Data:** V1 backfill (8,387 Accounts) | User (data load) | Done |
| CHG-17 | 10-09 | GDRSAND | V1 fields on pages; strict new-mapping page filters | Session A | Done |
| CHG-18 | 10-09 | GDRSAND | Cluster fix (Sector-only change + Sector cascade) | Session A | Done |
| CHG-19 | 10-09 → 10-13 | GDRSAND | **Data:** Account Sales Channel / Sector update (159 of 161 rows applied) | User (data load) | Done (see note) |
| CHG-20 | 10-12 | GDRPROD | Org setting `showDeveloperConsoleWithWebIdeOffOn` changed | User (Setup) | Done |
| CHG-21 | 10-12 → 10-13 | Git | GitHub repository created, organised, org synced | Session A | Done |

---

## CHG-01 · Shopify At-Risk / Warm-Off offboarding: sandbox build (25 Sep → 1 Oct)
**Why:** warn Shopify stores that stop ordering (warm-off emails at months 12/15/17/17+15 days) and deactivate them at 18 months.
How it works: [02_Knowledge_Base/Shopify_At_Risk_Offboarding.md](../02_Knowledge_Base/Shopify_At_Risk_Offboarding.md).
Production component list: `06_Deployment/Deployment_Documents/Shopify_AtRisk_Offboarding_Deployment_Document.xlsx`.

| Date / time | Change | How |
|---|---|---|
| 09-25 12:36 | Account field `Last_Shopify_Order_Sync_Date__c` (Date) created | Setup |
| 09-25 14:33 / 14:35 | Account formulas `Months_Since_Last_Order__c` (Number), `Scheduled_Deactivation_Date__c` (Date) created | Setup |
| 09-25 14:38 – 14:40 | `Shopify_At_Risk_Notice__c` fields `Stage__c` (picklist), `Months_Inactive_At_Notice__c`, `Last_Order_Date_At_Notice__c` + layout | Setup |
| 09-28 11:05 | `Shopify_At_Risk_Notice__c.Deactivation_Date__c` created | Setup |
| 09-28 13:08 | Account formula `Inactivity_Stage__c` (Text) created | Setup |
| 09-28 13:12 | Offboard Due Date formula changed to use Stage / Deactivation_Date__c | Setup |
| 09-28 14:17 | Notice `Status__c` value **Send Failed** added | Setup |
| 09-28 14:20 | Notice Key set as unique external ID (prevents duplicate notices) | Setup |
| 09-28 14:34 | `Shopify_At_Risk_Config.Default`: Template Stage 1–5 = Warm Off 1–5; At Risk Mode = Every Stage; Reminder Days = 15; Deactivation Months = 18; Test Store Name Filter = `R12%` | Setup |
| 09-28 15:27 | Flow `Send_Shopify_At_Risk_Notice` v2 activated (v1 deactivated). It now calls Apex `SendWarmOffEmail` | Deploy `0Afdx00000G3ISECA3` (earlier attempts `G3PVJCA3` and `G3RwvCAF` failed) |
| 09-28 16:06 – 16:08 | Email templates `Warm_Off_1_Check_In`, `Warm_Off_2_Early_Notice`, `Warm_Off_3_30_Day_Warning`, `Warm_Off_4_15_Day_Reminder`, `Warm_Off_5_Deactivation_Notice` | Deploys `G3SPxCAN`, `G3SWPCA3`, `G3SbFCAV`, `G3SeTCAV`, `G3Sg5CAF` |
| 09-29 13:13 / 09-30 11:15 | Test Store Name Filter → `R12 WO A%` → `R12 WOT%` (**must be cleared before production**) | Setup |
| 09-28 → 10-01 | `Auto_Offboard__c` switched on and off during testing. **Final value: on** (10-01 10:53) | Setup |
| 09-30 ~14:40 | Scheduled job **"Shopify At Risk Notices Daily"** (`ShopifyAtRiskNoticeBatch`, cron `0 0 5 * * ?`, Asia/Kolkata) created | Setup / Apex (by user) |
| 09-30 12:53 | Notice field **Offboard Due Date deleted** | Setup |
| 09-30 13:41 | `Scheduled_Deactivation_Date__c`: `Last_Shopify_Order_Date__c + 548` → `ADDMONTHS(Last_Shopify_Order_Date__c, 18)` | Setup |
| 09-30 13:42 | `Inactivity_Stage__c`: day-based → `ADDMONTHS` stages (Month 12 / 15 / 17 / 18+) | Setup |

The sandbox work also changed some content that the repo didn't have until the 13 Oct sync (CHG-21): the config gained At Risk Mode, Deactivation Months and Exclude Bounced, and the email wording was updated ("Hi {!Contact.FirstName}", Section 22 text).

## CHG-02 · New Sector values (28 Sep, Setup)
- 11:34: values **Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor** added to the global value set `Sector`.
  **Development** isn't in the approved mapping (see `05_Conflicts` CF-16).
- 11:41 – 11:44: Sector ← Sales Channel dependencies updated on Lead, Account, Contact and Opportunity.

## CHG-03 · Impact analysis (28 Sep → 5 Oct, read-only)
Session A retrieved the metadata into a scratch folder and produced `07_Technical_Documents/Impact_Analysis/Sector_SalesChannel_Impact_Analysis.xlsx`, including a Specialty CAN sheet. **No org changes.**

## CHG-04 · Field history tracking (30 Sep 15:03, Setup)
History tracking was turned **on** for Account fields Last Shopify Order Date, Shopify Ordering Enabled, Shopify Sales At Risk and YTD Performance Percent, and **off** for Vertical, Sport / Category and Website.

## CHG-05 · Order Channel field (5 Oct 12:28, Setup)
`Account.Order_Channel__c` (picklist) created. It's sandbox-only work that hasn't been approved for production.

## CHG-06 · Key Accounts → Key Account rename in the sandbox (6 Oct 10:45, Setup)
The label and API name were changed in the global value sets `Sales_Channel` and `Sales_Channel1`. Salesforce updated the records automatically.
Side effect: report filters that used "Key Accounts" lost that value.

## CHG-07 · Key Accounts → Key Account rename in PRODUCTION (6 Oct 11:48, Setup) ⚠
Same rename, done by hand in **GDRPROD**.
- Because of this, the production deployment step "rename the picklist value" is **already done**. The `KeyAccount_Rename_PROD` package (rules, team records, tests) should follow soon, because cluster rules that still say 'Key Accounts' no longer match any record.
- The production report `Accounts_without_NetSuite_Id` lost "Key Accounts" from its filter (REQ-020).

## CHG-08 · Key Account references (6 Oct, Session A)
| Time | Deploy (dry run) | Components | Result |
|---|---|---|---|
| 12:19 | `0Afdx00000GAgZSCA1` (`GAhnFCAT`) | Cluster rules Keys_Account_Account, Key_Account_Contact, Key_Account_Lead, Key_Account_Opp, Testtwoconditions → `Sales_Channel__c = 'Key Account'` | 5/5 |
| 12:22 | `0Afdx00000GAi4zCAD` (`GAgKwCAL`) | Pages Account_Company_Record_Page, Lead_Record_Page: Key Account section filter | 2/2 |
| 12:28 | `0Afdx00000GAiL7CAL` (`GAi8DCAT`; the test dry run `GAiBRCA1` showed 2 failures that already existed in ShopifyOrderSyncTest) | 9 test classes: 'Key Accounts' → 'Key Account' (24 lines) | 9/9 |
| 12:34 | `0Afdx00000GAijJCAT` (`GAfwkCAD`) | 116 `Account_Cluster_Team` records + `Account_Cluster_Team__mdt.Sales_Channel__c` (value added) | 117/117 |
| 12:38 | `0Afdx00000GAizRCAT` (`GAio9CAD`) | `ShopifyAssociationRetryBatch`: removed `AND Sales_Channel__c NOT IN ('Key Accounts')` (all channels now sync, matching the trigger handlers). Sandbox-only class | 1/1 |

Before snapshot: `Metadata_Before_Snapshots/2026-10-06_KeyAccount_Sector/`. Production package: `06_Deployment/Packages/KeyAccount_Rename_PROD`.

## CHG-09 · New Sector values in logic (6 Oct, Session A)
| Time | Deploy (dry run) | Components |
|---|---|---|
| 13:07 | `0Afdx00000GAl4TCAT` (`GAj4HCAT`, `GAkoLCAT`) | 8 new cluster rules: Specialty_Self_Service_Account/Lead/Opp/Contact (Cluster 6), Specialty_Planned_Account/Lead/Opp/Contact (Cluster 5). Additive; the old rules stay |
| 14:34 | `0Afdx00000GAp02CAD` (`GAihiCAD`) | Company and Lead pages: Specialty-Sellgoodr filter gets `Sector ≠ Planned`, Specialty-Bridge filter gets `Sector = Planned` |

Production package: `06_Deployment/Packages/Sector_NewValues_PROD`.

## CHG-10 · Production validation (7 Oct, Session A, check-only)
- 11:16: NoTestRun rejected by production. Nothing ran.
- 11:18: `0AfPn000002N1ALKA0`, 115 components, **failed**: "'Planned' is an invalid field value" on 2 pages. The picklist value doesn't exist in production yet.
- 11:19: `0AfPn000002N1BxKAK`, 113 components (without pages), **succeeded**, 17/17 tests. Check-only, so nothing was saved.

## CHG-11 · Specialty CAN → Specialty (8 Oct, Session A)
| Time | Deploy (dry run) | Components |
|---|---|---|
| 11:10 | `0Afdx00000GDSZyCAP` (`GDWorCAH`) | Flow `Lead_From_US_Retailer_Form_Assignment_And_Email`: the Canada path now sets Specialty (v4 active, v3 obsolete) |
| 11:15 | `0Afdx00000GDXEfCAP` (`GDX1lCAH`, 13/13 tests) | LeadConversionHandlerTest1, ShopifyAssociationSyncSchedulableTest |
| 11:28 | `0Afdx00000GDXrNCAX` (`GDXWPCA5`) | Reports Cluster3/Shopify_Accounts_CANSource_Cluster_3, Shopify_Accounts_Created_CAN_Cluster_3: logic `1 AND 2 AND 4 AND (3 OR (5 AND 6))` (Specialty + country CA) |

Verification on 11:33 – 11:58: anonymous Apex inserted test records and then rolled them back, so no data persisted. Full test run: 676 tests, 87% coverage. Before snapshot: `Metadata_Before_Snapshots/2026-10-08_SpecialtyCAN/`.

## CHG-12 · Shopify test classes (8 Oct 15:49, Session B)
Deploy `0Afdx00000GDn9lCAD`, 105 tests, 0 failures:
- **New** `BackfillLastShopifyOrderDateTest` (5 tests). Coverage of BackfillLastShopifyOrderDate: 0% → 97%.
- `ShopifyAtRiskNoticeBatchTest`: inserts the `Shopify_Configuration__c` test records and an HTTP mock.
- `ShopifyR12SalesTest`: corrected the assertion for the 31-Dec order (Prior YTD) and added a year-end guard.
- `ShopifyOrderSyncTest`: now expects `Last_Shopify_Order_Sync_Date__c`; the pricebook activation retries on row lock.

All 5 earlier failures were in the tests, not the classes. Detail: [Session_Logs/2026-09-29_to_10-08_Session_B_Shopify_AtRisk.md](Session_Logs/2026-09-29_to_10-08_Session_B_Shopify_AtRisk.md).

## CHG-13 · PRODUCTION Case Record page (8 Oct 15:08, Setup)
Lightning page "Case Record" changed in GDRPROD. This isn't part of the Sales Channel / Sector work. It's recorded so it isn't missed.

## CHG-14 · Old values deactivated (8 Oct, Setup)
- 12:07: Specialty CAN deactivated, then reactivated. Dependencies updated.
- 18:24 – 18:34: Sector values **Sellgoodr USA, Core, Mid-Market, Off-Price, Bridge, Sellgoodr CAN, Global** deactivated, and the Sector picklist reordered.
- 18:35 – 18:36: **Specialty CAN** deactivated in Sales Channel and Sales Channel1. Dependencies updated on all 4 objects.
- The user confirmed on 9 Oct that this was intentional. Effect: page filters can't reference these values any more (see CHG-17).

## CHG-15 · V1 backup fields (9 Oct 09:49, Session A)
Deploy `0Afdx00000GEjosCAD` (dry run `GEnxJCAT`): `Account.Sales_Channel_V1__c` and `Account.Sector_V1__c` (Text 50, help text "do not edit"), System Administrator Read/Edit.
Text was chosen over picklist so any old value can be stored.

## CHG-16 · DATA: V1 backfill (9 Oct, from about 10:05, user)
**8,387 Accounts** have `Sales_Channel_V1__c` filled (verified 2026-10-13). The load was done by the user outside the Claude sessions.
3 accounts had no V1 at 11:35. `Data_Changes/.../1_V1_Backfill_DataLoader.csv` was prepared for them.

## CHG-17 · Pages: V1 fields and strict filters (9 Oct, Session A)
| Time | Deploy (dry run) | Components |
|---|---|---|
| 10:03 | `0Afdx00000GEoOjCAL` (`GEoJtCAL`; `GEo8bCAD` and `GEoLVCA1` failed on the inactive "Bridge") | Store Location and Franchise pages: V1 fields after Sector in Details |
| 10:15 | `0Afdx00000GEotNCAT` (`GEmQBCA1`, `GEoq9CAD`; `GEoi5CAD` and `GEojhCAD` failed) | Company page: old-value filters replaced (Sellgoodr = Specialty AND Self Service; Bridge = Specialty AND Planned; Key Account; Partnerships; Global) + V1 fields |
| 10:20 | `0Afdx00000GEp9VCAT` (`GEoyDCAT`) | Lead page: same filters; Convert = Sales Channel ≠ Specialty AND Status = Qualified |

Before snapshot: `Metadata_Before_Snapshots/2026-10-09_V1_Fields_PageFilters/`.

## CHG-18 · Cluster fix (9 Oct 10:34, Session A)
**Problem (reported by the user):** a Specialty / Self Service account stayed in Cluster 5. Live testing found two bugs:
1. Changing only the Sector didn't re-cluster the record.
2. Saving an Account with open Opportunities failed with an invalid dependent Sector.

Deploy `0Afdx00000GEpsfCAD` (dry run `GEpUTCA1`, 119/119 tests; coverage ClusterRuleEngine 93%, AccountCascadeHandler 100%, LeadConversionHandler 88%):
- `ClusterRuleEngine` re-evaluates when Sales Channel **or** Sector changes (safe getter for objects without Sector).
- `AccountCascadeHandler` and `LeadConversionHandler` copy Sector to open Opportunities.
- Tests: `ClusterRuleEngineTest` and `AccountCascadeHandlerTest` each gained one test.

Re-check, rolled back afterwards: 32 cluster/team checks, 0 mismatches. Before snapshot: `Metadata_Before_Snapshots/2026-10-09_ClusterFix/`.

## CHG-19 · DATA: Account Sales Channel / Sector update in the sandbox (9 → 13 Oct, user)
Verified 2026-10-13 against `Data_Changes/DataMigration_Account_Sandbox/2_Account_Update_DataLoader.csv`:
- **159 of 161 rows** in the org match the new values. 163 Accounts now hold new Sector values: Self Service 131, Planned 11, Enterprise 10, Distributor 7, Strategic 4.
- 2 rows differ because those records were changed to other values afterwards: **Missoula Scheels** (file Key Account/Enterprise, org Partnerships/Partnerships) and **Test TVK** (file Key Account/Strategic, org Global/Distributor).
- 3 test accounts not in the file (R12 Test Company Sandbox, Test Team, R12 WOT T6 Late) also hold new values.
- Exact load time is unknown, because Sector has no field history. Accounts were last modified by the shared login on 10-09 (44), 10-11 (1) and 10-13 (118).
- Contact, Opportunity: no records on the new Sector values yet. Lead: 1 (Distributor).
- Rollback file: `3_Account_Rollback_DataLoader.csv`.

## CHG-20 · Production org setting (12 Oct 12:59, Setup)
`showDeveloperConsoleWithWebIdeOffOn` changed in GDRPROD. This isn't related to this project.

## CHG-21 · Repository (12 → 13 Oct, Session A)
- **10-12 19:27:** private GitHub repo created; commit `c2b6b3e`.
- **10-12 19:36:** organised as the "Goodr" project; commit `d591374`.
- **10-12 19:54:** 7 folders created; NetSuite credential records removed from tracking; commit `b7561dd`.
- **10-13 (repo synced to the org):** every class, trigger, flow, page and custom metadata record, plus the touched objects, fields, value sets and email templates, was retrieved from GDRSAND at API 68.0 (`manifest/retrieve/pkg_full_sync_20261013.xml`). The repo now matches the org.

  Real differences found and now fixed in the repo:
  - Shopify config: new settings in the org.
  - Warm-Off email wording.
  - `Send_Shopify_At_Risk_Notice`: the local file was a newer **undeployed** edit, now replaced by the org's active version. The old local file is still in git history at commit `b7561dd`.
  - Contact pages: fields `Account_Name_for_Email__c` and `Shopify_Company_ID_for_Email__c`.

  New in the repo: global value sets `Sales_Channel`, `Sales_Channel1` and `Sector`; Sales Channel / Sector fields on 4 objects; the `Shopify_At_Risk_Notice__c` object; the Shopify Account fields.

## CHG-22 · Credential hardening in the repository (13 Oct, Session A)
No org change. NetSuite credential custom metadata had been committed in the first two commits (old IDs `88fb123` and `246a9f2`). On 13 Oct:
- added placeholder templates (`07_Technical_Documents/Secure_Config_Templates/`, every value `SET_IN_ORG__<field>`) and checked that none of the real values appear in them;
- added the pre-commit hook `scripts/git-hooks/pre-commit`, which blocks credential files and secret-looking values (tested: it blocks the NetSuite file);
- added `.gitattributes` so the hook keeps LF line endings;
- **purged the history** (user approved): the 2 files were removed from every commit with `git filter-branch` and pushed with `--force-with-lease`. Every commit ID changed: `88fb123→c2b6b3e`, `246a9f2→d591374`, `7ced5d5→b7561dd`, `e3ab771→7dae7eb`. Checked: none of the 6 secret values appears in any commit. A backup bundle of the old history was kept locally (not in the repo).

**Still open:**
- Rotate the NetSuite sandbox keys (NetSuite admin).
- GitHub still serves the old commits to anyone with their exact ID until its clean-up runs. GitHub Support can remove them immediately. The repo is private.

## CHG-23 · Repository best-practice setup (13 Oct, Session A)
No org change.
- **GitHub settings:** added the repo description and topics, turned the wiki off, and set branches to be deleted after merge. Secret scanning isn't available on a free private repo; the pre-commit hook covers that gap.
- **`.github/`:** pull request checklist, issue templates (requirement, bug/conflict) and CODEOWNERS.
- **`CONTRIBUTING.md`, `.editorconfig`;** `.vscode/` gained recommended extensions and search/file settings.
- **`scripts/`:** samples moved to `samples/`; the one-off workbook builders moved to `doc-builders/archive_2026-10_workbook_builders/`; README added. `manifest/README.md` added.
- **Hook:** now also runs the project's lint-staged step when Node is installed.
- **Tag:** `sandbox-baseline-2026-10-13` marks the cleaned history, fully synced with GDRSAND.

---

## Before 25 Sep 2026
Changes from 3 Aug to 24 Sep (464 Setup Audit Trail entries: Apex classes, the Case management build, the first version of Shopify At Risk Config on 08-21, and Lightning pages) came before the Claude sessions in this repo. They're listed day by day in [Org_Change_History/Org_Change_History.md](Org_Change_History/Org_Change_History.md), with CSVs alongside.

## How to keep this log complete
1. After each change, add a CHG entry here: date, time, deploy ID, components, why, and the result.
2. Once a week, or before any production deployment, re-run
   `powershell -ExecutionPolicy Bypass -File scripts/doc-builders/build_org_change_history.ps1`
   and compare the result against this log. Salesforce keeps deploy history for about 30 days and audit history for 180 days.
3. Commit and push.
