# CR-021 — Pre-send statuses on the Contact and Send Agreement button visibility

| | |
|---|---|
| **Change ID** | CR-021 |
| **Date** | 2026-10-08 |
| **Requirement** | [REQ-010](../03-Requirements/REQ-010_Contact-Status-From-Latest-Agreement-And-Send-Button.md) §10.2, §10.3 |
| **Org** | utdev sandbox |
| **Deploy IDs** | 0AfiV0000008PHNSA2 · 0AfiV0000008PVtSAM |

## What changed
| Component | Change |
|---|---|
| `Contact.Agreement_Status__c` + record type | Added Draft, Pre-Send, Send in Progress, Created, Approved (13 values in process order) |
| `Adobe_Agreement_Update_Contact_Status` | Trigger is now **Create and Update**; entry `OR(ISNEW(), ISCHANGED(status))`; maps the new statuses |
| `certificateReminder` | New statuses shown as blue "in progress" |
| `Contact_Record_Page_Three_Column` | Send Agreement: Account Type in the 3 vendor types **and** status ≠ Document Pending **and** ≠ Document Uploaded **and** Vendor Contact |

## Notes
- Listing all 11 allowed statuses hit the page's **10-filter limit**.
- A "not blank" picklist check isn't allowed on the page, so a vendor Account Type is required instead.

## Verification
Check-only: new agreement B shows Draft immediately and then follows B; the older agreement is ignored.
