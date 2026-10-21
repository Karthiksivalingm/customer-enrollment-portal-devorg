# CR-027 — Auto-Offboarding Exclusion: warm-off batch and at-risk task flow

| | |
|---|---|
| **Change ID** | CR-027 |
| **Date** | 2026-10-21 (21 Oct 11:35 IST) |
| **Requirement** | [REQ-035](../03-Requirements/REQ-035_Auto-Offboarding-Exclusion.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GQ8WzCAL` (validated by `0Afdx00000GQ8QXCA1`) |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `ShopifyAtRiskNoticeBatch` | Apex class | `warmOffStart()`: two extra filters, `Exclude_From_Auto_Offboarding__c = false` and `Parent.Exclude_From_Auto_Offboarding__c = false`. `legacyStart()`: the same filters on `Account.` / `Account.Parent.`. Header comment updated. No other line changed |
| `ShopifyAtRiskNoticeBatchTest` | Apex test | 6 new tests: excluded store at 18 months stays active with no Email 5; excluded store at 17 months gets no notice and no task; excluded Company covers its store; non-excluded store still processed; excluded store skipped by the legacy run; at-risk task skipped for an excluded store and for a store under an excluded Company |
| `Create_At_Risk_Task_for_Account_Owner` | Flow | Version 2 active, version 1 obsolete. New entry condition `Exclude_From_Auto_Offboarding__c = false`; new Decision "Is Company Excluded?" ends the flow when `$Record.Parent.Exclude_From_Auto_Offboarding__c` is true. Description added |

**How the skip works:** an excluded store is never selected by the daily job, so no notice, email, task or deactivation is created for it. Existing notices are left unchanged.

**Not changed:**
- the Send Shopify At Risk Notice flow and `SendWarmOffEmail`
- Set At Risk Dates
- the offboarding date/user flow
- `AccountTriggerHelper` (rollup and cascade)
- the validation rules
- R12 and order sync
- the Shopify integration

The schedule "Shopify At Risk Notices Daily" is unchanged and still waiting.

## Verification
- Deploy `0Afdx00000GQ8WzCAL`, tests `ShopifyAtRiskNoticeBatchTest` and `AccountTriggerHelperTest`: **63 passed, 0 failed**.
- Coverage of `ShopifyAtRiskNoticeBatch`: 94.1%.
- Flow versions checked: v2 Active, v1 Obsolete.
- Scheduled job still `WAITING`.

## Rollback
Reactivate version 1 of `Create_At_Risk_Task_for_Account_Owner`, then redeploy `ShopifyAtRiskNoticeBatch` and `ShopifyAtRiskNoticeBatchTest` from the previous commit.
