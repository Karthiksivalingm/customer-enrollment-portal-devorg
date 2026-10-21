# MLB Project — Document Index

Every project document, by folder and serial number. **Last updated:** 2026-10-21 (REQ-014 to REQ-018, CR-027 to CR-035, CON-016 to CON-018, TECH-009 and TECH-010, ATR-002, MTC-002).

## Naming convention
`<PREFIX>-<3-digit serial>_<Short-Title-With-Hyphens>.md`, for example `REQ-005_Signed-Agreement-Email-With-PDF.md`.

| Folder | Prefix | What goes in it | Next free number |
|---|---|---|---|
| `01-Instructions` | — | Instructions for how work is done. **Read-only; never edited by the assistant.** | — |
| `02-Knowledge-Base` | `KB-` | Background: overview, process, integrations, environment, users | KB-007 |
| `03-Requirements` | `REQ-` | One per requirement: need, scope, behaviour, acceptance criteria, assumptions, open questions | REQ-019 |
| `04-Change-Records` | `CR-` | One per change made to an org: what, when, deploy ID, verification, rollback | CR-036 |
| `05-Conflicts` | `CON-` | Problems, clashes with existing automation or standards, open risks | CON-019 |
| `06-Deployment` | `DEP-` | Deployment documents, created only when something is actually deployed | DEP-001 |
| `07-Technical` | `TECH-` | Technical design and component detail | TECH-011 |
| `08-QA/01-Automated-Testing` | `ATR-` | Backend test run of every scenario, after "all good" | ATR-003 |
| `08-QA/02-Manual-Testing` | `MTC-` | Manual test case document with steps, screenshots and expected results, after "all good" | MTC-003 |

**Rules:**
- Numbers are never reused. A cancelled item keeps its number and is marked as such.
- An existing document is **updated** when its topic changes; a new number is used for a new topic.
- Every document links to its related REQ, CR, TECH, CON and DEP documents.

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
| KB-002 | [Business Process](02-Knowledge-Base/Business-Process.md) |
| KB-003 | [Integrations](02-Knowledge-Base/Integrations.md) |
| KB-004 | [Salesforce Environment and Tooling](02-Knowledge-Base/KB-004_Salesforce-Environment.md) |
| KB-005 | [Sandbox User Status](02-Knowledge-Base/KB-005_Sandbox-User-Status.md) |
| KB-006 | Agreement Testing Guide: [Word](02-Knowledge-Base/KB-006_Agreement-Testing-Guide.docx) · [HTML](02-Knowledge-Base/KB-006_Agreement-Testing-Guide.html). Sandbox user guide for Create Agreement, Edit Agreement, locked agreement fields and Suite Lease sending, with screenshots |
| — | [Technical Architecture](02-Knowledge-Base/Technical-Architecture.md) (existing, unchanged) |

