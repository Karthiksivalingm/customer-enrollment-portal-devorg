# CR-028 — Company page: YTD and At-Risk fields

| | |
|---|---|
| **Change ID** | CR-028 |
| **Date** | 2026-10-21 |
| **Requirement** | [REQ-036](../03-Requirements/REQ-036_Company-Page-YTD-And-At-Risk-Fields.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GQIT7CAP` (validated by `0Afdx00000GQIPtCAP`) |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `Account_Company_Record_Page` | Lightning page | Shopify Sales Performance section. **Left column**, after R12 Sales Performance Percent: Current YTD Sales, YTD Performance Percent. **Right column**, after R12 Calculation Last Run: Prior YTD Sales, At Risk Since, At Risk Episode Count. All five are read-only on the page |

**Not changed:** no fields, field access, automation or other page. All five fields are already readable by 23 profiles.

**Repository:** only these lines are committed. The live page also has an unrelated, uncommitted visibility rule on `Is_Saved_Record__c` that was already in the sandbox (see CR-026); it is still not committed.

## Verification
- The page retrieved from the sandbox after the deploy contains all five fields.
- Sample Company at risk: Current YTD 777.54, Prior YTD 3,951.60, YTD 19.68%, At Risk Since 2026-09-11, episode 1.

## Rollback
Redeploy `Account_Company_Record_Page` from the previous commit.
