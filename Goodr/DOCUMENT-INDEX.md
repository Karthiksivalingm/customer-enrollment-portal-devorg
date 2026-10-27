# Goodr Project — Document Index

Every project document, by folder and serial number. **Last updated:** 2026-10-27 (REQ-040 / CR-035 / ATR-005: automatic offboarding removes the Shopify ordering role; CON-039; CON-035 updated).

## Naming convention
`<PREFIX>-<3-digit serial>_<Short-Title-With-Hyphens>.md`, for example `REQ-012_Cluster-Not-Updating-For-Sector-Only-Change.md`.

| Folder | Prefix | What goes in it | Next free number |
|---|---|---|---|
| `01-Instructions` | — | Instructions for how work is done. **Read-only; never edited by the assistant.** | — |
| `02-Knowledge-Base` | `KB-` | Background: overview, process, integrations, environment, onboarding | KB-007 |
| `03-Requirements` | `REQ-` | One per requirement: need, scope, acceptance criteria, open questions | REQ-041 |
| `04-Change-Records` | `CR-` | One per change made to the sandbox: what, when, deploy ID, verification, rollback | CR-036 |
| `05-Conflicts` | `CON-` | Problems, clashes with existing automation or standards, open risks | CON-040 |
| `06-Deployment` | `DEP-` | Deployment documents, created only when something is actually deployed | DEP-003 |
| `07-Technical` | `TECH-` | Technical design and component detail | TECH-011 |
| `08-QA/01-Automated-Testing` | `ATR-` | Backend test run of every scenario, after "all good" | ATR-006 |
| `08-QA/02-Manual-Testing` | `MTC-` | Manual test case document with steps, screenshots and expected results, after "all good" | MTC-006 |

**Rules:**
- Numbers are never reused. A cancelled or removed item keeps its number and is marked as such.
- An existing document is **updated** when its topic changes; a new number is used for a new topic.
- Every document links to its related REQ, CR, TECH, CON, DEP and QA documents.
- Not used / removed: REQ-005, 006, 015, 018, 019, 020, 024, 026, 027, 028, 029, 031 · CR-007, 010, 013, 020 · CON-001, 002, 004, 005, 006, 015, 021, 022 · DEP-001, 002 (removed 2026-10-19, CR-025).

## 01 — Instructions (read-only)
| File | Purpose |
|---|---|
| [AI-Workflow.md](01-Instructions/AI-Workflow.md) | Workflows A, B and C; required document structures |
| [Coding-Standards.md](01-Instructions/Coding-Standards.md) | Rules every change must meet |
| [Project-Rules.md](01-Instructions/Project-Rules.md) | Environments, folders, document control, QA, test data, approvals, version control, reporting |
| [QA-Process.md](01-Instructions/QA-Process.md) | When QA runs, file locations, test IDs, how tests are run, ATR and MTC structure |

## 02 — Knowledge Base
| ID | Document |
|---|---|
| KB-001 | [Project Overview](02-Knowledge-Base/Project-Overview.md) |
| KB-002 | [Business Process: Shopify At-Risk Notices and Offboarding](02-Knowledge-Base/Business-Process.md) |
| KB-003 | [Integrations](02-Knowledge-Base/Integrations.md) |
| KB-004 | [Salesforce Environment and Tooling](02-Knowledge-Base/KB-004_Salesforce-Environment.md) |
| KB-005 | [Technical Architecture](02-Knowledge-Base/Technical-Architecture.md) |
| KB-006 | [Developer Onboarding](02-Knowledge-Base/KB-006_Developer-Onboarding.md) |

