# CR-018 — Cluster fix

| | |
|---|---|
| **Change ID** | CR-018 |
| **Date** | 2026-10-09 (9 Oct 10:34) |
| **Requirement** | [REQ-012](../03-Requirements/REQ-012_Cluster-Not-Updating-For-Sector-Only-Change.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GEpsfCAD` |
| **By** | Assistant |
| **Status** | Done |

## What changed
**Problem (reported by the user):** a Specialty / Self Service account stayed in Cluster 5. Live testing found two bugs:
1. Changing only the Sector didn't re-cluster the record.
2. Saving an Account with open Opportunities failed with an invalid dependent Sector.

Deploy `0Afdx00000GEpsfCAD` (dry run `GEpUTCA1`, 119/119 tests; coverage ClusterRuleEngine 93%, AccountCascadeHandler 100%, LeadConversionHandler 88%):
- `ClusterRuleEngine` re-evaluates when Sales Channel **or** Sector changes (safe getter for objects without Sector).
- `AccountCascadeHandler` and `LeadConversionHandler` copy Sector to open Opportunities.
- Tests: `ClusterRuleEngineTest` and `AccountCascadeHandlerTest` each gained one test.

Re-check, rolled back afterwards: 32 cluster/team checks, 0 mismatches. Test report: [ATR-001](../08-QA/01-Automated-Testing/ATR-001_Cluster-And-Team-Old-And-New-Mapping.md).

## Rollback
Redeploy the previous class versions from git history.
