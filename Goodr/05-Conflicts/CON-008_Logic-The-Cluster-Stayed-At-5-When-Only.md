# CON-008 — Logic: The cluster stayed at 5 when only the Sector changed

| | |
|---|---|
| **ID** | CON-008 |
| **Status** | ✅ Resolved |
| **Found** | 2026-10-09 |
| **Area** | Logic |

## Conflict
The cluster stayed at 5 when only the Sector changed (Specialty / Self Service should be 6)

## Resolution
`ClusterRuleEngine` now re-evaluates when Sales Channel **or** Sector changes
