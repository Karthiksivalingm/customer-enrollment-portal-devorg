# TECH-005 — Component inventory (everything created or changed)

| | |
|---|---|
| **ID** | TECH-005 |
| **Org** | utdev sandbox |
| **As of** | 2026-10-13 |

Legend: **C** = created · **M** = modified · **D** = deleted · **X** = deactivated · **R** = reverted (no longer exists)

## Agreement Flow and Ticket Office notification (REQ-001 to REQ-005, REQ-013)
| Component | Type | Action | Local file |
|---|---|---|---|
| `Agreement_Flow` | Flow | M (Ticket Office Comments; MVP label and 40 games, v65) | flows/Agreement_Flow.flow-meta.xml |
| `Adobe_Agreement_Notify_Ticket_Office` | Flow | C | flows/Adobe_Agreement_Notify_Ticket_Office.flow-meta.xml |
| `unfiled$public/Ticket_Office_Agreement_Details` | Email template (VF) | C | email/unfiled$public/Ticket_Office_Agreement_Details.email(+meta) |
| `TicketOfficeAgreementStatus` | VF component | C | components/ |
| `TicketOfficeAgreementSummary` | VF component | C | components/ |
| `TicketOfficeLogo` | VF component | C | components/ |
| `TicketOfficeAgreementStatusCtrl` / `…Test` | Apex | C | classes/ |
| `TicketOfficeSignedEmail` / `…Test` | Apex | C | classes/ |
| `Ticket_Office_Email` | Custom Label | C | labels/CustomLabels.labels-meta.xml |
| `Ticket_Office_Assets` / `Marlins_Logo` | Document folder / Document | C | documents/ |
| `Opportunity.Ticket_Office_Agreement_Details` | Workflow alert | C | workflows/Opportunity.workflow-meta.xml |
| `Opportunity.Suite_Lease_Agreement_Signed_Copy` | Workflow alert | D | — |
| `Opportunity.Suite_Lease_Agreement` | Approval process (inactive) | M (alert action removed) | approvalProcesses/ |

## Vendor certificates and status (REQ-006 to REQ-010)
| Component | Type | Action | Local file |
|---|---|---|---|
| `Contact.Agreement_Status__c` | Picklist field | M (+10 values) | objects/Contact/fields/ |
| `Contact.Vendor_Contact` | Record type | M (picklist values) | objects/Contact/recordTypes/ |
| `Contact.Certificate_Flow_Update__c` | Checkbox field | C | objects/Contact/fields/ |
| `Contact.Certificate_Fields_Flow_Only` | Validation rule | C | objects/Contact/validationRules/ |
| `Contact_Set_Certificate_Document_Status` | Flow | C | flows/ |
| `Adobe_Agreement_Update_Contact_Status` | Flow | C | flows/ |
| `Upload_Certificate` | Flow | M | flows/ |
| `Delete_Agreement_File` | Flow | X | flowDefinitions/Delete_Agreement_File.flowDefinition-meta.xml |
| `certificateReminder` | LWC | C | lwc/certificateReminder |
| `certificateUploadModal` | LWC | C | lwc/certificateUploadModal |
| `Contact_Record_Page_Three_Column` | FlexiPage | M | flexipages/ |
| `Admin` profile FLS (3 certificate fields) | Profile | M | not kept locally |
| FLS on 3 certificate fields (all other profiles) | FieldPermissions | M (read-only) | **not in metadata** |

## Sales Managers role access (REQ-012)
| Component | Type | Action | Local file |
|---|---|---|---|
| `MLB_Sales_Manager_Access` | Permission set | C (app Marlins_Sales, 3 Contact record types, RunFlow) | permissionsets/MLB_Sales_Manager_Access.permissionset-meta.xml |
| `Marlins_Sales` | CustomApplication | M (Contact View → Contact_Record_Page_Three_Column) | applications/Marlins_Sales.app-meta.xml |
| Assignments: MLB_Sales_Manager_Access, Adobe_Sign_User, Adobe_Access, AdobeSign_ContractBuilder_User | PermissionSetAssignment (data) | C, all 18 Sales Managers role users | **not in metadata** |

`applications/standard__LightningSales.app-meta.xml` was retrieved for comparison only and **not changed**.

## Adobe / environment (no deployable metadata)
| Item | Action |
|---|---|
| `Adobe_Sign_Callback` site | C, then deactivated (can't be deleted) |
| `echosign_dev1__SIGN_Settings__c` org default | C, then deleted |
| 4 scheduled jobs (`EchoSignScheduleCallback`) | C, then aborted |
| Object mapping a1EiV0000000Kd3UAE (Agreement File Upload - Contact) | M (Recipient2 → Recipient) |

## Reverted (REQ-011, on hold)
3 Ticketing Engagement fields, 3 validation rules, Opportunity lookup, 2 flows, quick action, page and layout changes: **R** ([CR-022](../04-Change-Records/CR-022_Revert-Ticketing-Engagement-Requirements.md)).

## Retrieved into the project but not changed
`objects/Contact/Contact.object-meta.xml` (pulled automatically with the field retrieve). **Don't deploy it** unless intended.
