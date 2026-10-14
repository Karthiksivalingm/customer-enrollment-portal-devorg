# MLB Project — Document Index

Every project document, by folder and serial number. **Last updated:** 2026-10-13 (REQ-013 added).

## Naming convention
`<PREFIX>-<3-digit serial>_<Short-Title-With-Hyphens>.md`, for example `REQ-005_Signed-Agreement-Email-With-PDF.md`.

| Folder | Prefix | What goes in it | Next free number |
|---|---|---|---|
| `01-Instructions` | — | Instructions for how work is done. **Read-only; never edited by the assistant.** | — |
| `02-Knowledge-Base` | `KB-` | Background: overview, process, integrations, environment, users | KB-006 |
| `03-Requirements` | `REQ-` | One per requirement: need, scope, behaviour, acceptance criteria, assumptions, open questions | REQ-014 |
| `04-Change-Records` | `CR-` | One per change made to an org: what, when, deploy ID, verification, rollback | CR-027 |
| `05-Conflicts` | `CON-` | Problems, clashes with existing automation or standards, open risks | CON-016 |
| `06-Deployment` | `DEP-` | Deployment documents, created only when something is actually deployed | DEP-001 |
| `07-Technical` | `TECH-` | Technical design and component detail | TECH-009 |

**Rules:**
- Numbers are never reused. A cancelled item keeps its number and is marked as such.
- An existing document is **updated** when its topic changes; a new number is used for a new topic.
- Every document links to its related REQ, CR, TECH, CON and DEP documents.

## 01 — Instructions (read-only)
| File | Purpose |
|---|---|
| [AI-Workflow.md](01-Instructions/AI-Workflow.md) | Workflows A, B and C; required document structures |
| [Coding-Standards.md](01-Instructions/Coding-Standards.md) | Rules every change must meet |
| [Project-Rules.md](01-Instructions/Project-Rules.md) | (empty) |

## 02 — Knowledge Base
| ID | Document |
|---|---|
| KB-001 | [Project Overview](02-Knowledge-Base/Project-Overview.md) |
| KB-002 | [Business Process](02-Knowledge-Base/Business-Process.md) |
| KB-003 | [Integrations](02-Knowledge-Base/Integrations.md) |
| KB-004 | [Salesforce Environment and Tooling](02-Knowledge-Base/KB-004_Salesforce-Environment.md) |
| KB-005 | [Sandbox User Status](02-Knowledge-Base/KB-005_Sandbox-User-Status.md) |
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
