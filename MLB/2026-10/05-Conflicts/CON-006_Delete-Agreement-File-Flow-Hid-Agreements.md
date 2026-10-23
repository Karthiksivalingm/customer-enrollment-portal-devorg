# CON-006 — Delete Agreement File flow removed non-signed agreement files

| | |
|---|---|
| **ID** | CON-006 |
| **Status** | ✅ Resolved 2026-10-08 ([CR-018](../04-Change-Records/CR-018_Deactivate-Delete-Agreement-File-Flow.md)) |

## Conflict
- The client (demo feedback) wanted all agreements visible; only signed ones showed.
- Existing flow `Delete_Agreement_File` (created 2026-09-23): "When a file is uploaded to an Opportunity, delete it unless the title contains 'signed' and it is a PDF."
- No related list had a status filter (checked).

## Resolution
The flow is **deactivated** (not deleted). New agreement files stay.

## Open point
Files deleted earlier may still be in the Recycle Bin (15 days). Restoring them hasn't been requested.
