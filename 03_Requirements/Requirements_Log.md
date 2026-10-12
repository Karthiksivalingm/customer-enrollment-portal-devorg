# Requirements Log

Add each new request as a row at the bottom, with the next ID. Status values: **Done**, **In progress**, **Waiting on client**, **Not started**.
Dates are approximate for requests raised and closed in the same working session.

| ID | Date | Requirement | Status | Output / where it is |
|---|---|---|---|---|
| REQ-001 | 2026-10-05 | Find where the Sector and Sales Channel values are used (classes, flows, pages, reports, dashboards) and what changing them affects | Done | `07_Technical_Documents/Impact_Analysis/Sector_Where_Used_Analysis.xlsx` |
| REQ-002 | 2026-10-05 | Impact of removing Specialty CAN; new Sector mapping | Done | Same workbook, Specialty CAN sheet |
| REQ-003 | 2026-10-06 | Rename `Key Accounts` → `Key Account` everywhere it's used, one component at a time, with no data change | Done | Change log 2026-10-06 |
| REQ-004 | 2026-10-06 | Add the new Sector values where the old values are used (cluster rules, page filters) without breaking existing logic | Done | Change log 2026-10-06/07 |
| REQ-005 | 2026-10-07 | Production deployment document with all classes, test classes, steps and rollback | Done | `06_Deployment/Deployment_Documents/KeyAccount_Rename_Deployment_Document.xlsx` |
| REQ-006 | 2026-10-07 | Production change set and validation that won't fail | Done (validation job `0AfPn000002N1BxKAK`, 17/17 tests) | `06_Deployment/Deployment_Documents/ChangeSet_Component_List.xlsx` |
| REQ-007 | 2026-10-08 | Specialty CAN → Specialty in metadata (flow, tests, reports), no data change | Done | Change log 2026-10-08 |
| REQ-008 | 2026-10-08 | Verify that metadata works for both the new and old mappings | Done | `06_Deployment/Post_Deployment_Verification/` |
| REQ-009 | 2026-10-08 | QA test scenarios for UI testing | Done | `06_Deployment/QA_Testing/QA_Test_Scenarios_KeyAccount_Sector_SpecialtyCAN.xlsx` |
| REQ-010 | 2026-10-09 | V1 backup fields (Sales Channel V1, Sector V1), editable by admins only, in the page Details section after Sector | Done | Change log 2026-10-09 |
| REQ-011 | 2026-10-09 | Replace page filters with the strict new mapping (Company page, Lead page) | Done | Change log 2026-10-09 |
| REQ-012 | 2026-10-09 | Bug: Specialty / Self Service showed Cluster 5. Verify cluster and team on all objects | Done (fixed and verified, 32 checks, 0 mismatches) | Change log 2026-10-09 (cluster fix) |
| REQ-013 | 2026-10-09 | QA references: cluster/team mapping; page sections per Sales Channel / Sector | Done | `06_Deployment/QA_Testing/` |
| REQ-014 | 2026-10-10 | Data update plan: export of existing and new values, Data Loader files, Mid-Market → Strategic | Prepared, **not loaded** | `04_Change_Records/Data_Changes/DataMigration_Account_Sandbox/` |
| REQ-015 | 2026-10-10 | Move page filters to production without unapproved fields (R12 and others) | Not started (V1 fields on prod pages not yet decided) | n/a |
| REQ-016 | 2026-10-11 | Put the project in a private GitHub repository | Done | https://github.com/yogemani/GDRSandbox |
| REQ-017 | 2026-10-12 | Organise the repo into Instructions / Knowledge Base / Requirements / Change Records / Conflicts / Deployment / Technical Documents | Done | This structure |

## Open / upcoming
| ID | Requirement | Waiting on |
|---|---|---|
| REQ-018 | Production data migration files: DWH export, V1 fill, per-object loads, rollback | Go-ahead for production data |
| REQ-019 | Add a "Data Migration – Production" section to the deployment document | REQ-018 |
| REQ-020 | Fix the "Accounts without NetSuite Id" report | Not started |
| REQ-021 | Update the QA pack for the deactivated values and the cluster fix | Not started |
| REQ-022 | Decide on the extra `ContactTeamReassignQueueable` line in `AccountCascadeHandler` (sandbox only) | Client / team decision |

## Template for a new requirement
```
| REQ-0xx | yyyy-mm-dd | <what was asked, one sentence> | Not started | <file or folder> |
```