## 03 — Requirements
| ID | Document | Status |
|---|---|---|
| REQ-001 | [Sales Channel and Sector Where-Used Analysis](03-Requirements/REQ-001_Sales-Channel-And-Sector-Where-Used-Analysis.md) | ✅ Done |
| REQ-002 | [Specialty CAN Removal Impact](03-Requirements/REQ-002_Specialty-CAN-Removal-Impact.md) | ✅ Done |
| REQ-003 | [Rename Key Accounts to Key Account](03-Requirements/REQ-003_Rename-Key-Accounts-To-Key-Account.md) | ✅ Done |
| REQ-004 | [Add New Sector Values Where Old Values Are Used](03-Requirements/REQ-004_Add-New-Sector-Values-Where-Old-Values-Are.md) | ✅ Done |
| REQ-007 | [Specialty CAN to Specialty in Metadata](03-Requirements/REQ-007_Specialty-CAN-To-Specialty-In-Metadata.md) | ✅ Done |
| REQ-008 | [Verify Old and New Mappings](03-Requirements/REQ-008_Verify-Old-And-New-Mappings.md) | ✅ Done |
| REQ-009 | [QA Test Scenarios for UI Testing](03-Requirements/REQ-009_QA-Test-Scenarios-For-UI-Testing.md) | ✅ Done |
| REQ-010 | [V1 Backup Fields](03-Requirements/REQ-010_V1-Backup-Fields.md) | ✅ Done |
| REQ-011 | [Strict New-Mapping Page Filters](03-Requirements/REQ-011_Strict-New-Mapping-Page-Filters.md) | ✅ Done |
| REQ-012 | [Cluster Not Updating for Sector-Only Change](03-Requirements/REQ-012_Cluster-Not-Updating-For-Sector-Only-Change.md) | ✅ Done (fixed and verified, 32 checks, 0 mismatches) |
| REQ-013 | [QA References for Cluster, Team and Page Sections](03-Requirements/REQ-013_QA-References-For-Cluster-Team-And-Page-Sections.md) | ✅ Done |
| REQ-014 | [Sandbox Data Update to New Mapping](03-Requirements/REQ-014_Sandbox-Data-Update-To-New-Mapping.md) | ✅ Done: files prepared by the assistant; loaded in the sandbox by the user (159 of 161 applied, see CR-019) |
| REQ-016 | [Private GitHub Repository](03-Requirements/REQ-016_Private-GitHub-Repository.md) | ✅ Done |
| REQ-017 | [Organise Repository Into Seven Sections](03-Requirements/REQ-017_Organise-Repository-Into-Seven-Sections.md) | ✅ Done |
| REQ-021 | [Update QA Pack for Deactivated Values and Cluster Fix](03-Requirements/REQ-021_Update-QA-Pack-For-Deactivated-Values-And-Cluster.md) | ⚠ Open - waiting on: Not started |
| REQ-022 | [Decision on ContactTeamReassignQueueable Line](03-Requirements/REQ-022_Decision-On-ContactTeamReassignQueueable-Line.md) | ⚠ Open - waiting on: Client / team decision |
| REQ-023 | [Record Every Org Change in GitHub](03-Requirements/REQ-023_Record-Every-Org-Change-In-GitHub.md) | ✅ Done |
| REQ-025 | [Decide on Sector Value Development](03-Requirements/REQ-025_Decide-On-Sector-Value-Development.md) | ⚠ Open - waiting on: Client |
| REQ-030 | [Document Shopify R12 and At-Risk Process](03-Requirements/REQ-030_Document-Shopify-R12-And-At-Risk-Process.md) | ✅ Done |
| REQ-032 | [Shopify Test Class Coverage](03-Requirements/REQ-032_Shopify-Test-Class-Coverage.md) | ✅ Done (deploy `0Afdx00000GDn9lCAD`, 105/105) |
| REQ-033 | [Move Goodr Into sfdcut SFDC Repository](03-Requirements/REQ-033_Move-Goodr-Into-Sfdcut-SFDC-Repository.md) | ✅ Done (pull request) |
| REQ-034 | [Align Goodr with the MLB folder standard (sandbox-only content)](03-Requirements/REQ-034_Align-Goodr-With-MLB-Standard.md) | ✅ Done |
| REQ-035 | [Exclude an Account from the Automated Offboarding](03-Requirements/REQ-035_Auto-Offboarding-Exclusion.md) | 🔧 Built and tested in the sandbox 2026-10-21 (ATR-002, 30 / 30 pass); waiting on client testing (CON-034) |
| REQ-036 | [Show YTD and At-Risk details on the Company page](03-Requirements/REQ-036_Company-Page-YTD-And-At-Risk-Fields.md) | ✅ Done in the sandbox 2026-10-21 |
| REQ-037 | [Hide the Shopify sections while a new Account is created](03-Requirements/REQ-037_Hide-Shopify-Sections-On-New-Account.md) | ✅ Done in the sandbox 2026-10-21 (ATR-003) |
| REQ-038 | [Sales Channel V1 and Sector V1 on Contact, Lead and Opportunity, in a BI section](03-Requirements/REQ-038_V1-Fields-And-BI-Section.md) | ✅ Done in the sandbox 2026-10-22 (ATR-003) |
| REQ-039 | [Sales Channel and Sector required before a Lead is Qualified](03-Requirements/REQ-039_Sales-Channel-Sector-Required-To-Qualify-Lead.md) | ✅ Done in the sandbox 2026-10-27 (ATR-004) |
| REQ-040 | [Automatic offboarding also removes the Shopify ordering role](03-Requirements/REQ-040_Offboarding-Removes-Shopify-Ordering-Role.md) | ✅ Built and tested in the sandbox 2026-10-27 (ATR-005) |

