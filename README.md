# Goodr – Salesforce Sandbox (GDRSAND)

> **Sandbox repository.** Everything here was built and deployed in the Goodr **sandbox** (`GDRSAND`).
> The record data in this repo (CSV / Excel) is **sandbox data**. Folders whose names end in
> `_PROD` are packages *prepared for* production (`GDRPROD`). They have **not** been deployed to production.

## What this project covers

Goodr's Sales Channel and Sector picklist values were moved to a new mapping on
**Account, Contact, Lead and Opportunity**:

| Old Sales Channel | Old Sector | New Sales Channel | New Sector |
|---|---|---|---|
| Key Accounts | Core | Key Account | Enterprise |
| Key Accounts | Mid-Market | Key Account | Strategic |
| Key Accounts | Off-Price | Key Account | Discount |
| Specialty | Bridge | Specialty | Planned |
| Specialty | Sellgoodr USA | Specialty | Self Service |
| Specialty | Sellgoodr CAN | Specialty | Self Service |
| Specialty CAN | Sellgoodr CAN | Specialty | Self Service |
| Specialty CAN | Bridge | Specialty | Planned |
| Partnerships | Partnerships | Partnerships | Partnerships |
| Global | Global | Global | Distributor |

The work was delivered in five workstreams. See [CHANGELOG.md](CHANGELOG.md) for every sandbox
deploy with its ID.

1. **Key Account rename**: `Key Accounts` → `Key Account` in rules, team records, tests and page filters.
2. **Sector new values**: Enterprise / Strategic / Discount / Planned / Self Service / Distributor, plus cluster rules and page filters.
3. **Specialty CAN retirement**: the flow, tests and reports moved to `Specialty`.
4. **V1 backup fields**: `Sales_Channel_V1__c` and `Sector_V1__c` on Account (editable by admins only) keep the old values.
5. **Cluster fix**: the cluster is recalculated when only the Sector changes, and Sector cascades from Account to open Opportunities.

## Repository layout

```
Goodr (repo root)
├── force-app/main/default/        Salesforce metadata source of the SANDBOX (deploy target: GDRSAND)
│                                    classes, triggers, flows, flexipages, customMetadata, objects, reports …
├── manifest/
│   ├── package.xml                 default project manifest
│   └── retrieve/                   manifests used to retrieve / compare components during the work
├── deployment/                     PRODUCTION-READY packages (mdapi format) + rollbacks + data loads
│   ├── KeyAccount_Rename_PROD/            + KeyAccount_Rename_PROD_ROLLBACK/
│   ├── Sector_NewValues_PROD/             + Sector_NewValues_PROD_ROLLBACK/
│   ├── SpecialtyCAN_Phase1_PROD/          + SpecialtyCAN_Phase1_PROD_ROLLBACK/
│   └── DataMigration_Account_Sandbox/     Data Loader CSVs (V1 backfill → pilot → full → rollback)
│       └── source_exports/                the record exports the load files were built from
├── docs/
│   ├── 1_Analysis/                 where-used / impact analysis
│   ├── 2_Deployment/               deployment document, change-set component list
│   ├── 3_QA/                       QA test scenarios, cluster/team reference, page-section checks
│   └── 4_Verification_Evidence/    results of the cluster/team checks, page rule exports, test runs
├── scripts/
│   ├── apex/verification/          anonymous Apex used to verify cluster + team live (rolls back, no data left)
│   ├── apex/, soql/                project template samples
│   └── doc-builders/               PowerShell (Excel COM) scripts that generated the workbooks
├── backups/sandbox_pre_change/     copies of each component taken from the org BEFORE it was changed
├── config/                         scratch-org definition (template)
└── sfdx-project.json               project "Goodr", package directory force-app, API 59.0
```

### Where to put new items

| Item | Location |
|---|---|
| Metadata changed in the sandbox | `force-app/main/default/<type>/` (retrieve first, then edit) |
| A package prepared for production | `deployment/<Change>_PROD/` with a matching `<Change>_PROD_ROLLBACK/` |
| Data Loader files | `deployment/DataMigration_<Object>_<Org>/`, with raw exports in `source_exports/` |
| Analysis workbook | `docs/1_Analysis/` |
| Deployment document / change-set list | `docs/2_Deployment/` |
| QA / UAT workbooks | `docs/3_QA/` |
| Proof that a change works (query output, test results) | `docs/4_Verification_Evidence/` |
| Snapshot of a component before changing it | `backups/sandbox_pre_change/<yyyy-mm-dd>_<Change>/` |
| Reusable Apex / SOQL / PowerShell | `scripts/` |

