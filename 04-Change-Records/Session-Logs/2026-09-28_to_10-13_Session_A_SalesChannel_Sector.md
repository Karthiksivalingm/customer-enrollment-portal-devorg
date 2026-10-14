# Change history: session d08dd3dc (2026-09-28 to 2026-10-13)

Source: `C:\Users\UTIS LAPTOP 377\.claude\projects\c--Microsoft-VS-Code-GDRSandbox\d08dd3dc-7817-4434-9679-5763d2940328.jsonl`
Times are IST (UTC+5:30), converted from transcript UTC timestamps. They match the org's DeployRequest and Setup Audit Trail times, which the session queried on 2026-10-13.
Credentials: the user's GitHub password, posted in chat on 2026-10-12, is shown here as [redacted].

## Important scope finding

**This session did NOT do the Shopify At-Risk / Warm-Off offboarding work.** From 2026-09-28 to 2026-10-05 it only did read-only analysis of the Sales Channel and Sector picklists and built workbooks. It made no deploys, ran no anonymous Apex and changed no data in that window.

The Shopify At-Risk changes in GDRSAND were made by Setup UI actions and by the other session, `c6dfcc34-dca0-4c56-b4cf-ef2ceeb71d02.jsonl`, which started 2026-09-29. That other session's user messages are about R12, the at-risk notice and batch documentation, and test classes. This session only **observed** those changes on 2026-10-13, when it queried the org history. They are listed in Appendix A for reference and are not attributed to this session.

## 1. Change table (actions performed by or in this session)