## 03 — Requirements
| ID | Requirement | Status |
|---|---|---|
| REQ-001 | [Ticket Office Comments field](03-Requirements/REQ-001_Ticket-Office-Comments-Field.md) | ✅ Sandbox |
| REQ-002 | [Ticket Office notification email](03-Requirements/REQ-002_Ticket-Office-Notification-Email.md) | ✅ Sandbox |
| REQ-003 | [Email triggering conditions](03-Requirements/REQ-003_Ticket-Office-Email-Triggering-Conditions.md) | ✅ Sandbox |
| REQ-004 | [Email design and content](03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md) | ✅ Sandbox |
| REQ-005 | [Signed email with PDF](03-Requirements/REQ-005_Signed-Agreement-Email-With-PDF.md) | ✅ Sandbox |
| REQ-006 | [Vendor certificate reminder and document status](03-Requirements/REQ-006_Vendor-Contact-Certificate-Reminder-And-Document-Status.md) | ✅ Sandbox |
| REQ-007 | [Restrict to Vendor Contact](03-Requirements/REQ-007_Restrict-Certificate-Features-To-Vendor-Contact.md) | ✅ Sandbox |
| REQ-008 | [Lock certificate fields to the flow](03-Requirements/REQ-008_Lock-Certificate-Fields-To-Flow-Only.md) | ✅ Sandbox |
| REQ-009 | [Demo feedback: files, status tracking, rules](03-Requirements/REQ-009_Demo-Feedback-Agreement-Files-Status-Tracking-Certificate-Rules.md) | ✅ Sandbox |
| REQ-010 | [Latest-agreement status and Send button](03-Requirements/REQ-010_Contact-Status-From-Latest-Agreement-And-Send-Button.md) | ✅ Sandbox |
| REQ-011 | [Ticketing Engagement fields and Opportunity link](03-Requirements/REQ-011_Ticketing-Engagement-Fields-and-Opportunity-Link.md) | ⏸ On hold, reverted |
| REQ-012 | [Sales Managers role access](03-Requirements/REQ-012_Sales-Managers-Role-Access.md) | ✅ Sandbox |
| REQ-013 | [Suite Lease: MVP label and 40 games](03-Requirements/REQ-013_Suite-Lease-MVP-Label-And-40-Games.md) | ✅ Sandbox |
| REQ-014 | [Agreement Flow: create and edit, locked agreement fields](03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) | ✅ Sandbox |
| REQ-015 | [Account Sales Vendor: Type value removed](03-Requirements/REQ-015_Account-Sales-Vendor-Type-Value.md) | ✅ Sandbox |
| REQ-016 | [Contact Sales Vendor record type](03-Requirements/REQ-016_Contact-Sales-Vendor-Record-Type.md) | ✅ Sandbox |
| REQ-017 | [User Sales Manager checkbox](03-Requirements/REQ-017_User-Sales-Manager-Checkbox.md) | ✅ Sandbox |
| REQ-018 | [Certificate-only agreement attachments](03-Requirements/REQ-018_Certificate-Only-Agreement-Attachments.md) | ✅ Sandbox |

