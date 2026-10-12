# Deployment

| Folder / file | Contents |
|---|---|
| [Pre_Deployment_Checklist.md](Pre_Deployment_Checklist.md) | What to do **before** any deployment |
| [Post_Deployment_Checklist.md](Post_Deployment_Checklist.md) | What to check **after** a deployment |
| `Deployment_Documents/` | Production deployment document (steps, tests, rollback), change set component list, Shopify at-risk offboarding document |
| `Packages/` | Production-ready packages (mdapi format), each with a `_ROLLBACK` package |
| `QA_Testing/` | QA test scenarios, cluster/team reference, page-section checks |
| `Post_Deployment_Verification/` | Evidence from the sandbox: cluster/team check results, page rule exports, test runs |

## Production packages: deploy in this order
| # | Package | Contents | Rollback |
|---|---|---|---|
| 1 | `Packages/KeyAccount_Rename_PROD` | 116 members: 9 test classes, cluster rules, team records, page filters | `KeyAccount_Rename_PROD_ROLLBACK` |
| 2 | `Packages/Sector_NewValues_PROD` | 8 new cluster rules + 2 pages (cumulative) | `Sector_NewValues_PROD_ROLLBACK` (includes `destructiveChangesPost.xml`) |
| 3 | `Packages/SpecialtyCAN_Phase1_PROD` | Flow, 2 test classes, 2 Cluster 6 reports | `SpecialtyCAN_Phase1_PROD_ROLLBACK` |

Picklist value changes (rename Key Accounts, add the new Sector values) are **manual Setup steps** done before the packages.
The exact step numbers are in `Deployment_Documents/KeyAccount_Rename_Deployment_Document.xlsx`.

```bash
# Validate (check-only) in production
sf project deploy validate -o GDRPROD --metadata-dir 06_Deployment/Packages/KeyAccount_Rename_PROD --test-level RunSpecifiedTests --tests ClusterTeamEngineTest --tests ContactClusterTriggerTest
# Quick-deploy the validated job after approval
sf project deploy quick --job-id <validation job id> -o GDRPROD
```
