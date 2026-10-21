# CR-030 — DEF-001: Paid to Date change blocked by the Opportunity rule

| | |
|---|---|
| **Change ID** | CR-030 |
| **Date** | 2026-10-19 (deployed 09:35 UTC) |
| **Requirement** | [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) |
| **Found by** | ATR-001, TC-014-13 (validate 0AfiV000000ALw1SAG failed) |
| **Org** | utdev sandbox |
| **Status** | Deployed to sandbox, retested (validate 0AfiV000000AMDlSAO), confirmed by user |

## Problem
Changing Paid to Date through the agreement edit failed with "Agreement details can't be edited manually". The reset flow re-saved the row; in that re-save Paid to Date still counted as changed, so `Update_Opportunity_from_Membership_Agreement` ran and updated the Opportunity's Total Paid to Date without flipping `Agreement_Flow_Update__c`.

## What changed
| Component | Type | Action |
|---|---|---|
| `Update_Opportunity_from_Membership_Agreement` | Record-triggered flow | v5: also flips `Agreement_Flow_Update__c` (formula on the Opportunity's current value). |
| `Edit_Agreement_Flow` (now `Agreement_Flow`, CR-031) | Screen flow | Saves the Opportunity before creating, updating or deleting Membership rows, so the two Opportunity saves don't collide. |

## Verification
TC-014-13 passed in the backend; TC-014-18 passed on screen with a Paid to Date change (rows and Opportunity at 12,500).

## Rollback
Activate the previous versions of both flows. Paid to Date edits would fail again.