## 04 — Change Records
| ID | Change | Date |
|---|---|---|
| CR-001 | [Agreement Flow: Ticket Office Comments](04-Change-Records/CR-001_Agreement-Flow-Ticket-Office-Comments.md) | 10-05 |
| CR-002 | [Ticket Office email: initial build](04-Change-Records/CR-002_Ticket-Office-Email-Initial-Build.md) | 10-05 |
| CR-003 | [Email recipients and rows](04-Change-Records/CR-003_Ticket-Office-Email-Recipients-And-Rows.md) | 10-06 |
| CR-004 | [Delete Suite Lease Signed Copy alert](04-Change-Records/CR-004_Delete-Suite-Lease-Signed-Copy-Alert.md) | 10-06 |
| CR-005 | [Adobe callback setup and revert](04-Change-Records/CR-005_Adobe-Sign-Callback-Setup-And-Revert.md) | 10-06 |
| CR-006 | [Email triggers and status component](04-Change-Records/CR-006_Ticket-Office-Email-Triggers-And-Status-Component.md) | 10-06 |
| CR-007 | [Email fields per type](04-Change-Records/CR-007_Ticket-Office-Email-Fields-Per-Type.md) | 10-07 |
| CR-008 | [$50k first-send rule](04-Change-Records/CR-008_Fifty-K-First-Send-Rule.md) | 10-07 |
| CR-009 | [Marlins design and logo](04-Change-Records/CR-009_Marlins-Email-Design-And-Logo.md) | 10-07 |
| CR-010 | [Agreement File Upload - Contact mapping fix](04-Change-Records/CR-010_Agreement-File-Upload-Contact-Mapping-Fix.md) | 10-06 |
| CR-011 | [Sandbox manual configuration](04-Change-Records/CR-011_Sandbox-Manual-Configuration.md) | 10-06/07 |
| CR-012 | [Vendor certificate reminder and status](04-Change-Records/CR-012_Vendor-Certificate-Reminder-And-Document-Status.md) | 10-07 |
| CR-013 | [Restrict to Vendor Contact](04-Change-Records/CR-013_Restrict-To-Vendor-Contact-Record-Type.md) | 10-07 |
| CR-014 | [Certificate fields locked](04-Change-Records/CR-014_Certificate-Fields-Locked-To-Flow-Only.md) | 10-07 |
| CR-015 | [No upload button when complete](04-Change-Records/CR-015_Remove-Upload-Button-When-Complete.md) | 10-08 |
| CR-016 | [Signed email with PDF](04-Change-Records/CR-016_Signed-Email-With-PDF-Attachment.md) | 10-08 |
| CR-017 | [Upload Certificate Non-Profit fix](04-Change-Records/CR-017_Upload-Certificate-Non-Profit-Fix.md) | 10-08 |
| CR-018 | [Deactivate Delete Agreement File flow](04-Change-Records/CR-018_Deactivate-Delete-Agreement-File-Flow.md) | 10-08 |
| CR-019 | [Contact status tracking and certificate rules](04-Change-Records/CR-019_Contact-Status-Tracking-And-Certificate-Rules.md) | 10-08 |
| CR-020 | [Status from latest agreement](04-Change-Records/CR-020_Contact-Status-From-Latest-Agreement.md) | 10-08 |
| CR-021 | [Pre-send statuses and Send button](04-Change-Records/CR-021_Draft-Statuses-And-Send-Agreement-Visibility.md) | 10-08 |
| CR-022 | [Ticketing Engagement build and revert](04-Change-Records/CR-022_Revert-Ticketing-Engagement-Requirements.md) | 10-08/09 |
| CR-023 | [MLB Sales Manager Access permission set](04-Change-Records/CR-023_MLB-Sales-Manager-Access-Permission-Set.md) | 10-09 |
| CR-024 | [Marlins Sales app Contact page](04-Change-Records/CR-024_Marlins-Sales-App-Contact-Page.md) | 10-09 |
| CR-025 | [Adobe Sign permission sets for Sales Managers](04-Change-Records/CR-025_Adobe-Sign-Permission-Sets-For-Sales-Managers.md) | 10-09 |
| CR-026 | [Agreement Flow: MVP label and 40 games](04-Change-Records/CR-026_Agreement-Flow-MVP-Label-And-40-Games.md) | 10-13 |
| CR-027 | [Membership Agreement manual-edit lock](04-Change-Records/CR-027_Membership-Agreement-Manual-Edit-Lock.md) | 10-14/15 |
| CR-028 | [Edit Agreement flow and button (superseded by CR-031)](04-Change-Records/CR-028_Edit-Agreement-Flow-And-Button.md) | 10-15 |
| CR-029 | [Opportunity agreement fields lock](04-Change-Records/CR-029_Opportunity-Agreement-Fields-Lock.md) | 10-15 |
| CR-030 | [DEF-001 Paid to Date fix](04-Change-Records/CR-030_DEF-001-Paid-To-Date-Fix.md) | 10-19 |
| CR-031 | [One Agreement Flow for create and edit](04-Change-Records/CR-031_Combined-Agreement-Flow.md) | 10-21 |
| CR-032 | [Account Sales Vendor Type value](04-Change-Records/CR-032_Account-Sales-Vendor-Type-Value.md) | 10-21 |
| CR-033 | [Contact Sales Vendor record type and features](04-Change-Records/CR-033_Contact-Sales-Vendor-Record-Type.md) | 10-21 |
| CR-034 | [User Sales Manager checkbox](04-Change-Records/CR-034_User-Sales-Manager-Checkbox.md) | 10-21 |
| CR-035 | [Certificate-only agreement attachments](04-Change-Records/CR-035_Certificate-Only-Agreement-Attachments.md) | 10-21 |

