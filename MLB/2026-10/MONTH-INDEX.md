# 2026-10 — Month index

History of the project work in October 2026: every requirement, the documents and components behind it, and its status. The master index is [DOCUMENT-INDEX.md](../DOCUMENT-INDEX.md). The tracking workbook for this month is [2026-10_Tracker.xlsx](2026-10_Tracker.xlsx).

## Summary
- **Ticket Office notifications** (REQ-001 to REQ-005): Ticket Office Comments in the Agreement Flow; Ticket Office email on $50k first send, Sales Manager approval / denial and customer signature / decline; signed PDF attached.
- **Vendor certificates and agreement status** (REQ-006 to REQ-010, REQ-016, REQ-018): certificate banner and upload, document status, Adobe status sync from the latest agreement, Send Agreement visibility, certificate checkboxes locked to the flow, only certificate files attached. Limited to the **Sales Vendor** contact record type on 2026-10-23.
- **Access** (REQ-012, REQ-017): Sales Managers role access; Sales Manager checkbox on User; ten sales users given full agreement access.
- **Agreement Flow** (REQ-013, REQ-014): MVP label and 40 games; one flow for create and edit; agreement fields and Membership rows locked to the flow.
- **Sales Vendor record types** (REQ-015, REQ-016).
- **On hold**: Ticketing Engagement (REQ-011), built and reverted.

