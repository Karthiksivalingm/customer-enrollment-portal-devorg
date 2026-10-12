# Change Records: what changed, before and after

| What | Before | After |
|---|---|---|
| **Metadata** (classes, rules, pages, flows, reports) | `Metadata_Before_Snapshots/<date>_<Change>/`: copied from the org just before each change | `force-app/main/default/` (current sandbox version) |
| **Record data** (Sales Channel / Sector values) | `Data_Changes/DataMigration_Account_Sandbox/source_exports/` (existing values) and the V1 backup fields | The `New Sales Channel` / `New Sector` columns and the Data Loader update files |
| **History of every deploy** | n/a | [Change_Log.md](Change_Log.md): date, deploy ID, components |

## Metadata before snapshots
| Folder | Contents |
|---|---|
| `2026-10-06_KeyAccount_Sector` | 9 test classes, ShopifyAssociationRetryBatch, cluster rules, team records, pages before the Key Account rename |
| `2026-10-08_SpecialtyCAN` | Flow (local copy and org v3), 2 test classes, 2 Cluster 3 CAN reports |
| `2026-10-09_V1_Fields_PageFilters` | Company, Store Location, Franchise and Lead pages: org baseline and local copy before the change |
| `2026-10-09_ClusterFix` | ClusterRuleEngine, AccountCascadeHandler, LeadConversionHandler and their tests before the fix |

To restore a component, deploy the snapshot file back with `sf project deploy start --source-dir <file> -o GDRSAND`
after copying it into `force-app/`.

## Data changes (sandbox): status **prepared, not loaded**
Mapping: see [02_Knowledge_Base/Project_Overview.md](../02_Knowledge_Base/Project_Overview.md).

| File | Rows | Purpose |
|---|---|---|
| `1_V1_Backfill_DataLoader.csv` | 3 | Fill empty V1 backups first |
| `2a_Account_Update_PILOT_DataLoader.csv` | 7 | One record per mapping, then check |
| `2_Account_Update_DataLoader.csv` | 161 | Full Account update |
| `3_Account_Rollback_DataLoader.csv` | 161 | Restore the old values from V1 |
| `SalesChannel_Sector_Records_To_Update_Sandbox.xlsx` | 989 | All 4 objects: 312 ready, 677 need a decision (mostly Specialty CAN with blank Sector) |
| `source_exports/mig_*.csv` | n/a | Raw exports the files above were built from |

The record data in this folder is **sandbox data only**.
