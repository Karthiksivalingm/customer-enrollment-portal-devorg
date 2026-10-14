# CR-019 — Contact agreement status tracking and new certificate rules

| | |
|---|---|
| **Change ID** | CR-019 |
| **Date** | 2026-10-08 |
| **Requirement** | [REQ-009](../03-Requirements/REQ-009_Demo-Feedback-Agreement-Files-Status-Tracking-Certificate-Rules.md) §9.2, §9.3 |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000008JezSAE |

## What changed
| Component | Change |
|---|---|
| `Contact.Agreement_Status__c` + `Vendor_Contact` record type | Added Out for Approval, Out for Signature, Signed, Cancelled / Declined, Expired |
| `Adobe_Agreement_Update_Contact_Status` | **New** flow (after save on agreement): Adobe status → Recipient Vendor Contact |
| `Contact_Set_Certificate_Document_Status` | Non-Profit and Sales Activation need COI only. Acts only while status is blank, Document Pending or Document Uploaded. |
| `Upload_Certificate` | New choice `Choice_W9_Optional` ("W-9 (optional)", value W-9). Sales Activation now offers COI + W-9 optional; Non-Profit offers COI + W-9 optional. |
| `certificateReminder` | Required and optional certificates; "Upload W-9 (optional)" button; colours for new statuses |
| `Contact_Record_Page_Three_Column` | Upload Certificate: Sales Activation shows while COI or W-9 is missing. Create Agreement: new document rules, and status in (Document Uploaded, Cancelled / Declined, Expired). |

## Verification
Check-only test: all rule and status-sync scenarios passed ([REQ-009](../03-Requirements/REQ-009_Demo-Feedback-Agreement-Files-Status-Tracking-Certificate-Rules.md)).
