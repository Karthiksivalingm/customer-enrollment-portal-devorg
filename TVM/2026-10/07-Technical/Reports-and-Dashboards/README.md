# Reports and Dashboards

**Not retrieved into source** (scope decision pending, see [Metadata-Scope.md](../Metadata-Scope.md)).

| Item | Count in Fullsandbox (unmanaged) | Evidence |
|---|---|---|
| Reports | 5,834 | `SELECT COUNT() FROM Report WHERE NamespacePrefix = null`, 2026-10-14 |
| Dashboards | 412 | SOQL count, 2026-10-14 |
| Report folders / dashboard folders | 470 / 104 | `sf org list metadata` |
| Report types (custom) | retrieved | [Other-Metadata.md](../Metadata-Inventory/Other-Metadata.md) |
| Report/dashboard subscriptions | ~100 scheduled (CronTrigger job type A) | [Scheduled-Jobs.md](../Scheduled-and-Batch-Jobs/Scheduled-Jobs.md) |
| Apex that sends reports | `ReportsToExternalUsers` (driven by `Reports_To_External_User__mdt`) | Source |

To bring a folder into scope: name it, add `Report`/`Dashboard` members for that folder to `scripts/build_manifest.py`, and retrieve.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created during setup. |
