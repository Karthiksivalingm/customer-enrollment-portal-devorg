# TECH-010 — Sales Vendor contacts, Sales Manager checkbox and certificate-only attachments

| | |
|---|---|
| **ID** | TECH-010 |
| **Requirements** | [REQ-015](../03-Requirements/REQ-015_Account-Sales-Vendor-Type-Value.md) · [REQ-016](../03-Requirements/REQ-016_Contact-Sales-Vendor-Record-Type.md) · [REQ-017](../03-Requirements/REQ-017_User-Sales-Manager-Checkbox.md) · [REQ-018](../03-Requirements/REQ-018_Certificate-Only-Agreement-Attachments.md) |

## 1. Vendor record types
| Place | Rule |
|---|---|
| Contact page filters (`Contact_Record_Page_Three_Column`) | `{!Record.RecordType.DeveloperName}` CONTAINS `Vendor` (4 filters) |
| `Contact_Set_Certificate_Document_Status` (before save) | OR(RT = Vendor_Contact, RT = Sales_Vendor) AND vendor Account Type AND status blank / Document Pending / Document Uploaded |
| `Adobe_Agreement_Update_Contact_Status` (after save) | Recipient RT = Vendor_Contact or Sales_Vendor |
| `certificateReminder` LWC | `VENDOR_RECORD_TYPES = ['Vendor_Contact', 'Sales_Vendor']` |
| `Certificate_Fields_Flow_Only` rule, `CertificateAttachmentService` | Record type independent |

Access to Sales_Vendor: Admin and Ticket Sales profiles (Contact-Vendor layout), MLB_Sales_Manager_Access permission set.

## 2. Sales Manager list
`Vendor_Activation_Food_and_Beverage_Agreement` (v9) → `SalesManagerChoiceSet`: User where `Sales_Manager__c = true` AND `IsActive = true`, label Name, value Id. Saved to `Contact.Sales_Manager__c` by `Update_Contact_Record` (unchanged).

## 3. Certificate-only attachments
```
Upload Certificate screen (file upload) → Loop_Versions → Update_Category (ContentVersion.Certificate_Category__c)
  → Copy_Certificates_To_Attachments (CertificateAttachmentService, invocable)
       → Queueable CopyJob → delete Attachment "[Category] …" on the Contact → insert Attachment "[Category] title.ext" (body = VersionData)
  → Which_Category → Mark_* → Update_Contact

Send Agreement (Contact button) → echosign_dev1__AgreementTemplateProcess (template a0kiV0000000IZdQAM)
  row 0000029: Document Builder Template (generated agreement)
  row 0000031: Document from Master Object · Attachments · All Documents  ← only "[Category]" attachments exist there
```
- Queueable: asynchronous heap (12 MB) so normal certificate PDFs fit.
- `backfill(Set<Id>)` copies the latest categorised file versions already on the Contacts (used once on 2026-10-21: 29 attachments, 18 contacts).
- Users adding files through Files create ContentDocuments, never classic Attachments, so they are not attached.

## 4. Production checklist
1. Deploy: Contact.Sales_Vendor record type → profiles (Admin, Ticket Sales, Marlins Sales Leadership partial) and permission set → User.Sales_Manager__c → flows, page, LWC, Apex (CertificateAttachmentServiceTest runs).
2. Data: tick Sales Manager on the agreed users.
3. Adobe: template "Vendor Activation Agreement" row 0000031 → Source type Attachments.
4. Data: run `CertificateAttachmentService.backfill()` for Vendor and Sales Vendor contacts.
