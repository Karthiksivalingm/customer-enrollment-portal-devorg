# CR-027 — Membership Agreement: manual edits blocked

| | |
|---|---|
| **Change ID** | CR-027 |
| **Date** | 2026-10-14 to 2026-10-15 |
| **Requirement** | [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | 0AfiV0000009X1ZSAU (rule, ISCHANGED on all fields) · 0AfiV0000009k6sSAA (Flow_Update__c exception, reset flow) |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `Membership_Agreement__c.Membership_Agreement_Flow_Only` | Validation rule | Created. Blocks an update when any of the 35 editable fields changes, unless `Flow_Update__c` is ticked in the same save. New records are not affected. |
| `Membership_Agreement__c.Flow_Update__c` | Checkbox | Created. Hidden: no field access for any profile, not on the layout. |
| `Membership_Agreement_Reset_Flow_Update` | Record-triggered flow (after save, create and update) | Created. Unticks `Flow_Update__c` straight after a save that ticked it. |

## History
1. 2026-10-14: first built as a marker-flip rule with a test class. The user asked for a validation rule only, so the class and field were deleted and the rule rewritten as ISCHANGED on all fields (0AfiV0000009X1ZSAU).
2. 2026-10-15: for Edit Agreement to update rows, `Flow_Update__c` was re-created as a tick-and-reset checkbox and the rule gained `NOT(Flow_Update__c)`.
3. The error message was later changed directly in the org to "…Please use the Edit Agreement button on the Opportunity." and synced back to the project on 2026-10-19.

## Verification
Manual edits blocked for administrator and Sales Manager; flow updates saved and the box reset; 200-row bulk; deletes allowed. See ATR-001 TC-014-01 to 07 and 22.

## Rollback
Deactivate the validation rule. Optionally deactivate the reset flow and delete the checkbox field.

## Change set note
The outbound change set "Membership Agreement Flow Only" was created on 2026-10-14. Its components must be added by hand in Setup (see TECH-009, production notes).
