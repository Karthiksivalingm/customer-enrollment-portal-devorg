# REQ-014 — Sandbox Data Update to New Mapping

| | |
|---|---|
| **ID** | REQ-014 |
| **Status** | ✅ Done: files prepared by Claude; loaded in the sandbox by the user (159 of 161 applied, see CR-019) |
| **Requested** | 2026-10-10 |
| **Related** | [CR-016](../04-Change-Records/CR-016_DATA-V1-Backfill.md) · [CR-019](../04-Change-Records/CR-019_DATA-Account-Sales-Channel-Sector-Update-In-The.md) |

## Business need
Data update plan: export of existing and new values, Data Loader files, Mid-Market → Strategic

## Scope
- **In:** Export of existing and new values, Data Loader files (V1 backfill, pilot, full, rollback); Mid-Market maps to Strategic
- **Out:** Production data

## Acceptance criteria
1. Load files match the approved mapping
2. Rollback file available

## Output
`04-Change-Records/Data-Changes/DataMigration_Account_Sandbox/`

## Open questions
None.
