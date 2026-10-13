# Goodr: Salesforce Sandbox (GDRSAND)

> **Sandbox repository.** The metadata in `force-app/` mirrors the Goodr **sandbox** (`GDRSAND`). All record data in this
> repository (CSV / Excel) is **sandbox data**. The packages in `06_Deployment/Packages/` are *prepared for* production
> (`GDRPROD`) and haven't been deployed there yet.

**New developer? Start with [01_Instructions/Developer_Onboarding.md](01_Instructions/Developer_Onboarding.md).**
Full dated history of every change: [04_Change_Records/Change_Log.md](04_Change_Records/Change_Log.md).

## Folders

| # | Folder | What's in it | Start here |
|---|---|---|---|
| 01 | [01_Instructions](01_Instructions/) | Rules Claude and the team follow: process, approvals, data, security | [Working_Instructions.md](01_Instructions/Working_Instructions.md) |
| 02 | [02_Knowledge_Base](02_Knowledge_Base/) | Project overview: business context, orgs, mapping, cluster model, client decisions | [Project_Overview.md](02_Knowledge_Base/Project_Overview.md) |
| 03 | [03_Requirements](03_Requirements/) | Every request with ID, date, status and output | [Requirements_Log.md](03_Requirements/Requirements_Log.md) |
| 04 | [04_Change_Records](04_Change_Records/) | What changed, before and after: change log, metadata snapshots, data files | [README](04_Change_Records/README.md) · [Change_Log.md](04_Change_Records/Change_Log.md) |
| 05 | [05_Conflicts](05_Conflicts/) | Conflicts faced and possible conflicts | [Conflicts_Log.md](05_Conflicts/Conflicts_Log.md) |
| 06 | [06_Deployment](06_Deployment/) | Pre/post-deployment checklists, deployment documents, packages + rollbacks, QA, evidence | [README](06_Deployment/README.md) |
| 07 | [07_Technical_Documents](07_Technical_Documents/) | Apex classes, triggers, flows, fields, integrations, impact analysis | [README](07_Technical_Documents/README.md) |
| n/a | `force-app/` | Salesforce source of the sandbox | n/a |
| n/a | `scripts/` | Verification Apex, SOQL, document generators | n/a |
| n/a | `manifest/` | `package.xml` and retrieve manifests | n/a |

## Current project: 2026 Sales Channel / Sector transition
Key Accounts → Key Account; new Sectors Enterprise / Strategic / Discount / Planned / Self Service / Distributor;
Specialty CAN retired into Specialty; V1 backup fields; cluster recalculation on Sector change.
Sandbox metadata: **done**. Sandbox data: **V1 backfill done; Account update applied (159 of 161)**. Production: **packages ready and validated, not deployed**. The Sales Channel value was already renamed to Key Account in production by hand on 2026-10-06 (CHG-07).
Also in the sandbox: **Shopify At-Risk / Warm-Off offboarding** (see [02_Knowledge_Base/Shopify_At_Risk_Offboarding.md](02_Knowledge_Base/Shopify_At_Risk_Offboarding.md)).
See [02_Knowledge_Base/Project_Overview.md](02_Knowledge_Base/Project_Overview.md).

## Quick commands
```bash
sf project retrieve start --metadata ApexClass:ClusterRuleEngine -o GDRSAND
sf project deploy start --source-dir force-app/main/default/classes/ClusterRuleEngine.cls -o GDRSAND --dry-run --test-level RunSpecifiedTests --tests ClusterRuleEngineTest
sf project deploy validate --metadata-dir 06_Deployment/Packages/KeyAccount_Rename_PROD -o GDRPROD --test-level RunSpecifiedTests --tests ClusterTeamEngineTest --tests ContactClusterTriggerTest
```

## Security
Secrets are never committed. `NetSuite_Credential` and `NetSuite_Config` custom metadata are excluded by `.gitignore` and `.forceignore`.
Org auth (`.sf/`, `.sfdx/`) is git-ignored. The repository is private.
