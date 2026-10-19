# CR-019 — DATA Account Sales Channel / Sector update in the sandbox

| | |
|---|---|
| **Change ID** | CR-019 |
| **Date** | 2026-10-09 → 2026-10-13 (9 → 13 Oct, user) |
| **Requirement** | [REQ-014](../03-Requirements/REQ-014_Sandbox-Data-Update-To-New-Mapping.md) |
| **Org** | GDRSAND |
| **Deploy ID** | n/a |
| **By** | User (data load) |
| **Status** | Done (see note) |

## What changed
Verified 2026-10-13 against the Data Loader update file (161 rows; kept in git history):
- **159 of 161 rows** in the org match the new values. 163 Accounts now hold new Sector values: Self Service 131, Planned 11, Enterprise 10, Distributor 7, Strategic 4.
- 2 rows differ because those records were changed to other values afterwards: **Missoula Scheels** (file Key Account/Enterprise, org Partnerships/Partnerships) and **Test TVK** (file Key Account/Strategic, org Global/Distributor).
- 3 test accounts not in the file (R12 Test Company Sandbox, Test Team, R12 WOT T6 Late) also hold new values.
- Exact load time is unknown, because Sector has no field history. Accounts were last modified by the shared login on 10-09 (44), 10-11 (1) and 10-13 (118).
- Contact, Opportunity: no records on the new Sector values yet. Lead: 1 (Distributor).
- Rollback file: `3_Account_Rollback_DataLoader.csv`.

## Rollback
Load the rollback file from git history (restores the V1 values).
