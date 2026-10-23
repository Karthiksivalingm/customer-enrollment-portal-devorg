# CR-029 — Opportunity: agreement fields locked to the agreement flow

| | |
|---|---|
| **Change ID** | CR-029 |
| **Date** | 2026-10-15 (deployed 08:13 UTC) |
| **Requirement** | [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) |
| **Org** | utdev sandbox |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `Opportunity.Agreement_Flow_Update__c` | Checkbox | Created. Hidden: no field access, not on any layout. |
| `Opportunity.Agreement_Sections_Flow_Only` | Validation rule | Created. Blocks a change to any of the 35 editable fields in the four agreement sections unless `Agreement_Flow_Update__c` flips in the same save. New Opportunities are not affected. |
| `Agreement_Flow` | Screen flow | v66: each Assign_*_To_Opportunity flips `Agreement_Flow_Update__c`; runs in system mode with sharing so it can set the hidden field. |
| `Update_Opportunity_from_Membership_Agreement` | Record-triggered flow | v4: skips rows saved with `Flow_Update__c` ticked (superseded by CR-030). |

## Design note
The Opportunity uses **flip** (set to the opposite value), not tick-and-reset, so no second Opportunity save is needed. A second save would re-run every Opportunity trigger and flow, including Adobe Sign.

## Verification
Parking Passes, Suite Location and Payment Plan blocked for the administrator; Next Step saved; a flow save with the flip succeeded; manual edit after it blocked. See ATR-001 TC-014-08 to 12.

## Rollback
Deactivate the validation rule. The flows keep working without it.
