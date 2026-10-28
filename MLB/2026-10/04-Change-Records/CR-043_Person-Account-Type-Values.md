# CR-043 — Food and Beverage and Non-Profit added to Person Account Type

| | |
|---|---|
| **Change ID** | CR-043 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-020](../03-Requirements/REQ-020_Person-Account-Type-Values.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | `0AfiV000000Bs57SAC` |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `PersonAccount.PersonAccount` | Record type | Account `Type` picklist: **Food and Beverage** and **Non-Profit** added. |

Local file: `force-app/main/default/objects/PersonAccount/recordTypes/PersonAccount.recordType-meta.xml` (retrieved from the org first, then changed).

## Verification
UI API picklist values for the Person Account record type now list 13 values including both. Apex save of Person Accounts with each value as a Sales Manager, and the edit screen, also checked (ATR-003 TC-020-01 to 03).

## Rollback
Remove the two `<values>` entries and redeploy the record type.
