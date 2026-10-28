# Rollback Procedures

A rollback is itself a deployment: it needs explicit approval and is recorded in the DEP record (and a CF record explaining why).

| Component type | Rollback method | Notes |
|---|---|---|
| Apex class / trigger | Redeploy the backup from `06-Deployment/Backups/DEP-NNN/` with its tests | New classes: remove with `destructiveChanges.xml` (approval needed) |
| Flow | Reactivate the previous version (Setup → Flows → version) or redeploy the backup | Record which version is active before and after |
| Custom field | Redeploy the previous definition. Deleting a field loses its data (recoverable only for 15 days) | Never delete without separate approval |
| Picklist values | Redeploy the previous value set; values in use stay on records | Check record data before deactivating values |
| Validation rule | Redeploy the previous version or deactivate | |
| Permission set / page / layout | Redeploy the backup | |
| Record data | Restore from the CR record's before-values export | Needs its own CR and approval |

What cannot be reversed by metadata alone: deleted fields and their data, data changed by automation while the change was live,
emails or callouts already sent. List these in the DEP record before deploying.
