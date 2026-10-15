# CON-004: Old and new versions of the same automation both active

| Field | Value |
|---|---|
| Status | ⚠ Open |
| Severity | 🟠 Medium |
| Found | 2026-10-13 |
| Related | [TECH-015](../07-Technical/TECH-015_Flow-Inventory.md) · [TECH-017](../07-Technical/TECH-017_Process-Flow-Migrations.md) |

- The legacy Process Builder `BDR_Activity_completed_change_lead_owner_to_activity_owner` and its replacement `Task_BDR_Activity_Completed_Change_Lead_Owner` are both active. Both filter on `WhatId` starting with `00Q`, a Lead, which can't be a Task's WhatId, so neither appears to fire.
- The 121 process flow migration records map 47 processes to 56 flows. Eight sources were migrated to two or three flows each, which risks **duplicate active flows**. All of these flows are now in `force-app/flows/` and can be checked.
- 34 workflow rules carry a `failedMigrationToolVersion` marker, meaning the Migrate to Flow tool failed on them.
- 69 Process Builders are still in the org. Salesforce has retired Process Builder.
