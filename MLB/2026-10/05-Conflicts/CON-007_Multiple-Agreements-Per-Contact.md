# CON-007 — Several agreements on one Contact overwrote each other's status

| | |
|---|---|
| **ID** | CON-007 |
| **Status** | ✅ Resolved 2026-10-08 ([CR-020](../04-Change-Records/CR-020_Contact-Status-From-Latest-Agreement.md), [CR-021](../04-Change-Records/CR-021_Draft-Statuses-And-Send-Agreement-Visibility.md)) |

## Conflict
The first status-sync version used "last status change wins". Example: agreement B signed, then old agreement A expired → Contact showed **Expired** although a signed agreement existed.

## Resolution (client decision)
Only the Contact's **most recently created** agreement updates the Contact, from the moment it's created (Draft onward). Older agreements are ignored.

## Remaining edge case
"Latest" is by `CreatedDate`. Two agreements created in the same second would be ambiguous. This is unlikely in real use.
