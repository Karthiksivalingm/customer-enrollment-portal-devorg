# CON-021 — Order of the cluster fix and the data load in production

| | |
|---|---|
| **ID** | CON-021 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-09 |
| **Where** | Production |

## Risk
**Order of the cluster fix and the data load in production.** 71 Key Account accounts with manual clusters 2/3/8 would be reset to Cluster 1 if the fix is deployed before the data load

## Mitigation
Load the data first, or restore the manual clusters afterwards
