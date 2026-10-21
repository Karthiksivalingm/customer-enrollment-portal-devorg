# CR-033 — Contact Sales Vendor record type, access and certificate features

| | |
|---|---|
| **Change ID** | CR-033 |
| **Date** | 2026-10-21 |
| **Requirement** | [REQ-016](../03-Requirements/REQ-016_Contact-Sales-Vendor-Record-Type.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV000000AoI5SAK (certificate features); record type, profiles and permission set deployed the same day |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `Contact.Sales_Vendor` | Record type | Created, cloned from Vendor_Contact (all picklist values). |
| `Admin`, `Ticket Sales` | Profiles (partial) | Record type visible (not default); Contact-Vendor layout assigned. |
| `MLB_Sales_Manager_Access` | Permission set | Record type visibility added (all four Contact record types). |
| `Contact_Record_Page_Three_Column` | Record page | 4 visibility filters changed from RecordType DeveloperName **equals** "Vendor_Contact" to **contains** "Vendor" (banner, Create Agreement, Send Agreement, Vendor Information section). |
| `Contact_Set_Certificate_Document_Status` | Flow | Entry condition includes Sales_Vendor. |
| `Adobe_Agreement_Update_Contact_Status` | Flow | Entry condition includes Sales_Vendor. |
| `certificateReminder` | LWC | Accepts Vendor_Contact and Sales_Vendor. |

## Notes
- The org's Contact page no longer had the Upload Certificate header action (removed in the org before this change); uploads go through the banner. The org version was kept.
- The Create Agreement filter was already at the 10-condition limit, hence "contains" (CON-018).

## Verification
Record type active; both profiles visible with the Contact-Vendor layout; same 13 Agreement Status values; new Sales Vendor contact got Document Pending and the banner with Upload Certificate; a Draft agreement set the contact to Draft. See ATR-002.

## Rollback
Revert the page filters to "Vendor_Contact", revert the two flows and the LWC, remove the record type from the profiles and permission set, then deactivate the record type.