## 05 — Conflicts
| ID | Conflict | Status |
|---|---|---|
| CON-001 | [Non Profit vs Non-Profit](05-Conflicts/CON-001_Upload-Certificate-Non-Profit-Value-Mismatch.md) | ✅ |
| CON-002 | [Email alert platform limits](05-Conflicts/CON-002_Email-Alert-Platform-Limits.md) | ✅ |
| CON-003 | [Admins bypass read-only FLS](05-Conflicts/CON-003_Admin-Bypasses-Read-Only-FLS.md) | ✅ |
| CON-004 | [Restricted picklist and record type error](05-Conflicts/CON-004_Restricted-Picklist-Record-Type-Error.md) | ✅ |
| CON-005 | [Adobe status not syncing in sandbox](05-Conflicts/CON-005_Adobe-Sign-Status-Not-Syncing-In-Sandbox.md) | ✅ |
| CON-006 | [Delete flow hid agreement files](05-Conflicts/CON-006_Delete-Agreement-File-Flow-Hid-Agreements.md) | ✅ |
| CON-007 | [Multiple agreements per Contact](05-Conflicts/CON-007_Multiple-Agreements-Per-Contact.md) | ✅ |
| CON-008 | [Contact file mapping target](05-Conflicts/CON-008_Agreement-File-Upload-Contact-Mapping.md) | ✅ |
| CON-009 | [Sandbox email deliverability](05-Conflicts/CON-009_Sandbox-Email-Deliverability-Off.md) | ✅ |
| CON-010 | [Ticket Office address in two places](05-Conflicts/CON-010_Ticket-Office-Address-Stored-In-Two-Places.md) | ⚠ Open |
| CON-011 | [Gaps against coding standards](05-Conflicts/CON-011_Gaps-Against-Coding-Standards.md) | ⚠ Open |
| CON-012 | [Open data, user and tooling items](05-Conflicts/CON-012_Open-Data-And-Access-Items.md) | ⚠ Open |
| CON-013 | [Opportunity ProVenue ID is a formula](05-Conflicts/CON-013_Opportunity-ProVenue-ID-Is-A-Formula.md) | ℹ Known |
| CON-014 | [Sales Manager access gaps](05-Conflicts/CON-014_Sales-Manager-Access-Gaps.md) | ✅ |
| CON-015 | [Suite Location MPV vs MVP](05-Conflicts/CON-015_Suite-Location-MPV-vs-MVP.md) | ✅ |
| CON-016 | [Adobe runtime variable limits](05-Conflicts/CON-016_Adobe-Runtime-Variable-Limits.md) | ✅ |
| CON-017 | [1 year New Business term not wired](05-Conflicts/CON-017_One-Year-New-Business-Term-Not-Wired.md) | ⚠ Open |
| CON-018 | [Contact page filter condition limit](05-Conflicts/CON-018_Contact-Page-Filter-Condition-Limit.md) | ℹ Known |

## 06 — Deployment
No deployment documents yet. Nothing has been deployed so far.

## 07 — Technical
| ID | Document |
|---|---|
| TECH-001 | [Agreement Flow: Ticket Office Comments](07-Technical/TECH-001_Agreement-Flow-Ticket-Office-Comments.md) |
| TECH-002 | [Ticket Office notification architecture](07-Technical/TECH-002_Ticket-Office-Notification-Architecture.md) |
| TECH-003 | [Email field mapping per type](07-Technical/TECH-003_Ticket-Office-Email-Field-Mapping.md) |
| TECH-004 | [Vendor certificate and status automation](07-Technical/TECH-004_Vendor-Certificate-and-Agreement-Status-Automation.md) |
| TECH-005 | [Component inventory](07-Technical/TECH-005_Component-Inventory.md) |
| TECH-006 | [Ticketing Engagement design (on hold)](07-Technical/TECH-006_Ticketing-Engagement-Design-On-Hold.md) |
| TECH-007 | [Sales Manager access model](07-Technical/TECH-007_Sales-Manager-Access-Model.md) |
| TECH-008 | [Agreement Flow: Suite Lease choices](07-Technical/TECH-008_Agreement-Flow-Suite-Lease-Choices.md) |
| TECH-009 | [Agreement Flow create/edit and locks](07-Technical/TECH-009_Agreement-Flow-Create-Edit-And-Locks.md) |
| TECH-010 | [Sales Vendor, Sales Manager, certificate attachments](07-Technical/TECH-010_Sales-Vendor-And-Certificate-Attachments.md) |

## 08 — QA
How QA is run and what each document contains: [01-Instructions/QA-Process.md](01-Instructions/QA-Process.md).

| ID | Automated test report | Manual test cases |
|---|---|---|
| 001 (REQ-014 Edit Agreement and locked agreement fields) | [ATR-001](08-QA/01-Automated-Testing/ATR-001_Edit-Agreement-And-Locked-Agreement-Fields.md): 24 of 24 passed (retested after combining the flows), DEF-001 found and fixed · [test class](08-QA/01-Automated-Testing/ATR-001_EditAgreementQaTest.cls) | [MTC-001](08-QA/02-Manual-Testing/MTC-001_Edit-Agreement-And-Locked-Agreement-Fields.md): 24 test cases with screenshots |
| 002 (REQ-015 to REQ-018 Sales Vendor, Sales Manager checkbox, certificate attachments) | [ATR-002](08-QA/01-Automated-Testing/ATR-002_Sales-Vendor-Sales-Manager-And-Certificate-Attachments.md): 16 of 16 passed | [MTC-002](08-QA/02-Manual-Testing/MTC-002_Sales-Vendor-Sales-Manager-And-Certificate-Attachments.md): 11 test cases with screenshots |
