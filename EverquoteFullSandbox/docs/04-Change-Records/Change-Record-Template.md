# CR-xxxx: <Short title>

| Field | Value |
|---|---|
| Date | YYYY-MM-DD |
| Requirement | REQ-xxxx |
| Change type | Metadata / Configuration / Data |
| Org(s) | EverquotefullSandbox / Production / … |
| Made by | |
| Reviewed by | |
| Git commit / branch | |
| Deployment log | DEP-… |

## Summary
What changed and why, in one or two sentences.

## Before and after

**Metadata and configuration**

| Component type | API name | Before | After |
|---|---|---|---|
| CustomField | Lead.Example__c | Picklist values: A, B | Picklist values: A, B, C |
| ApexClass | LeadTriggerHandler | `if (x > 5)` | `if (x >= 5)` |

**Data**

| Object | Filter / record count | Field | Before | After |
|---|---|---|---|---|
| Lead | Status = 'Open' (1,234 rows) | OwnerId | Queue: X | Queue: Y |

Backup file (stored outside Git): `<file name>`

## Testing / verification
How the change was verified, with test class results or a coverage percentage.

## Rollback steps
1. …