## Requirement history
| REQ | Title | Keywords | Objects / main components | Status | Change records | Other documents |
|---|---|---|---|---|---|---|
| [REQ-001](03-Requirements/REQ-001_Ticket-Office-Comments-Field.md) | Ticket Office Comments field | ticket office comments, long text | Opportunity; Agreement_Flow | ✅ Sandbox | CR-001 | TECH-001 |
| [REQ-002](03-Requirements/REQ-002_Ticket-Office-Notification-Email.md) | Ticket Office notification email | email alert, VF template, ticket office | Opportunity; Adobe_Agreement_Notify_Ticket_Office; Ticket_Office_Agreement_Details | ✅ Sandbox | CR-002, CR-003, CR-004, CR-005, CR-011 | TECH-002, CON-002, CON-005, CON-009, CON-010 |
| [REQ-003](03-Requirements/REQ-003_Ticket-Office-Email-Triggering-Conditions.md) | Email triggering conditions | 50k, first send, approval, signed, declined | echosign Agreement; notify flow | ✅ Sandbox | CR-006, CR-008 | TECH-002 |
| [REQ-004](03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md) | Email design and content | Marlins logo, layout, agreement summary, multi-product | VF template and components | ✅ Sandbox | CR-007, CR-009 | TECH-003 |
| [REQ-005](03-Requirements/REQ-005_Signed-Agreement-Email-With-PDF.md) | Signed email with PDF | signed PDF attachment | TicketOfficeSignedEmail (Apex) | ✅ Sandbox | CR-016 | TECH-002 |
| [REQ-006](03-Requirements/REQ-006_Vendor-Contact-Certificate-Reminder-And-Document-Status.md) | Vendor certificate reminder and document status | banner, upload certificate, COI, W-9, food service, document pending | Contact; certificateReminder; Upload_Certificate; Contact_Set_Certificate_Document_Status | ✅ Sandbox (now Sales Vendor only) | CR-012, CR-015, CR-017 | TECH-004, CON-001, CON-004 |
| [REQ-007](03-Requirements/REQ-007_Restrict-Certificate-Features-To-Vendor-Contact.md) | Restrict to Vendor Contact | record type, vendor contact | Contact page filters | Superseded by REQ-016 / CR-036 (Sales Vendor only) | CR-013 | TECH-004 |
| [REQ-008](03-Requirements/REQ-008_Lock-Certificate-Fields-To-Flow-Only.md) | Lock certificate fields to the flow | validation rule, read only, COI collected | Contact.Certificate_Fields_Flow_Only | ✅ Sandbox | CR-014 | CON-003 |
| [REQ-009](03-Requirements/REQ-009_Demo-Feedback-Agreement-Files-Status-Tracking-Certificate-Rules.md) | Demo feedback: files, status tracking, rules | agreement files, status tracking, non-profit rules | Delete_Agreement_File; Adobe_Agreement_Update_Contact_Status | ✅ Sandbox | CR-010, CR-018, CR-019 | CON-006, CON-008 |
| [REQ-010](03-Requirements/REQ-010_Contact-Status-From-Latest-Agreement-And-Send-Button.md) | Latest-agreement status and Send button | latest agreement, draft statuses, send agreement button | Adobe_Agreement_Update_Contact_Status; Contact page | ✅ Sandbox | CR-020, CR-021 | CON-007 |
| [REQ-011](03-Requirements/REQ-011_Ticketing-Engagement-Fields-and-Opportunity-Link.md) | Ticketing Engagement fields and Opportunity link | ticketing engagement, ProVenue ID | Ticketing_Engagement__c | ⏸ On hold, reverted | CR-022 | TECH-006, CON-013 |
| [REQ-012](03-Requirements/REQ-012_Sales-Managers-Role-Access.md) | Sales Managers role access (+ four sales reps, 10-23) | permission set, Marlins Sales app, record types, Adobe permission sets | MLB_Sales_Manager_Access; Marlins_Sales app | ✅ Sandbox | CR-023, CR-024, CR-025, CR-037 | TECH-007, CON-014 |
| [REQ-013](03-Requirements/REQ-013_Suite-Lease-MVP-Label-And-40-Games.md) | Suite Lease: MVP label and 40 games | suite location, MVP, total games | Agreement_Flow | ✅ Sandbox | CR-026 | TECH-008, CON-015 |
| [REQ-014](03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) | Agreement Flow: create and edit, locked agreement fields | edit agreement, prefill, membership rows, validation rule, lock | Agreement_Flow; Membership_Agreement__c; Opportunity rules | ✅ Sandbox | CR-027 to CR-031 | TECH-009, CON-016, CON-017, ATR-001, MTC-001 |
| [REQ-015](03-Requirements/REQ-015_Account-Sales-Vendor-Type-Value.md) | Account Sales Vendor: Type value removed | account type, sales vendor | Account.Sales_Vendor record type | ✅ Sandbox | CR-032 | TECH-010, ATR-002, MTC-002 |
| [REQ-016](03-Requirements/REQ-016_Contact-Sales-Vendor-Record-Type.md) | Contact Sales Vendor record type | sales vendor, record type, certificate features | Contact.Sales_Vendor; profiles; page filters | ✅ Sandbox | CR-033, CR-036 | TECH-010, CON-018, ATR-002, MTC-002 |
| [REQ-017](03-Requirements/REQ-017_User-Sales-Manager-Checkbox.md) | User Sales Manager checkbox | sales manager list, checkbox, vendor agreement | User.Sales_Manager__c; Vendor_Activation_Food_and_Beverage_Agreement | ✅ Sandbox | CR-034, CR-037 | TECH-010, ATR-002, MTC-002 |
| [REQ-018](03-Requirements/REQ-018_Certificate-Only-Agreement-Attachments.md) | Certificate-only agreement attachments | send agreement, attachments, files, Adobe template | CertificateAttachmentService; Upload_Certificate; Adobe template | ✅ Sandbox | CR-035 | TECH-010, CON-016, ATR-002, MTC-002 |

## Documents created this month
The knowledge base is common to all months and lives in the root [02-Knowledge-Base](../02-Knowledge-Base) folder. KB-004 (Salesforce Environment), KB-005 (Sandbox User Status) and KB-006 (Agreement Testing Guide) were added this month.

### 04 — Change Records
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
| CR-036 | [Contact vendor features: Sales Vendor only](04-Change-Records/CR-036_Contact-Vendor-Features-Sales-Vendor-Only.md) | 10-23 |
| CR-037 | [Sales Manager ticks and sales user access](04-Change-Records/CR-037_Sales-Manager-Ticks-And-Sales-User-Access.md) | 10-23 |