## 04 — Change Records
| ID | Document | Date |
|---|---|---|
| CR-001 | [Shopify At-Risk / Warm-Off offboarding: sandbox build](04-Change-Records/CR-001_Shopify-At-Risk-Warm-Off-Offboarding-Sandbox-Build.md) | 2026-09-25 |
| CR-002 | [New Sector values](04-Change-Records/CR-002_New-Sector-Values.md) | 2026-09-28 |
| CR-003 | [Impact analysis](04-Change-Records/CR-003_Impact-Analysis.md) | 2026-09-28 |
| CR-004 | [Field history tracking](04-Change-Records/CR-004_Field-History-Tracking.md) | 2026-09-30 |
| CR-005 | [Order Channel field](04-Change-Records/CR-005_Order-Channel-Field.md) | 2026-10-05 |
| CR-006 | [Key Accounts → Key Account rename in the sandbox](04-Change-Records/CR-006_Key-Accounts-To-Key-Account-Rename-In-The.md) | 2026-10-06 |
| CR-008 | [Key Account references](04-Change-Records/CR-008_Key-Account-References.md) | 2026-10-06 |
| CR-009 | [New Sector values in logic](04-Change-Records/CR-009_New-Sector-Values-In-Logic.md) | 2026-10-06 |
| CR-011 | [Specialty CAN → Specialty](04-Change-Records/CR-011_Specialty-CAN-To-Specialty.md) | 2026-10-08 |
| CR-012 | [Shopify test classes](04-Change-Records/CR-012_Shopify-Test-Classes.md) | 2026-10-08 |
| CR-014 | [Old values deactivated](04-Change-Records/CR-014_Old-Values-Deactivated.md) | 2026-10-08 |
| CR-015 | [V1 backup fields](04-Change-Records/CR-015_V1-Backup-Fields.md) | 2026-10-09 |
| CR-016 | [DATA V1 backfill](04-Change-Records/CR-016_DATA-V1-Backfill.md) | 2026-10-09 |
| CR-017 | [Pages: V1 fields and strict filters](04-Change-Records/CR-017_Pages-V1-Fields-And-Strict-Filters.md) | 2026-10-09 |
| CR-018 | [Cluster fix](04-Change-Records/CR-018_Cluster-Fix.md) | 2026-10-09 |
| CR-019 | [DATA Account Sales Channel / Sector update in the sandbox](04-Change-Records/CR-019_DATA-Account-Sales-Channel-Sector-Update-In-The.md) | 2026-10-09 |
| CR-021 | [Repository](04-Change-Records/CR-021_Repository.md) | 2026-10-12 |
| CR-022 | [Credential hardening in the repository](04-Change-Records/CR-022_Credential-Hardening-In-The-Repository.md) | 2026-10-13 |
| CR-023 | [Repository best-practice setup](04-Change-Records/CR-023_Repository-Best-Practice-Setup.md) | 2026-10-13 |
| CR-024 | [Move into the sfdcut/SFDC repository](04-Change-Records/CR-024_Move-Into-Sfdcut-SFDC-Repository.md) | 2026-10-14 |
| CR-025 | [Align with the house folder standard (sandbox-only content)](04-Change-Records/CR-025_Align-With-House-Standard.md) | 2026-10-19 |
| CR-026 | [Auto-Offboarding Exclusion: fields, field access and pages](04-Change-Records/CR-026_Auto-Offboarding-Exclusion-Fields-Access-And-Pages.md) | 2026-10-21 |
| CR-027 | [Auto-Offboarding Exclusion: warm-off batch and at-risk task flow](04-Change-Records/CR-027_Auto-Offboarding-Exclusion-Batch-And-Flow.md) | 2026-10-21 |
| CR-028 | [Company page: YTD and At-Risk fields](04-Change-Records/CR-028_Company-Page-YTD-And-At-Risk-Fields.md) | 2026-10-21 |
| CR-029 | [ShopifyOrderSyncTest: no dependency on the "Key Account" value](04-Change-Records/CR-029_ShopifyOrderSyncTest-Org-Independent-Sales-Channel.md) | 2026-10-22 |
| CR-030 | [Hide the Shopify sections on the New Account form](04-Change-Records/CR-030_Hide-Shopify-Sections-On-New-Account.md) | 2026-10-21 |
| CR-031 | [Sales Channel V1 and Sector V1 on Contact, Lead and Opportunity; BI section](04-Change-Records/CR-031_V1-Fields-And-BI-Section.md) | 2026-10-22 |
| CR-032 | [Create NetSuite button: foundation (fields, NetSuite Information section, value map, client, Shopify skip guard)](04-Change-Records/CR-032_NetSuite-Create-Button-Foundation.md) | 2026-10-26 |
| CR-033 | [Lead validation rule: Sales Channel and Sector required to qualify](04-Change-Records/CR-033_Lead-Qualify-Validation-Rule.md) | 2026-10-27 |
| CR-034 | [Scheduled Apex jobs moved to Pacific Time](04-Change-Records/CR-034_Scheduled-Jobs-Moved-To-Pacific-Time.md) | 2026-10-27 |
| CR-035 | [Offboarding batch removes the Shopify ordering role of the stores it deactivates](04-Change-Records/CR-035_Offboarding-Batch-Removes-Shopify-Ordering-Role.md) | 2026-10-27 |

