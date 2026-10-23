# CR-013 — Limit certificate features to the Vendor Contact record type

| | |
|---|---|
| **Change ID** | CR-013 |
| **Date** | 2026-10-07 |
| **Requirement** | [REQ-007](../03-Requirements/REQ-007_Restrict-Certificate-Features-To-Vendor-Contact.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV00000085nJSAQ |

## What changed
| Component | Change |
|---|---|
| `Contact_Set_Certificate_Document_Status` (flow) | Entry criteria: `$Record.RecordType.DeveloperName = "Vendor_Contact"` |
| `certificateReminder` (LWC) | Renders only when `RecordType.DeveloperName` = Vendor_Contact |
| `Contact_Record_Page_Three_Column` (FlexiPage) | Visibility rule `{!Record.RecordType.DeveloperName} = Vendor_Contact` added to the Upload Certificate, Create Agreement and Send Agreement actions, the **Vendor Information** section and the banner. Filtering by `RecordTypeId` isn't allowed on this page. |

## Verification
Food & Beverage account with each record type (rolled back): Internal and Business saved with no error and no status; Vendor became Document Pending.
