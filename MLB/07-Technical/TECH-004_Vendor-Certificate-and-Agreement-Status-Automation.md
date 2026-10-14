# TECH-004 — Vendor certificate and agreement status automation

| | |
|---|---|
| **ID** | TECH-004 |
| **Requirements** | REQ-006 · REQ-007 · REQ-008 · REQ-009 · REQ-010 |
| **Scope** | Contacts with record type `Vendor_Contact` only |

## 1. Data model (Contact)
| Field | Type | Notes |
|---|---|---|
| `Agreement_Status__c` | Picklist (restricted) | 13 values: Document Pending, Document Uploaded, Ready to Send, Draft, Pre-Send, Send in Progress, Created, Out for Approval, Approved, Out for Signature, Signed, Cancelled / Declined, Expired. All enabled on `Vendor_Contact`. |
| `COI_Collected__c`, `W_9_Collected__c`, `Food_Services_Certificate_Collected__c` | Checkbox | Set only by `Upload_Certificate`. Read-only FLS plus a validation rule. |
| `Certificate_Flow_Update__c` | Checkbox (hidden, no FLS) | Marker flipped by the flow so its save passes the validation rule |
| `Account_Type__c` | Formula (existing) | Shows "Non Profit" for Account Type "Non-Profit" |

## 2. Automation
| Component | Type / timing | Logic |
|---|---|---|
| `Contact_Set_Certificate_Document_Status` | Flow, **before save**, Contact, create and update | Entry: RT = Vendor_Contact AND Account.Type ∈ {Food and Beverage, Non-Profit, Sales Activation} AND status ∈ {blank, Document Pending, Document Uploaded}. Sets status = Document Uploaded if all **required** certificates are collected, else Document Pending. |
| `Upload_Certificate` | Screen flow (existing, modified), **system mode without sharing** | Per-type screens. Ticks the checkbox for the chosen category and flips `Certificate_Flow_Update__c` (formula `frmToggleCertificateFlowUpdate`). Non-Profit fixed. W-9 optional choice. COI added for Sales Activation. |
| `Certificate_Fields_Flow_Only` | Validation rule | `IF(ISNEW(), any box ticked, OR(ISCHANGED(any box)) AND NOT(ISCHANGED(Certificate_Flow_Update__c)))` |
| `Adobe_Agreement_Update_Contact_Status` | Flow, **after save**, agreement, create and update | Entry: (ISNEW or status changed) AND `echosign_dev1__Recipient__c` set AND Recipient RT = Vendor_Contact AND status in the mapped list. Get the Recipient's latest agreement (CreatedDate desc); if it's this one, Contact status = mapped status. |
| `Delete_Agreement_File` | Flow (existing) | **Deactivated** |
| Vendor Activation flow (`Vendor_Activation_Food_and_Beverage_Agreement`) | Existing, unchanged | Sets **Ready to Send** |

**Status mapping** (Adobe → Contact): identity mapping, except Waiting for Counter-Approval → Out for Approval and Waiting for Counter-Signature → Out for Signature. Other Adobe statuses (form-filling, acceptance, delivery) are ignored.

**Order of execution:** before-save status flow → validation rule → save → after-save flows. The document flow never overrides Ready to Send or Adobe statuses, because its entry criteria exclude them.

## 3. Certificate rules
| Account.Type | Required | Optional |
|---|---|---|
| Food and Beverage | Food Service, W-9 | — |
| Non-Profit | COI | W-9 |
| Sales Activation | COI | W-9 |

## 4. UI: `Contact_Record_Page_Three_Column`
| Element | Visibility rule (all AND `{!Record.RecordType.DeveloperName}` = Vendor_Contact) |
|---|---|
| `certificateReminder` (top of main) | RT only; the component also checks RT and the vendor type |
| Upload Certificate (`Contact.Upload_Certificate`) | (F&B AND (Food = false OR W9 = false)) OR (Non Profit AND (COI = false OR W9 = false)) OR (Sales Activation AND (COI = false OR W9 = false)) |
| Create Agreement (`Contact.Create_Agreement`) | ((F&B AND Food AND W9) OR (Non Profit AND COI) OR (Sales Activation AND COI)) AND status ∈ {Document Uploaded, Cancelled / Declined, Expired} |
| Send Agreement (`CustomButton.Contact.Send_Agreement`) | Account_Type__c ∈ 3 vendor types AND status ≠ Document Pending AND ≠ Document Uploaded |
| Vendor Information section | RT only |

Page limits that shaped this:
- at most 10 filter conditions per component
- `RecordTypeId` can't use EQUAL
- picklist "not blank" isn't allowed

## 5. LWC
| Component | Behaviour |
|---|---|
| `certificateReminder` | `getRecord` (Account.Type, status, 3 checkboxes, RecordType.DeveloperName). Required and optional lists per type. Amber banner with **Upload Certificate** while required items are missing; green banner with **Upload W-9 (optional)** while only optional items are missing; no button once complete. Toast once per page open when required items are missing. Status pill colours. |
| `certificateUploadModal` | `LightningModal` running `lightning-flow` `Upload_Certificate` with input `recordId`; closes on FINISHED and refreshes the record |

## 6. Rejected options
- **FLS only:** admins bypass it ([CON-003](../05-Conflicts/CON-003_Admin-Bypasses-Read-Only-FLS.md)).
- **Last-change-wins status sync:** older agreements overwrote newer ones ([CON-007](../05-Conflicts/CON-007_Multiple-Agreements-Per-Contact.md)).
- **Listing 11 statuses for Send Agreement:** exceeds the filter limit.