## 05 — Conflicts
| ID | Document | Status |
|---|---|---|
| CON-003 | [Pages: After the old Sector values were deactivated](05-Conflicts/CON-003_Pages-After-The-Old-Sector-Values-Were-Deactivated.md) | ✅ Resolved |
| CON-007 | [AccountCascadeHandler has an unrelated queueable call](05-Conflicts/CON-007_AccountCascadeHandler-Has-An-Unrelated-Queueable-Call.md) | ⚠ Open (decision pending, [REQ-022](03-Requirements/REQ-022_Decision-On-ContactTeamReassignQueueable-Line.md)) |
| CON-008 | [Logic: The cluster stayed at 5 when only the Sector changed](05-Conflicts/CON-008_Logic-The-Cluster-Stayed-At-5-When-Only.md) | ✅ Resolved |
| CON-009 | [Logic: Saving an Account with open Opportunities failed with an invalid](05-Conflicts/CON-009_Logic-Saving-An-Account-With-Open-Opportunities-Failed.md) | ⚠ Open |
| CON-010 | [Sandbox data: Sandbox Opportunity record types don't include Specialty CAN, so](05-Conflicts/CON-010_Sandbox-Data-Sandbox-Opportunity-Record-Types-Dont-Include.md) | ✅ Resolved |
| CON-011 | [Tests: 2 ShopifyOrderSyncTest methods fail in the sandbox](05-Conflicts/CON-011_Tests-2-ShopifyOrderSyncTest-Methods-Fail-In-The-Sandbox.md) | ✅ Resolved |
| CON-012 | [Users: planda@goodr](05-Conflicts/CON-012_Users-Planda-Goodr.md) | ⚠ Open (admin decision on the user) |
| CON-013 | [Reports: Renaming a picklist value in Setup removes the old value from report](05-Conflicts/CON-013_Reports-Renaming-A-Picklist-Value-In-Setup-Removes.md) | ✅ Resolved |
| CON-014 | [Security: NetSuite credential custom metadata was committed to git](05-Conflicts/CON-014_Security-NetSuite-Credential-Custom-Metadata-Was-Committed-To.md) | ⚠ Open (rotate NetSuite keys) |
| CON-016 | [Picklist: Sector value "Development" is not in the approved mapping](05-Conflicts/CON-016_Picklist-Sector-Value-Development-Was-Added-On-2026.md) | ⚠ Open (client decision, REQ-025) |
| CON-017 | [Repo vs org: On 2026-10-13 the repo did not match the org](05-Conflicts/CON-017_Repo-Vs-Org-On-2026-10-13-The.md) | ✅ Resolved |
| CON-018 | [API version: Retrieving with manifest version 59](05-Conflicts/CON-018_API-Version-Retrieving-With-Manifest-Version-59.md) | ✅ Resolved |
| CON-019 | [Data: Sandbox Account update](05-Conflicts/CON-019_Data-Sandbox-Account-Update.md) | ✅ Resolved (recorded in CR-019) |
| CON-020 | [Shopify At-Risk: Sandbox-only settings](05-Conflicts/CON-020_Shopify-At-Risk-Sandbox-Only-Settings.md) | ⚠ Open (time zone done: Pacific, CR-034; test filter sandbox-only) |
| CON-023 | [Several triggers on one object, and Salesforce doesn't guarantee](05-Conflicts/CON-023_Several-Triggers-On-One-Object-And-Salesforce-Doesnt.md) | ⚠ Open risk |
| CON-024 | [ClusterRuleEngine uses the first matching rule with no ordering](05-Conflicts/CON-024_ClusterRuleEngine-Uses-The-First-Matching-Rule-With-No.md) | ⚠ Open risk |
| CON-025 | [Flow Opportunity_field_update_from_Account](05-Conflicts/CON-025_Flow-Opportunity-Field-Update-From-Account.md) | ⚠ Open risk |
| CON-026 | [Lead_From_US_Retailer_Form_Assignment_And_Email is after-save with no](05-Conflicts/CON-026_Lead-From-US-Retailer-Form-Assignment-And-Email.md) | ⚠ Open risk |
| CON-027 | [The Shopify classes call four different Admin API versions](05-Conflicts/CON-027_The-Shopify-Classes-Call-Four-Different-Admin-API.md) | ⚠ Open risk |
| CON-028 | [Flows in InvalidDraft / Obsolete status](05-Conflicts/CON-028_Flows-In-InvalidDraft-Obsolete-Status.md) | ⚠ Open risk |
| CON-029 | [Deactivated picklist values can't be used in page filters, and record](05-Conflicts/CON-029_Deactivated-Picklist-Values-Cant-Be-Used-In-Page.md) | ⚠ Open risk |
| CON-030 | [Report filters lose renamed values silently](05-Conflicts/CON-030_Report-Filters-Lose-Renamed-Values-Silently.md) | ⚠ Open risk |
| CON-031 | [Shopify company rollup is calculated per 200-record batch chunk](05-Conflicts/CON-031_Shopify-Company-Rollup-Is-Calculated-Per-200-Record.md) | ⚠ Open risk |
| CON-032 | [With At Risk Mode = Every Stage, a store can lose the at-risk flag in](05-Conflicts/CON-032_With-At-Risk-Mode-Every-Stage-A-Store.md) | ⚠ Open risk |
| CON-034 | [Auto-Offboarding Exclusion: open decisions](05-Conflicts/CON-034_Auto-Offboarding-Exclusion-Open-Decisions.md) | ⚠ Open (client decision) |
| CON-035 | [Offboarding behaviour vs the client's answers](05-Conflicts/CON-035_Offboarding-Behaviour-Vs-Client-Answers.md) | ⚠ Open (parked; gap 6 fixed by CR-035) |
| CON-036 | [The sandbox-only "Key Account" rename breaks test classes in other deployments](05-Conflicts/CON-036_Sandbox-Only-Key-Account-Rename-Breaks-Test-Deploys.md) | ⚠ Open risk |
| CON-037 | [Lightning page filters cannot check "the record exists"](05-Conflicts/CON-037_Page-Filters-Cannot-Check-Record-Exists.md) | ✅ Resolved |
| CON-038 | [Qualify rule: Leads already Qualified, and other limits](05-Conflicts/CON-038_Qualify-Rule-And-Existing-Qualified-Leads.md) | ⚠ Open (client decision) |
| CON-033 | [Running ShopifyAtRiskNoticeBatch by hand sends real emails](05-Conflicts/CON-033_Running-ShopifyAtRiskNoticeBatch-By-Hand-Sends-Real-Emails.md) | ⚠ Open risk |
| CON-039 | [The sandbox "Specialty CAN" Shopify setting does not point to a test store](05-Conflicts/CON-039_Sandbox-Canada-Shopify-Setting-Is-Not-A-Test-Store.md) | ⚠ Open risk |

## 06 — Deployment
None. Deployment documents are written only when something is actually deployed.

## 07 — Technical
| ID | Document | Status |
|---|---|---|
| TECH-001 | [Cluster and Team Engine](07-Technical/TECH-001_Cluster-and-Team-Engine.md) |  |
| TECH-002 | [Apex Classes](07-Technical/TECH-002_Apex-Classes.md) |  |
| TECH-003 | [Apex Triggers](07-Technical/TECH-003_Apex-Triggers.md) |  |
| TECH-004 | [Flows](07-Technical/TECH-004_Flows.md) |  |
| TECH-005 | [Fields and Custom Metadata](07-Technical/TECH-005_Fields-and-Custom-Metadata.md) |  |
| TECH-006 | [UI Components](07-Technical/TECH-006_UI-Components.md) |  |
| TECH-007 | [Secure Configuration](07-Technical/TECH-007_Secure-Configuration.md) |  |
| TECH-008 | [Sales Channel / Sector Impact Analysis](07-Technical/TECH-008_Sales-Channel-Sector-Impact-Analysis.xlsx) (Excel) | |
| TECH-009 | [Sector Where-Used Analysis](07-Technical/TECH-009_Sector-Where-Used-Analysis.xlsx) (Excel) | |
| TECH-010 | [Hide-on-create section filters and the BI section](07-Technical/TECH-010_Section-Filters-And-BI-Section.md) | |

## 08 — QA
| ID | Document |
|---|---|
| ATR-001 | [Cluster and team assignment for old and new values](08-QA/01-Automated-Testing/ATR-001_Cluster-And-Team-Old-And-New-Mapping.md) |
| ATR-002 | [Exclude an Account from the Automated Offboarding (30 / 30 pass)](08-QA/01-Automated-Testing/ATR-002_Auto-Offboarding-Exclusion.md) |
| ATR-003 | [Hide the Shopify sections on create; V1 fields and BI section (28 / 28 pass)](08-QA/01-Automated-Testing/ATR-003_Hide-Shopify-Sections-And-BI-V1-Fields.md) · [test class](08-QA/01-Automated-Testing/ATR-003_SavedRecordAndV1QaTest.cls) |
| ATR-004 | [Lead validation rule: Sales Channel and Sector required to qualify (15 / 15 pass, regression 110 / 110, on screen 8 / 8)](08-QA/01-Automated-Testing/ATR-004_Lead-Qualify-Validation-Rule.md) · [test class](08-QA/01-Automated-Testing/ATR-004_LeadQualifyRuleQaTest.cls) |
| ATR-005 | [Automatic offboarding removes the Shopify ordering role (13 / 13 pass, regression 390 / 390)](08-QA/01-Automated-Testing/ATR-005_Offboarding-Shopify-Role-Removal.md) |
| MTC-001 | [Key Account, Sector and Specialty CAN test scenarios](08-QA/02-Manual-Testing/MTC-001_Key-Account-Sector-Specialty-CAN-Test-Scenarios.xlsx) (Excel) |
| MTC-002 | [Cluster and team assignment reference](08-QA/02-Manual-Testing/MTC-002_Cluster-and-Team-Assignment.xlsx) (Excel) |
| MTC-003 | [Record page sections by Sales Channel / Sector](08-QA/02-Manual-Testing/MTC-003_Record-Page-Sections-by-Sales-Channel-Sector.xlsx) (Excel) |
| MTC-004 | [Hide the Shopify sections on create; V1 fields and BI section](08-QA/02-Manual-Testing/MTC-004_Hide-Shopify-Sections-And-BI-V1-Fields.md): 13 test cases with screenshots |
| MTC-005 | [Lead validation rule: Sales Channel and Sector required to qualify](08-QA/02-Manual-Testing/MTC-005_Lead-Qualify-Validation-Rule.md): 9 test cases with screenshots |
