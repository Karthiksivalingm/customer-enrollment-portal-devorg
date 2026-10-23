# CR-036 — Contact vendor features limited to the Sales Vendor record type

| | |
|---|---|
| **Change ID** | CR-036 |
| **Date** | 2026-10-23 |
| **Requirement** | [REQ-016](../03-Requirements/REQ-016_Contact-Sales-Vendor-Record-Type.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV000000BLfRSAW (CertificateAttachmentServiceTest 5 of 5) |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Before | After |
|---|---|---|---|
| `Contact_Record_Page_Three_Column` | Record page | 4 filters: RecordType DeveloperName **contains** "Vendor" | **equals** "Sales_Vendor" |
| `Contact_Set_Certificate_Document_Status` | Flow (v5) | Vendor_Contact or Sales_Vendor | Sales_Vendor only |
| `Adobe_Agreement_Update_Contact_Status` | Flow (v5) | Vendor_Contact or Sales_Vendor | Sales_Vendor only |
| `certificateReminder` | LWC | `['Vendor_Contact', 'Sales_Vendor']` | `['Sales_Vendor']` |
| `CertificateAttachmentServiceTest` | Apex test | Test contact on Vendor_Contact | Test contact on Sales_Vendor |

Pre-check: all four components retrieved from the org first; identical to the project.

## Verification
- Vendor Contact "UT Demo 1": no banner, no Upload Certificate / Create Agreement / Send Agreement buttons.
- New Sales Vendor contact: Agreement Status = Document Pending; banner with Upload Certificate. Contact deleted after the test.

## Impact
The 18 existing Vendor Contacts keep their data but no longer show the banner or buttons, and their Agreement Status no longer follows the Adobe agreement (CON-012 item 14).

## Rollback
Reverse the four changes (filters back to contains "Vendor", flows and LWC back to both record types).