### 05 — Conflicts
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
| CON-012 | [Open data, user and tooling items](05-Conflicts/CON-012_Open-Data-And-Access-Items.md) | ⚠ Open (living) |
| CON-013 | [Opportunity ProVenue ID is a formula](05-Conflicts/CON-013_Opportunity-ProVenue-ID-Is-A-Formula.md) | ℹ Known |
| CON-014 | [Sales Manager access gaps](05-Conflicts/CON-014_Sales-Manager-Access-Gaps.md) | ✅ |
| CON-015 | [Suite Location MPV vs MVP](05-Conflicts/CON-015_Suite-Location-MPV-vs-MVP.md) | ✅ |
| CON-016 | [Adobe runtime variable limits](05-Conflicts/CON-016_Adobe-Runtime-Variable-Limits.md) | ✅ |
| CON-017 | [1 year New Business term not wired](05-Conflicts/CON-017_One-Year-New-Business-Term-Not-Wired.md) | ⚠ Open |
| CON-018 | [Contact page filter condition limit](05-Conflicts/CON-018_Contact-Page-Filter-Condition-Limit.md) | ✅ Closed |

### 06 — Deployment
None. Nothing was deployed to production this month.

### 07 — Technical
| ID | Document |
|---|---|
| TECH-001 | [Agreement Flow: Ticket Office Comments](07-Technical/TECH-001_Agreement-Flow-Ticket-Office-Comments.md) |
| TECH-002 | [Ticket Office notification architecture](07-Technical/TECH-002_Ticket-Office-Notification-Architecture.md) |
| TECH-003 | [Email field mapping per type](07-Technical/TECH-003_Ticket-Office-Email-Field-Mapping.md) |
| TECH-004 | [Vendor certificate and status automation](07-Technical/TECH-004_Vendor-Certificate-and-Agreement-Status-Automation.md) |
| TECH-005 | [Component inventory](07-Technical/TECH-005_Component-Inventory.md) (living) |
| TECH-006 | [Ticketing Engagement design (on hold)](07-Technical/TECH-006_Ticketing-Engagement-Design-On-Hold.md) |
| TECH-007 | [Sales Manager access model](07-Technical/TECH-007_Sales-Manager-Access-Model.md) |
| TECH-008 | [Agreement Flow: Suite Lease choices](07-Technical/TECH-008_Agreement-Flow-Suite-Lease-Choices.md) |
| TECH-009 | [Agreement Flow create/edit and locks](07-Technical/TECH-009_Agreement-Flow-Create-Edit-And-Locks.md) |
| TECH-010 | [Sales Vendor, Sales Manager, certificate attachments](07-Technical/TECH-010_Sales-Vendor-And-Certificate-Attachments.md) |

### 08 — QA
| ID | Automated test report | Manual test cases |
|---|---|---|
| 001 (REQ-014) | [ATR-001](08-QA/01-Automated-Testing/ATR-001_Edit-Agreement-And-Locked-Agreement-Fields.md): 24 of 24 passed, DEF-001 found and fixed · [test class](08-QA/01-Automated-Testing/ATR-001_EditAgreementQaTest.cls) | [MTC-001](08-QA/02-Manual-Testing/MTC-001_Edit-Agreement-And-Locked-Agreement-Fields.md): 24 test cases |
| 002 (REQ-015 to REQ-018) | [ATR-002](08-QA/01-Automated-Testing/ATR-002_Sales-Vendor-Sales-Manager-And-Certificate-Attachments.md): 16 of 16 passed, retest 5 of 5 | [MTC-002](08-QA/02-Manual-Testing/MTC-002_Sales-Vendor-Sales-Manager-And-Certificate-Attachments.md): 12 test cases |

## Open items at month end
See [CON-012](05-Conflicts/CON-012_Open-Data-And-Access-Items.md) and [CON-017](05-Conflicts/CON-017_One-Year-New-Business-Term-Not-Wired.md).
