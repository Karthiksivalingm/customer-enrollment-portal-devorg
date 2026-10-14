# CR-015 — V1 backup fields

| | |
|---|---|
| **Change ID** | CR-015 |
| **Date** | 2026-10-09 (9 Oct 09:49, Session A) |
| **Requirement** | [REQ-010](../03-Requirements/REQ-010_V1-Backup-Fields.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GEjosCAD` |
| **By** | Session A |
| **Status** | Done |

## What changed
Deploy `0Afdx00000GEjosCAD` (dry run `GEnxJCAT`): `Account.Sales_Channel_V1__c` and `Account.Sector_V1__c` (Text 50, help text "do not edit"), System Administrator Read/Edit.
Text was chosen over picklist so any old value can be stored.


## Rollback
Delete the two fields. This also deletes the backup values they hold, so not recommended.
