# TECH-005 — Component inventory (everything created or changed)

| | |
|---|---|
| **ID** | TECH-005 |
| **Org** | utdev sandbox |
| **As of** | 2026-10-23 |

Legend: **C** = created · **M** = modified · **D** = deleted · **X** = deactivated · **R** = reverted (no longer exists)

## Agreement Flow and Ticket Office notification (REQ-001 to REQ-005, REQ-013)
| Component | Type | Action | Local file |
|---|---|---|---|
| `Agreement_Flow` | Flow | M (Ticket Office Comments; MVP label and 40 games; create and edit in one flow, v68; Suite Lease payment schedule, v75) | flows/Agreement_Flow.flow-meta.xml |
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
| `Contact_Set_Certificate_Document_Status` | Flow | C (v5: Sales_Vendor only) | flows/ |
| `Adobe_Agreement_Update_Contact_Status` | Flow | C (v5: Sales_Vendor only) | flows/ |
| `Upload_Certificate` | Flow | M (v11: copy certificates to attachments) | flows/ |
| `Delete_Agreement_File` | Flow | X | flowDefinitions/Delete_Agreement_File.flowDefinition-meta.xml |
| `certificateReminder` | LWC | C (Sales_Vendor only) | lwc/certificateReminder |
| `certificateUploadModal` | LWC | C | lwc/certificateUploadModal |
| `Contact_Record_Page_Three_Column` | FlexiPage | M (record type filters: equals Sales_Vendor) | flexipages/ |
| `Admin` profile FLS (3 certificate fields) | Profile | M | not kept locally |
| FLS on 3 certificate fields (all other profiles) | FieldPermissions | M (read-only) | **not in metadata** |

## Sales Managers role access (REQ-012)
| Component | Type | Action | Local file |
|---|---|---|---|
| `MLB_Sales_Manager_Access` | Permission set | C (app Marlins_Sales, 4 Contact record types incl. Sales_Vendor, RunFlow) | permissionsets/MLB_Sales_Manager_Access.permissionset-meta.xml |
| `Marlins_Sales` | CustomApplication | M (Contact View → Contact_Record_Page_Three_Column) | applications/Marlins_Sales.app-meta.xml |
| Assignments: MLB_Sales_Manager_Access, Adobe_Sign_User, Adobe_Access, AdobeSign_ContractBuilder_User | PermissionSetAssignment (data) | C, all 18 Sales Managers role users | **not in metadata** |

`applications/standard__LightningSales.app-meta.xml` was retrieved for comparison only and **not changed**.

## Agreement edit and locked agreement fields (REQ-014)
| Component | Type | Action | Local file |
|---|---|---|---|
| `Membership_Agreement__c.Flow_Update__c` | Checkbox (hidden) | C | objects/Membership_Agreement__c/fields/ |
| `Membership_Agreement__c.Membership_Agreement_Flow_Only` | Validation rule | C | objects/Membership_Agreement__c/validationRules/ |
| `Membership_Agreement_Reset_Flow_Update` | Flow (record-triggered) | C | flows/ |
| `Opportunity.Agreement_Flow_Update__c` | Checkbox (hidden) | C | objects/Opportunity/fields/ |
| `Opportunity.Agreement_Sections_Flow_Only` | Validation rule | C | objects/Opportunity/validationRules/ |
| `Update_Opportunity_from_Membership_Agreement` | Flow (record-triggered) | M (v5) | flows/ |
| `Edit_Agreement_Flow` | Flow | C, then D (merged into Agreement_Flow, CR-031) | — |
| `Opportunity.Edit_Agreement` | Quick action | C (opens Agreement_Flow) | quickActions/ |
| `Ticketing_Opportunity_LRP` | FlexiPage | M (Edit Agreement action) | flexipages/ |

## Client change requests, 2026-10-21 (REQ-015 to REQ-018)
| Component | Type | Action | Local file |
|---|---|---|---|
| `Account.Sales_Vendor` | Record type | M ("Sales Vendor" removed from Type) | objects/Account/recordTypes/ |
| `Contact.Sales_Vendor` | Record type | C (clone of Vendor_Contact) | objects/Contact/recordTypes/ |
| `Admin`, `Ticket Sales`, `Marlins Sales Leadership` | Profiles (partial) | M (Sales_Vendor visibility and layout; Sales_Manager__c field access) | profiles/ |
| `User.Sales_Manager__c` | Checkbox | C | objects/User/fields/ |
| `Vendor_Activation_Food_and_Beverage_Agreement` | Flow | M (v9: Sales Manager list from the checkbox) | flows/ |
| `CertificateAttachmentService` / `…Test` | Apex | C | classes/ |
| `Contact.Send_Agreement` | Custom button | Unchanged (retrieved; temporarily changed for testing and restored) | objects/Contact/webLinks/ |
| Users Billy Marlin, Ruben Smith | Data | Sales_Manager__c ticked | **not in metadata** |
| Adobe template row 0000031 (a0oiV0000000D0TQAU) | Data | Source type Files → Attachments | **not in metadata** |
| Certificate attachments (29 on 18 contacts) | Data | C (backfill) | **not in metadata** |
## Suite Lease payment schedule and Person Account Type (REQ-019, REQ-020)
| Component | Type | Action | Local file |
|---|---|---|---|
| `Opportunity.Number_of_Payment_Plans__c` | Picklist (label "Number of Payment Schedule") | C | objects/Opportunity/fields/ |
| `Opportunity.Payment_Amount__c` | Text(18) | C | objects/Opportunity/fields/ |
| `Opportunity.Payment_Due_Date_1__c` … `_12__c` | Text(30) | C (first as Date, rebuilt as text, CR-042) | objects/Opportunity/fields/ |
| `Opportunity.Payment_Amount_1__c` … `_12__c` | Text | C, then D (CR-041) | — |
| `Opportunity.Payment_Due_Date_1_Formatted__c` … `_12_` | Formula | C, then D and purged (CR-042) | — |
| `Opportunity.Payment_Amounts_Numeric_Only` | Validation rule | C | objects/Opportunity/validationRules/ |
| `Opportunity.Agreement_Sections_Flow_Only` | Validation rule | M (license fees out; schedule fields in; 44 fields) | objects/Opportunity/validationRules/ |
| `Agreement_Flow` | Flow | M (v75; versions 69–74 deleted) | flows/ |
| `Ticketing_Opportunity_LRP` | FlexiPage | M (Suite Lease Details arranged; Suite Payment Plan section) | flexipages/ |
| `Opportunity-Opportunity Layout` | Page layout | M (schedule fields) | layouts/ |
| `Admin`, `Ticket Sales`, `Marlins Sales Leadership`, `Marlins IT Admin` | Profiles (partial) | M (field access on the 14 fields; deployed from a temporary folder, not kept in force-app) | — |
| `PersonAccount.PersonAccount` | Record type | M (Type: Food and Beverage, Non-Profit) | objects/PersonAccount/recordTypes/ |
| Suite Lease Adobe templates DCT-16, DCT-22 | Data | 15 field-mapping entries each (CR-039) | **not in metadata** |

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
`objects/Contact/Contact.object-meta.xml` and `objects/Account/Account.object-meta.xml` (pulled automatically with retrieves). **Don't deploy them** unless intended.
