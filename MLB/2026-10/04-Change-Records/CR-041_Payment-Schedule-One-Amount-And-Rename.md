# CR-041 — Number of Payment Schedule, one Payment Amount, option "1" removed

| | |
|---|---|
| **Change ID** | CR-041 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | `0AfiV000000BxSzSAK` (fields, rules, Agreement_Flow v73, page, layout, profiles) · `0AfiV000000BxeISAS` (12 amount fields deleted). Failed attempts: `0AfiV000000BxJJSA0`, `…BxO9SAK`, `…BwgcSAC`, `…Buq6SAC` (page filter limits, CON-020), `…BuyBSAS`, `…Bv4cSAC` (fields still used by old flow versions) |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `Opportunity.Number_of_Payment_Plans__c` | Picklist | Label **Number of Payment Schedule** (API name kept); value **1** removed; help text "2-12". |
| `Opportunity.Payment_Amount__c` | Text(18) | **Created**: one amount for every payment. |
| `Opportunity.Payment_Amount_1__c` … `_12__c` | Text | **Deleted** (in the recycle bin for 15 days). |
| `Payment_Amounts_Numeric_Only` | Validation rule | Checks `Payment_Amount__c` only. |
| `Agreement_Sections_Flow_Only` | Validation rule | 12 amount fields replaced by `Payment_Amount__c`. |
| `Agreement_Flow` | Flow (v73) | Choice "1" removed; formulas `frmPayAmountCents` = ROUND(total × 100 ÷ count) and `frmPayAmount`; the per-payment amount and summary formulas removed; saves `Payment_Amount__c`; label and confirmation text "Number of Payment Schedule", "Payment Amount". |
| `Ticketing_Opportunity_LRP` | Lightning page | 12 amount rows replaced by Payment Amount; due-date row visibility rebuilt (CON-020). |
| `Opportunity-Opportunity Layout` | Page layout | 12 amount fields replaced by Payment Amount. |
| 4 profiles | Profiles (partial) | Read and edit on `Payment_Amount__c`. |
| Agreement_Flow versions 69–72 | Flow versions (inactive) | **Deleted**, approved by the user, so the amount fields could be deleted. |
| Adobe entries | Data | See CR-039. |

## Verification
Validate-only `0AfiV000000BxcfSAC` (7 of 7); the screen offered Full, 2–12 with the right due dates. Final results: ATR-003.

## Data impact
Opportunity 006iV000000PlTgQAK still holds the now inactive value "1" (CON-021).

## Rollback
Recreate the amount fields from git history (they are also in the recycle bin until 2026-11-11) and redeploy the CR-038 versions of the flow, rules, page and layout.
