# CR-016 — DATA V1 backfill

| | |
|---|---|
| **Change ID** | CR-016 |
| **Date** | 2026-10-09 (9 Oct, from about 10:05, user) |
| **Requirement** | [REQ-010](../03-Requirements/REQ-010_V1-Backup-Fields.md) [REQ-014](../03-Requirements/REQ-014_Sandbox-Data-Update-To-New-Mapping.md) |
| **Org** | GDRSAND |
| **Deploy ID** | n/a |
| **By** | User (data load) |
| **Status** | Done |

## What changed
**8,387 Accounts** have `Sales_Channel_V1__c` filled (verified 2026-10-13). The load was done by the user outside the assistant sessions.
3 accounts had no V1 at 11:35. A backfill file was prepared for them (git history).

## Rollback
Clear the V1 fields with Data Loader. Not recommended: they are the backup of the old values.
