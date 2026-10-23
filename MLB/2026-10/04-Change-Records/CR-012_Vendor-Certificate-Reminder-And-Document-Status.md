# CR-012 — Vendor certificate reminder and document status (initial build)

| | |
|---|---|
| **Change ID** | CR-012 |
| **Date** | 2026-10-07 |
| **Requirement** | [REQ-006](../03-Requirements/REQ-006_Vendor-Contact-Certificate-Reminder-And-Document-Status.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV00000085ddSAA (an earlier attempt failed: `CASE()` can't return true/false in a flow formula) |

## What changed
| Component | Type | Action |
|---|---|---|
| `Contact.Agreement_Status__c` | Picklist (restricted) | Added Document Pending and Document Uploaded |
| `Contact.Vendor_Contact` | Record type | Same values enabled |
| `Contact_Set_Certificate_Document_Status` | Flow (before save, Contact) | **Created** |
| `certificateReminder` | LWC | **Created**: banner and popup toast |
| `certificateUploadModal` | LWC | **Created**: runs the `Upload_Certificate` flow in a modal |
| `Contact_Record_Page_Three_Column` | FlexiPage | Banner added at the top of the main region |

## Verification
Eight contact scenarios (all types, plus Ready to Send kept) in a rolled-back transaction: all correct.