## Key documents

| Document | Purpose |
|---|---|
| [docs/2_Deployment/KeyAccount_Rename_Deployment_Document.xlsx](docs/2_Deployment/KeyAccount_Rename_Deployment_Document.xlsx) | Production deployment steps for all three workstreams (Key Account, Sector, Specialty CAN), test plan and rollback |
| [docs/2_Deployment/ChangeSet_Component_List.xlsx](docs/2_Deployment/ChangeSet_Component_List.xlsx) | The 44 components for the outbound change set |
| [docs/1_Analysis/Sector_Where_Used_Analysis.xlsx](docs/1_Analysis/Sector_Where_Used_Analysis.xlsx) | Where Sales Channel / Sector are used and the impact of each change |
| [docs/3_QA/QA_Test_Scenarios_KeyAccount_Sector_SpecialtyCAN.xlsx](docs/3_QA/QA_Test_Scenarios_KeyAccount_Sector_SpecialtyCAN.xlsx) | 36 UI test cases |
| [docs/3_QA/QA_Cluster_Team_Assignment_Reference.xlsx](docs/3_QA/QA_Cluster_Team_Assignment_Reference.xlsx) | Expected cluster and team for each Sales Channel / Sector |
| [docs/3_QA/QA_LRP_Sections_by_SalesChannel_Sector.xlsx](docs/3_QA/QA_LRP_Sections_by_SalesChannel_Sector.xlsx) | Which record-page sections show for each value |
| [deployment/DataMigration_Account_Sandbox/SalesChannel_Sector_Records_To_Update_Sandbox.xlsx](deployment/DataMigration_Account_Sandbox/SalesChannel_Sector_Records_To_Update_Sandbox.xlsx) | All 989 sandbox records with their existing and new values |

## Common commands

```bash
# Sandbox: retrieve before editing, check-only deploy, then deploy
sf project retrieve start --metadata ApexClass:ClusterRuleEngine --target-org GDRSAND
sf project deploy start --source-dir force-app/main/default/classes/ClusterRuleEngine.cls --target-org GDRSAND --dry-run --test-level RunSpecifiedTests --tests ClusterRuleEngineTest

# Production: validate a prepared package (production does not allow NoTestRun)
sf project deploy validate --metadata-dir deployment/KeyAccount_Rename_PROD --target-org GDRPROD --test-level RunSpecifiedTests --tests ClusterTeamEngineTest --tests ContactClusterTriggerTest
```

## Working rules

- Retrieve the latest version from the org and take a backup (`backups/`) before changing anything.
- Make the smallest change possible. Existing working logic must not change.
- Run a check-only (`--dry-run`) deploy first. Deploy only after approval.
- Don't change record data unless it has been approved.
- Verify after each deploy and save the evidence in `docs/4_Verification_Evidence/`.

## Known open items

- `planda@goodr.com` (Global, Cluster 7, Sales Director) is inactive, so the team has 4 members.
- Two test accounts in the sandbox (`R12 Test Company Sandbox`, `Test Team`) still show Cluster 5 with Self Service.
- 2 `ShopifyOrderSyncTest` methods fail in the sandbox only. This was already the case before this work.
- `AccountCascadeHandler` in the sandbox contains `ContactTeamReassignQueueable`. This line is not part of this work and isn't in production.
- Production: 346 Specialty CAN companies have no Billing Country. In 71 Key Account accounts, clusters set by hand (2/3/8) are reset to Cluster 1 if the cluster fix is deployed before the data load.
- The production data migration and the production page package are still pending.

## Notes

- The scripts in `scripts/doc-builders/` were run from a temporary working folder. Before re-running one, update the `$sp` / `$out` paths at the top of the script.
- `.sf/`, `.sfdx/`, logs and `node_modules/` are git-ignored. Org connections are never stored in this repo.