| Date-time (IST) | Org | What changed (components) | How | Why (user request) | Outcome |
|---|---|---|---|---|---|
| 2026-09-28 19:23 – 19:52 | local / claude.ai | Claude Doc "Goodr Sector Field Replacement – Impact Analysis" (artifact 532f35de-…); `C:\Microsoft VS Code\GDRSandbox\Sector_SalesChannel_Impact_Analysis.xlsx` | Read-only `sf project retrieve` from GDRSAND into the scratchpad, then Excel COM via PowerShell | Find where Sector and Sales Channel old values are used and the impact of replacing them | Success (no org change) |
| 2026-09-29 18:42 | none | Time estimate only (40–60 h) | Chat | Estimate the effort | n/a |
| 2026-10-05 12:03 – 12:20 | local | Impact workbook regenerated: new "Specialty CAN" sheet, Sector V2 approach | Excel COM | Impact of removing Specialty CAN; separate sheet | Success. The first retry hit a file lock from a hidden Excel instance |
| 2026-10-06 12:16 / 12:19 | GDRSAND | CustomMetadata Sales_Channel_Cluster: Keys_Account_Account, Key_Account_Contact, Key_Account_Lead, Key_Account_Opp, Testtwoconditions → `Sales_Channel__c = 'Key Account'` | Dry run 0Afdx00000GAhnFCAT, then deploy **0Afdx00000GAgZSCA1** | User renamed "Key Accounts" to "Key Account" in Setup; replace references (step 1.1) | Success, 5/5 |
| 2026-10-06 12:20 / 12:22 | GDRSAND | FlexiPage Account_Company_Record_Page, Lead_Record_Page: "Key Account" section filter Key Accounts → Key Account | Dry run 0Afdx00000GAgKwCAL, deploy **0Afdx00000GAi4zCAD** | Key Account rename (1.2) | Success, 2/2 |
| 2026-10-06 12:24 / 12:28 | GDRSAND | 9 test classes: AccountCascadeHandlerTest, ClusterRuleEngineTest, ClusterTriggerTest, ContactTriggerHandlerTest, LeadConversionHandlerTest, LeadConversionHandlerTest1, ShopifyAddressSyncTest, ShopifyOrderSyncTest, ShopifySalesSyncServiceTest ('Key Accounts' → 'Key Account', 24 lines) | Dry run 0Afdx00000GAi8DCAT. Dry run with tests 0Afdx00000GAiBRCA1 failed: 139/141, 2 pre-existing ShopifyOrderSyncTest failures. Deploy **0Afdx00000GAiL7CAL** (NoTestRun) | Key Account rename (1.3) | Success, 9/9. Post-deploy run 143/145 (same 2 pre-existing failures) |
| 2026-10-06 12:30 / 12:34 | GDRSAND | 116 Account_Cluster_Team__mdt records → Key Account; field Account_Cluster_Team__mdt.Sales_Channel__c (added value "Key Account") | Dry run 0Afdx00000GAfwkCAD, deploy **0Afdx00000GAijJCAT** (`-x pkg_step1_5.xml`) | Key Account rename (1.5) | Success, 117/117 |
| 2026-10-06 12:36 / 12:38 | GDRSAND | ApexClass ShopifyAssociationRetryBatch: removed `AND Sales_Channel__c NOT IN ('Key Accounts')` | Dry run 0Afdx00000GAio9CAD, deploy **0Afdx00000GAizRCAT** (NoTestRun) | Key Account rename (1.4). "Must not affect existing logic": follows the AccountTriggerHandler and ContactTriggerHandler pattern (all channels sync) | Success, 1/1. This class doesn't exist in production |
| 2026-10-06 12:39 – 13:07 | GDRSAND | 8 new Sales_Channel_Cluster CMDT rules: Specialty_Self_Service_Account/Lead/Opp/Contact (Cluster 6), Specialty_Planned_Account/Lead/Opp/Contact (Cluster 5) | Dry runs 0Afdx00000GAj4HCAT and 0Afdx00000GAkoLCAT, deploy **0Afdx00000GAl4TCAT** | Sector replacement, additive (2.1) | Success, 8/8 |
| 2026-10-06 13:09 / 14:34 | GDRSAND | FlexiPage Account_Company_Record_Page, Lead_Record_Page: Specialty-Sellgoodr filter gets criterion 4 `Sector ≠ Planned`; Specialty-Bridge filter gets `Sector = Planned` | Dry run 0Afdx00000GAihiCAD, deploy **0Afdx00000GAp02CAD** | Sector replacement (2.2) | Success, 2/2 |
| 2026-10-06 12:45 – 16:00 | local | `deployment\KeyAccount_Rename_Deployment_Document.xlsx` (Key Account section, later a Sector section); `deployment\KeyAccount_Rename_PROD\` (116 members, built from **production** files), `KeyAccount_Rename_PROD_ROLLBACK\`, `Sector_NewValues_PROD\` and its rollback (with destructiveChangesPost.xml) | Read-only `sf project retrieve` from GDRPROD, plus Excel COM | Production deployment document | Success. One save was blocked because the workbook was open in Excel; the user closed it |
| 2026-10-07 10:50 – 11:00 | local | `Sector_Where_Used_Analysis.xlsx` | Excel COM | Where-used list for the Sector field, as Excel | Success |
| 2026-10-07 11:16 – 11:17 | GDRPROD | Combined package of 115 components (KA rules, 100 team records with prod users, team picklist field, 8 Sector rules, 2 pages) | `sf project deploy validate --test-level NoTestRun` and `deploy start --dry-run NoTestRun` | Validate the change set in production; "should not fail" | Rejected: CLI enum / "NoTestRun cannot be used in production". Nothing ran |
| 2026-10-07 11:18 | GDRPROD | Same 115 components | Check-only validate, RunSpecifiedTests (ClusterTeamEngineTest, ContactClusterTriggerTest), job **0AfPn000002N1ALKA0** | Same | **Failed**: 2 FlexiPages, "'Planned' is an invalid field value" (production lacks the picklist values) |
| 2026-10-07 11:19 | GDRPROD | 113 components (without FlexiPages) | Check-only validate, job **0AfPn000002N1BxKAK** | Same | **Succeeded**: 113/113, 17/17 tests. Check-only, nothing saved. The session said an outbound change set can only be built in the Setup UI |
| 2026-10-08 11:02 / 11:10 | GDRSAND | Flow Lead_From_US_Retailer_Form_Assignment_And_Email: Canada path Specialty CAN → Specialty (v4 active, v3 obsolete) | Dry run 0Afdx00000GDWorCAH, deploy **0Afdx00000GDSZyCAP** | Specialty CAN replacement, step C1 | Success, 1/1 |
| 2026-10-08 11:11 / 11:15 | GDRSAND | ApexClass LeadConversionHandlerTest1, ShopifyAssociationSyncSchedulableTest: 'Specialty CAN' → 'Specialty' | Dry run 0Afdx00000GDX1lCAH (13/13 tests), deploy **0Afdx00000GDXEfCAP** | Specialty CAN, step C2 | Success, 2/2; tests 13/13 |
| 2026-10-08 11:19 / 11:28 | GDRSAND | Report Cluster3/Shopify_Accounts_CANSource_Cluster_3_Abw and Cluster3/Shopify_Accounts_Created_CAN_Cluster_3_k2J: logic `1 AND 2 AND 4 AND (3 OR (5 AND 6))` (Specialty plus country CA, additive) | Dry run 0Afdx00000GDXWPCA5, deploy **0Afdx00000GDXrNCAX** | Specialty CAN, step C3 | Success, 2/2 |
| 2026-10-08 11:33 – 11:58 | GDRSAND | None (verification) | Anonymous Apex `verify_cluster.apex` (in-memory, no DML); `verify_live_rollback.apex` (inserts, then a forced exception, so everything rolls back); full local test run (676 tests, 13 failing, 87% coverage) | Verify old and new mappings both work | Rolled back / read-only. Created-today counts were the same before and after (0) |
| 2026-10-08 11:38 – 11:40 | local | `deployment\SpecialtyCAN_Phase1_PROD\` and rollback (built from production files; reports in folder Cluster6); deployment doc Specialty CAN section | Read-only retrieve from GDRPROD, Excel COM | Specialty CAN deployment doc | Success |
| 2026-10-08 11:50 – 09:37 (10-09) | local | `QA_Test_Scenarios_KeyAccount_Sector_SpecialtyCAN.xlsx` (36 test cases) | Excel COM | QA UI test pack | Success |
| 2026-10-09 09:49 | GDRSAND | CustomField Account.Sales_Channel_V1__c and Account.Sector_V1__c (Text(50), with help text); System Administrator profile field-level security Read/Edit | Dry run 0Afdx00000GEnxJCAT, deploy **0Afdx00000GEjosCAD** (`--metadata-dir deploy_v1_fields_1009`) | Admin-only backup fields for old values (Text recommended over picklist) | Success, 3/3 |
| 2026-10-09 09:56 – 10:03 | GDRSAND | FlexiPage Account_Store_Location_Record_Page1, Account_Franchise_Record_Page1: V1 fields after Sector in the details section | Failed dry runs 0Afdx00000GEo8bCAD and 0Afdx00000GEoLVCA1 (Company page: inactive "Bridge" in filter); dry run 0Afdx00000GEoJtCAL; deploy **0Afdx00000GEoOjCAL** | Add V1 fields to the page for testing | Success, 2/2. Company page left unchanged at that point |
| 2026-10-09 10:10 – 10:15 | GDRSAND | FlexiPage Account_Company_Record_Page: old-value filters replaced by the strict new mapping (Sellgoodr = Specialty AND Self Service; Bridge = Specialty AND Planned; Key Account; Partnerships; Global); V1 fields added | Failed dry runs 0Afdx00000GEoi5CAD and 0Afdx00000GEojhCAD; dry runs 0Afdx00000GEmQBCA1 and 0Afdx00000GEoq9CAD; deploy **0Afdx00000GEotNCAT** | "remove the old filter and replace with new field mapping filter" | Success, 1/1 |
| 2026-10-09 10:17 / 10:20 | GDRSAND | FlexiPage Lead_Record_Page: same strict filters; Convert button = Sales Channel ≠ Specialty AND Status = Qualified | Dry run 0Afdx00000GEoyDCAT, deploy **0Afdx00000GEp9VCAT** | Same | Success, 1/1 |
| 2026-10-09 10:26 – 10:28 | GDRSAND | None (verification) | Anonymous Apex `verify_cluster_team.apex` (live inserts and updates, rolled back by StopAndRollbackException). The first run hit a DmlException (CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY), so no commit | User reported Specialty/Self Service account still in Cluster 5 | Found 2 bugs: Sector-only change didn't re-cluster; Account Sales Channel change failed with open Opportunities (invalid dependent Sector) |
| 2026-10-09 10:30 / 10:34 | GDRSAND | ApexClass ClusterRuleEngine (re-evaluates when Sales Channel **or** Sector changes; safeGet), AccountCascadeHandler (cascades Sector to open Opps), LeadConversionHandler (same Sector sync), ClusterRuleEngineTest and AccountCascadeHandlerTest (+1 test each) | Dry run 0Afdx00000GEpUTCA1 (119/119 tests; coverage 93% / 100% / 88%), deploy **0Afdx00000GEpsfCAD** (NoTestRun) | Fix cluster assignment for the new values | Success, 5/5. The rolled-back re-check gave 32 checks, 0 wrong clusters |
| 2026-10-09 10:48 – 11:20 | GDRSAND / local | `QA_Cluster_Team_Assignment_Reference.xlsx`, `QA_LRP_Sections_by_SalesChannel_Sector.xlsx` | Anonymous Apex `verify_team_roles.apex` (rolled back), Excel COM | QA reference sheets | Success. 32 rows, 0 team mismatches (except the inactive planda@goodr.com) |
| 2026-10-09 11:33 – 11:56 | local | `deployment\DataMigration_Account_Sandbox\`: 1_V1_Backfill_DataLoader.csv (3 rows), 2a_Account_Update_PILOT_DataLoader.csv (7), 2_Account_Update_DataLoader.csv (161), 3_Account_Rollback_DataLoader.csv (161), Account_SalesChannel_Sector_Update_Sandbox.xlsx, SalesChannel_Sector_Records_To_Update_Sandbox.xlsx (989 records, 312 ready) | Read-only SOQL plus Excel COM | Prepare the data update (Mid-Market → Strategic) | Files only. **The session did not load any data** |
| 2026-10-09 12:22 – 12:25 | local | `ChangeSet_Component_List.xlsx` (44 components) | Read-only comparison against GDRPROD | Outbound change set request (the session can't create one by CLI) | Success. Flagged that AccountCascadeHandler has an unrelated sandbox line (`System.enqueueJob(new ContactTeamReassignQueueable(...))`) |
| 2026-10-09 13:05 – 13:18 | none | Advice only: production page "Option A" (build from production pages, exclude R12 and other unapproved fields); data-load considerations from the client's answers | Read-only GDRPROD queries | Client answers / R12 fields | n/a |
| 2026-10-12 19:02 – 19:28 | local machine | Installed Git and GitHub CLI via winget; `gh auth login` (device flow) as yogemani; `gh auth setup-git`; global git identity | winget / gh | User asked for GitHub login. The user posted a password ([redacted]); the session did not use it and advised changing it | Success |
| 2026-10-12 19:27 – 19:28 | local / GitHub | `git init`; private repo https://github.com/yogemani/GDRSandbox; commit `88fb123` (1,420 files) pushed | git / gh | "Create GDRSandbox as a repository" | Success. A secret scan found no real secrets |
| 2026-10-12 19:33 – 19:36 | local / GitHub | Repo reorganised as the "Goodr" project (sfdx-project.json and package.json renamed; docs/, backups, scripts moved in); commit `246a9f2` pushed | git mv / commit / push | "arrange this all into proper one, project name Goodr" | Success |
| 2026-10-12 19:40 – 19:54 | local / GitHub | Restructured into 01_Instructions … 07 folders (plus root CLAUDE.md, Knowledge Base, Requirements, Change Records, Conflicts_Log.md, Deployment, Technical Documents); commit `7ced5d5` pushed | Write and git | User's 7-folder structure | Success |
| 2026-10-13 12:02 – 12:13 | GDRSAND (read) / local | Queried DeployRequest (46 since 25 Sep) and the Setup Audit Trail in both orgs. Ran `git checkout -- force-app; git clean -fd force-app`, then a full retrieve (`manifest/retrieve/pkg_full_sync_20261013.xml`, version changed 59.0 → 68.0) **into force-app**, which overwrote local files with the org versions | sf retrieve, git | "all changes ... stored in github with correct date, no changes missed" | Retrieve succeeded. Drift shows in Shopify_At_Risk_Config.Default, Warm_Off_1..5 templates, BackfillLastShopifyOrderDateTest, several pages and flows. Not committed when the transcript ends (unverified) |

## 2. Data changes

- **No record inserts, updates or deletes made by this session persisted in either org.**
  - Every anonymous Apex run that did DML (`verify_live_rollback.apex`, `verify_cluster_team.apex`, `verify_team_roles.apex`) ended in a forced exception (Divide by 0, later `StopAndRollbackException`) or failed at compile or DML. All were rolled back.
  - Count checks before and after (Leads, Accounts and Opps created today) showed 0 → 0.
  - `verify_cluster.apex` used in-memory records only.
- Apex test runs (`sf apex run test`, dry-run deploys with tests) don't persist data.
- Picklist rename side effect (Setup UI, by the user, not this session): renaming Sales Channel "Key Accounts" → "Key Account" in GDRSAND on 2026-10-06 10:45 IST, and in GDRPROD on 2026-10-06 11:48 IST, automatically updated every record holding that value (record counts not captured). It also removed "Key Accounts" from report filters; for example, the prod report Accounts_without_NetSuite_Id_hg8 now has only "Key Account CAN".
- **Account V1 backfill (by the user, outside this session; unverified time and tool):**
  - At 2026-10-09 11:35 IST the session found 8,387 GDRSAND Accounts with Sales_Channel_V1__c filled and 172 with Sector_V1__c filled. Those fields were created at 09:49 IST that day.
  - 3 Accounts were still missing V1. The session prepared a backfill CSV but did not load it.
- Data Loader files for 161 Account updates (plus a 7-record pilot and a rollback) were prepared but **not loaded by this session**. Whether the user loaded them later is unverified.

## 3. User requests (chronological, IST)

- 09-28 19:22: Find where the old Sector and Sales Channel values are used and the impact of replacing them; analyse the whole org.
- 09-28 19:39: Create a document (Excel) of where these fields and values are used: Lightning page filters, components, severity.
- 09-28 19:54: Where is the Excel file stored?
- 09-29 18:41: Estimate the time to replace everything.
- 10-05 11:59: Will removing Specialty CAN affect code or flows (client mapping with Sector V2)?
- 10-05 12:03: Update the workbook with a separate Specialty CAN sheet.
- 10-05 12:18: Explain the flow and what happens if Specialty CAN is removed.
- 10-06 11:36: New approved mapping. Don't touch Specialty CAN. List the replacement locations by component. Ask before deploying ("Deploy to Sandbox").
- 10-06 12:13: User renamed Sales Channel to Key Account in the sandbox. Replace Key Accounts references step by step, then Sector. Don't change data.
- 10-06 12:19, 12:22, 12:28, 12:33 ("should not affect existing working logic"), 12:38: Deploy to Sandbox (Key Account steps 1.1–1.5).
- 10-06 12:45: Create a production deployment document for the Key Account change (GoodR format).
- 10-06 12:54: Where is the deployment document?
- 10-06 13:01: Start Sector replacement with the same process.
- 10-06 13:07, 14:33: Deploy to Sandbox (Sector 2.1, 2.2).
- 10-06 14:41 – 15:49: Update the same deployment document with a Sector section (several resumes and continues).
- 10-06 16:01: Where is Specialty CAN used; what must change?
- 10-07 10:46: Reports, dashboards and report types needing replacement.
- 10-07 10:55: Verify the user's where-used list for Sector, with reasons; 10:59: as Excel.
- 10-07 11:15: Create a change set in the sandbox and validate in production ("should not fail").
- 10-07 11:25: One-line comments for the task tracker.
- 10-07 11:44: Review the client questions for production data migration.
- 10-08 10:54: Specialty CAN mapping given; where to update.
- 10-08 10:59: Go one by one for Specialty CAN, no data changes, then update the deployment document.
- 10-08 11:10, 11:15, 11:27: Deploy to Sandbox (C1, C2, C3).
- 10-08 11:32: No data migration yet; verify CMDT and LRP work for both old and new values.
- 10-08 11:38: Update the deployment document with a Specialty CAN section.
- 10-08 11:49: Test all sandbox changes against the Impact Register and Visibility Matrix.
- 10-09 09:33: QA Excel for UI testing.
- 10-09 09:44: V1 backup fields (text or picklist), admin-only edit.
- 10-09 09:48: Deploy to Sandbox (V1 fields).
- 10-09 09:54: Add the V1 fields to the page for testing.
- 10-09 10:03: Old sector values are deactivated intentionally; keep them for now.
- 10-09 10:09: Add V1 to the Company page.
- 10-09 10:14: Replace the old filters with strict new-mapping filters.
- 10-09 10:15, 10:20: Deploy to Sandbox (Company, Lead pages).
- 10-09 10:24: Self Service account got Cluster 5 instead of 6; verify cluster and team on all objects.
- 10-09 10:34: Deploy to Sandbox (cluster fix).
- 10-09 10:48: QA Excel of cluster and team per Sales Channel + Sector; 10:50: resume.
- 10-09 11:17: QA Excel for LRP sections by Sales Channel + Sector.
- 10-09 11:33: How to update the old fields with the new values (V1 already filled).
- 10-09 11:38: Mid-Market → Strategic; xlsx of records to update.
- 10-09 11:54: Single sheet with counts and existing/new values.
- 10-09 12:22: Create an outbound change set.
- 10-09 13:05: Move LRP filters to production without unapproved fields (R12).
- 10-09 13:14: Client answers; data-load considerations.
- 10-12 18:59: GitHub login (username plus password [redacted]).
- 10-12 19:02: Install whatever is needed for login; 19:13: "yes".
- 10-12 19:22: Device code issue.
- 10-12 19:25: Create the GDRSandbox repository on GitHub.
- 10-12 19:30: Arrange as project "Goodr" (sandbox) and store everything.
- 10-12 19:40: Create the 7 folders (Instructions, Knowledge Base, Requirements, Change Records, Conflicts, Deployment, Technical Documents).
- 10-13 12:01: Store all org changes, with dates and detail, in GitHub and VS Code; miss nothing.

## 4. Decisions & lessons

- **Process:** prepare locally, then dry run, then ask for confirmation. Deploy only after "Deploy to Sandbox". Back up org versions to the scratchpad (`backup_20261006`, `backup_20261008_CAN`, `backup_20261009_V1_LRP`, `backup_20261009_cluster_fix`).
- **Expand → migrate → contract:** new values are added alongside the old ones; old values are removed only after data migration.
- **Production packages are built from production's own files** (read-only GDRPROD retrieves), not from the sandbox.
  - Sandbox team CMDT points to `.partial` users.
  - Sandbox pages carry unapproved work: Fulfillment/Order Channel, YTD/at-risk and inactivity fields, R12, Tiers.
  - A change set would leak these, so the CLI "Option A" was recommended.
- **Production validation:**
  - NoTestRun isn't allowed in production; use RunSpecifiedTests with repeated `--tests` flags.
  - FlexiPage filters fail validation until the picklist values exist (and are active) in the target org.
- **Deactivated values break FlexiPage saves:** filters can't reference inactive values. After the user deactivated old Sector values and Specialty CAN in GDRSAND on 10-08 (18:24 – 18:36 IST), the Company and Lead pages had to be rebuilt with strict new-mapping filters.
- **Cluster bug fix (GEpsfCAD):**
  - ClusterRuleEngine previously ignored Sector-only changes.
  - AccountCascadeHandler didn't sync the Sector to open Opportunities, so the dependent picklist failed.
  - Two sandbox Accounts (R12 Test Company Sandbox, Test Team) still show Cluster 5 with Self Service. No data fix was applied.
- **Severity corrections:** Opportunity flow failure was retracted; team-assignment severity was lowered to Low because ClusterTeamEngine matches on cluster only.
- **Pre-existing sandbox-only test failures:** 2 ShopifyOrderSyncTest methods. The full run on 10-08 showed 13 failing, including ShopifyAtRiskNoticeBatchTest.inactiveStore_noticesSweptToOffboarded and DeleteAutomatedTasksBatchTest.
- **Tooling:**
  - There's no Python, so Excel 2007 COM was used (cell-by-cell `.Formula` writes).
  - PowerShell aliases R and SC clashed with helper names.
  - Anonymous Apex exception class names must end in "Exception"; debug logs encode `|` as `&#124;`.
  - The typeform__Form__c Name field isn't writeable.
