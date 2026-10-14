# REQ-012 — Cluster Not Updating for Sector-Only Change

| | |
|---|---|
| **ID** | REQ-012 |
| **Status** | ✅ Done (fixed and verified, 32 checks, 0 mismatches) |
| **Requested** | 2026-10-09 |
| **Related** | [CR-018](../04-Change-Records/CR-018_Cluster-Fix.md) · [CON-008](../05-Conflicts/CON-008_Logic-The-Cluster-Stayed-At-5-When-Only.md) · [CON-009](../05-Conflicts/CON-009_Logic-Saving-An-Account-With-Open-Opportunities-Failed.md) · [TECH-001](../07-Technical/TECH-001_Cluster-and-Team-Engine.md) |

## Business need
Bug: Specialty / Self Service showed Cluster 5. Verify cluster and team on all objects

## Scope
- **In:** Specialty / Self Service account stayed in Cluster 5; verify cluster and team on all objects
- **Out:** Data fixes

## Acceptance criteria
1. Sector-only change recalculates the cluster
2. Account save with open Opportunities succeeds
3. 32 cluster/team checks pass

## Output
Change log 2026-10-09 (cluster fix)

## Open questions
None.
