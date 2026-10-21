# CR-031 — One Agreement Flow for create and edit

| | |
|---|---|
| **Change ID** | CR-031 |
| **Date** | 2026-10-21 |
| **Requirement** | [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV000000Anp3SAC |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `Agreement_Flow` | Screen flow | v68: rebuilt from v67 (which already had the new "1 year New Business" term choice, added in the org on 2026-10-19). Adds `Get_Existing_Rows`, decision `Has_Agreement`, assignment `Set_Prefill`, formula `frmAgreementType`, variables `prefillOpp` and `prefillRows`, plus all prefill defaults, row update / create / delete and rollback from the edit flow. |
| `Opportunity.Edit_Agreement` | Quick action | Now opens `Agreement_Flow`. |
| `Edit_Agreement_Flow` | Screen flow | Deactivated and all 4 versions deleted. |

## Behaviour
- No Agreement Type: Select Agreement Type screen, then blank screens. `prefillOpp` / `prefillRows` stay empty, so stale hidden values and stray rows are not shown or changed.
- Agreement Type set: the type screen is skipped and `Set_Prefill` loads the saved Opportunity and rows.

## Verification
- Backend: 13 of 13 tests passed (validate 0AfiV000000AoTNSA0).
- Screen: new mode showed the type screen and blank Membership row counts; edit mode skipped the type screen and showed the saved Suite Lease values; a Suite Lease save stored Parking Passes 15, Games 41 and "Forty-One (41)". The record was restored afterwards (0 differences).

## Rollback
Activate Agreement_Flow v67 and point the Edit Agreement quick action back at a separate flow (restore `Edit_Agreement_Flow` from Git history).