- **Production risk noted:** 71 production Key Account accounts with manual clusters 2, 3 or 8 would reset to Cluster 1 if the cluster fix is deployed before the data load. 346 production Specialty CAN companies have no Billing Country.
- **Security:** the user posted a GitHub password in chat. It was not used (device-flow auth instead), and the user was advised to change it.

## Appendix A: org changes seen in GDRSAND history but NOT made by this session (for reference)

These come from the Setup Audit Trail and DeployRequest query run on 2026-10-13. Times are IST and all actions were by user "Ruben Smith", the shared login. They cover the Shopify At-Risk / Warm-Off work and manual Setup steps.

- 09-25 12:36 – 14:40: Account fields Last_Shopify_Order_Sync_Date__c, Months_Since_Last_Order__c (formula), Scheduled_Deactivation_Date__c (formula) created. Shopify_At_Risk_Notice__c fields Stage__c (picklist), Months Inactive At Notice and Last Order Date At Notice created, plus layout changes.
- 09-28 11:05: Shopify_At_Risk_Notice__c.Deactivation_Date__c created.
- 09-28 11:34 – 11:44: 7 new Sector values added (Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor). Sector dependencies updated on Lead, Account, Contact and Opportunity.
- 09-28 13:08: Account.Inactivity_Stage__c (formula, Text) created.
- 09-28 13:12: Offboard Due Date formula changed.
- 09-28 14:17: Status value "Send Failed" added.
- 09-28 14:20: Notice Key set as unique/external ID.
- 09-28 14:34: Shopify_At_Risk_Config.Default set:
  - Template Stage 1–5 = Warm Off 1–5
  - At Risk Mode = Every Stage
  - Reminder Days = 15
  - Deactivation Months = 18
  - Test Store Name Filter = R12%
