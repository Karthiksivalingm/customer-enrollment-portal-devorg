# CR-020 — Contact status syncs only from the latest agreement

| | |
|---|---|
| **Change ID** | CR-020 |
| **Date** | 2026-10-08 |
| **Requirement** | [REQ-010](../03-Requirements/REQ-010_Contact-Status-From-Latest-Agreement-And-Send-Button.md) §10.1 |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000008PAvSAM |

## What changed
`Adobe_Agreement_Update_Contact_Status`:
- added `Get_Latest_Agreement`: the Recipient Contact's newest agreement, sorted by CreatedDate descending
- added decision `Is_Latest_Agreement`: update the Contact only when the changed agreement is that newest one

## Verification
Two agreements on one contact (check-only): changes on the older agreement are ignored.
