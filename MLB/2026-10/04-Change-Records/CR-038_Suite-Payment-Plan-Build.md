# CR-038 — Suite Lease payment plan build and editable license fees

| | |
|---|---|
| **Change ID** | CR-038 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | `0AfiV000000BrFVSA0` build (34 components, Agreement_Flow v69) · `0AfiV000000BrIjSAK` DEF-002 fix (v70) · `0AfiV000000BrSPSA0` on-screen summary line removed (v71) · `0AfiV000000Brc5SAC` "Due Date" label for Full (v72) |
| **Status** | Deployed to sandbox, confirmed by user. Parts later changed by [CR-041](CR-041_Payment-Schedule-One-Amount-And-Rename.md) and [CR-042](CR-042_Payment-Due-Dates-As-Text.md) |

## What changed
| Component | Type | Action |
|---|---|---|
| `Opportunity.Number_of_Payment_Plans__c` | Picklist (restricted) | Created: Full, 1–12. Renamed and "1" removed in CR-041. |
| `Opportunity.Payment_Due_Date_1__c` … `_12__c` | Date | Created. Rebuilt as text in CR-042. |
| `Opportunity.Payment_Amount_1__c` … `_12__c` | Text(18) | Created. Replaced by one `Payment_Amount__c` in CR-041. |
| `Opportunity.Payment_Amounts_Numeric_Only` | Validation rule | Created: amounts must match `^[0-9]+(\.[0-9]{1,2})?$`. |
| `Opportunity.Agreement_Sections_Flow_Only` | Validation rule | Year 1–5 License Fee **removed** from the lock; schedule fields **added**. |
| `Agreement_Flow` | Flow | Suite Lease screen: read-only Due Date replaced by the schedule dropdown and dynamic required due dates; amount formulas; `Assign_Suite_To_Opportunity` saves the schedule; `Due_Date__c` = payment 1 date; confirmation text. |
| `Opportunity-Opportunity Layout` | Page layout | Schedule fields added after Due Date. |
| `Ticketing_Opportunity_LRP` | Lightning page | Schedule fields added (arranged in CR-040). |
| `Admin`, `Ticket Sales`, `Marlins Sales Leadership`, `Marlins IT Admin` | Profiles (partial) | Read and edit on the new fields. |

### Follow-up fixes the same day
| Deploy | Flow version | Change |
|---|---|---|
| `0AfiV000000BrIjSAK` | v70 | **DEF-002:** due-date visibility now tests the dropdown value instead of a formula (formulas are not re-evaluated on the screen), so the right number of dates appears and they are required. |
| `0AfiV000000BrSPSA0` | v71 | On-screen line "Payment amounts: …" removed (user request). |
| `0AfiV000000Brc5SAC` | v72 | Full shows its own field labelled **Due Date** (`Suite_Full_Payment_Due_Date`); Payment 1 Due Date shows only for 2 or more payments. |

## Verification
Apex QA class (validate-only `0AfiV000000BrH7SAK`, 7 of 7) and screen tests. Final results after all later changes: [ATR-003](../08-QA/01-Automated-Testing/ATR-003_Suite-Lease-Payment-Schedule-And-Person-Account-Type.md).

## Data impact
DEF-002 was found when a test pressed Next on test Opportunity 006iV000000XUIfQAO: it saved without dates and cleared Due Date. The record was restored with a temporary class (`0AfiV000000BrKLSA0` deployed, `0AfiV000000BrLxSAK` deleted; again `0AfiV000000BrgvSAC` / `0AfiV000000BrIkSAK`). 0 differences, apart from `Prevent_Validations__c`, which org automation stamps on every save (CON-021).

## Rollback
Superseded by CR-041 and CR-042; roll back from CR-042.