- Auto Offboard toggled 0/1 on: 09-28 14:53 / 15:02; 09-29 14:17; 09-30 11:15, 11:36, 11:38, 12:54; 10-01 10:52, 10:53. The last value is 1.
- 09-28 15:27: Deploy 0Afdx00000G3ISECA3, Flow Send_Shopify_At_Risk_Notice (v2 activated, v1 deactivated). Failed deploys at 15:29 (0Afdx00000G3PVJCA3) and 15:59 (0Afdx00000G3RwvCAF).
- 09-28 16:06 – 16:08: EmailTemplates Warm_Off_1_Check_In (G3SPxCAN), Warm_Off_2_Early_Notice (G3SWPCA3), Warm_Off_3_30_Day_Warning (G3SbFCAV), Warm_Off_4_15_Day_Reminder (G3SeTCAV), Warm_Off_5_Deactivation_Notice (G3Sg5CAF).
- 09-29 13:13: Test Store Name Filter → "R12 WO A%".
- 09-30 11:15: Test Store Name Filter → "R12 WOT%".
- 09-30 12:53: Offboard Due Date field **deleted** from Shopify_At_Risk_Notice__c.
- 09-30 13:41: Scheduled_Deactivation_Date__c formula changed from `Last_Shopify_Order_Date__c + 548` to `ADDMONTHS(Last_Shopify_Order_Date__c, 18)`.
- 09-30 13:42: Inactivity_Stage__c formula changed to ADDMONTHS-based stages (Month 12/15/17/18+).
- 09-30 15:03: Account field history tracking on for Last Shopify Order Date, Shopify Ordering Enabled, Shopify Sales At Risk and YTD Performance Percent; off for Vertical, Sport/Category and Website.
- 10-05 12:28: Account.Order_Channel__c (picklist) created.
- 10-06 10:45 – 10:46: Sales Channel and Sales Channel1 value Key Accounts → Key Account (label and API name), by the user in Setup.
- 10-08 12:07: Specialty CAN deactivated then re-activated; Sector dependencies updated.
- 10-08 15:49: Deploy 0Afdx00000GDn9lCAD: BackfillLastShopifyOrderDateTest (created), ShopifyAtRiskNoticeBatchTest, ShopifyOrderSyncTest and ShopifyR12SalesTest (changed); 105 tests passed. This came from the other session, c6dfcc34 (unverified attribution).
- 10-08 18:24 – 18:36: Sector values Sellgoodr USA, Core, Mid-Market, Off-Price, Bridge, Sellgoodr CAN and Global **deactivated**. Specialty CAN deactivated in Sales Channel and Sales Channel1. Dependencies updated on all 4 objects. The user confirmed on 10-09 that this was intentional.
- **GDRPROD audit trail:**
  - 10-06 11:48: Sales Channel value Key Accounts → Key Account (production rename, done by the user in Setup).
  - 10-08 15:08: Lightning page Case Record changed.
  - 10-12 12:59: showDeveloperConsoleWithWebIdeOffOn changed.
- **GDRPROD deploys:** only the two check-only validations, 0AfPn000002N1ALKA0 (failed) and 0AfPn000002N1BxKAK (succeeded), both from this session.
