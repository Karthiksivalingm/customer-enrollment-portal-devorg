# DEP-001 — Sales Channel / Sector transition: production deployment

| | |
|---|---|
| **ID** | DEP-001 |
| **Status** | ⚠ Prepared and validated, **not deployed**. Production validation `0AfPn000002N1BxKAK` passed on 2026-10-07 (113 components, 17/17 tests) |
| **Target** | GDRPROD |
| **Requirements** | [REQ-003](../03-Requirements/REQ-003_Rename-Key-Accounts-To-Key-Account.md) · [REQ-004](../03-Requirements/REQ-004_Add-New-Sector-Values-Where-Old-Values-Are.md) · [REQ-005](../03-Requirements/REQ-005_Production-Deployment-Document.md) · [REQ-006](../03-Requirements/REQ-006_Production-Change-Set-And-Validation.md) · [REQ-007](../03-Requirements/REQ-007_Specialty-CAN-To-Specialty-In-Metadata.md) · [REQ-024](../03-Requirements/REQ-024_Deploy-Key-Account-Package-To-Production.md) |
| **Detailed workbook** | [Deployment-Documents/KeyAccount_Rename_Deployment_Document.xlsx](Deployment-Documents/KeyAccount_Rename_Deployment_Document.xlsx) (steps 1–11, S1–S8, C1–C6, rollback R/R2/R3, test plan) |

## 1. Summary
This rolls out the new Sales Channel / Sector mapping to production in three parts:
- Key Accounts → Key Account;
- new Sector values with cluster rules and page filters;
- Specialty CAN → Specialty in the Typeform flow, tests and reports.

The sandbox changes are in [CR-008](../04-Change-Records/CR-008_Key-Account-References.md), [CR-009](../04-Change-Records/CR-009_New-Sector-Values-In-Logic.md) and [CR-011](../04-Change-Records/CR-011_Specialty-CAN-To-Specialty.md).
The cluster fix ([CR-018](../04-Change-Records/CR-018_Cluster-Fix.md)) and the strict page filters ([CR-017](../04-Change-Records/CR-017_Pages-V1-Fields-And-Strict-Filters.md)) still need packages.

## 2. Component inventory (all built from **production's own files**)
| # | Package | Contents | Rollback package |
|---|---|---|---|
| 1 | [Packages/KeyAccount_Rename_PROD](Packages/KeyAccount_Rename_PROD) | 116 members: 9 test classes, Key Account cluster rules, team records (production users), team picklist field, page filters | `KeyAccount_Rename_PROD_ROLLBACK` |
| 2 | [Packages/Sector_NewValues_PROD](Packages/Sector_NewValues_PROD) | 8 new cluster rules + 2 pages (cumulative) | `Sector_NewValues_PROD_ROLLBACK` (includes `destructiveChangesPost.xml`) |
| 3 | [Packages/SpecialtyCAN_Phase1_PROD](Packages/SpecialtyCAN_Phase1_PROD) | Flow `Lead_From_US_Retailer_Form_Assignment_And_Email`, 2 test classes, 2 reports in folder Cluster6 | `SpecialtyCAN_Phase1_PROD_ROLLBACK` |

The full change-set list (44 components) is in [Deployment-Documents/ChangeSet_Component_List.xlsx](Deployment-Documents/ChangeSet_Component_List.xlsx).

## 3. Pre-deployment steps
Work through [Pre-Deployment-Checklist.md](Pre-Deployment-Checklist.md). For this release:
- **Key Accounts → Key Account was already renamed by hand in production on 2026-10-06** ([CR-007](../04-Change-Records/CR-007_Key-Accounts-To-Key-Account-Rename-In-PRODUCTION.md)). Skip that step, and deploy package 1 soon: production cluster rules still say 'Key Accounts' ([CON-015](../05-Conflicts/CON-015_Production-Sales-Channel-Key-Accounts-Was-Renamed-To.md)).
- Add the new Sector values in Setup and update the dependencies **before** package 2. Pages fail validation otherwise ([CON-002](../05-Conflicts/CON-002_Production-Deploy-Page-Validation-Failed-On-Planned-And.md)).
- Decide the order of data load and cluster fix ([CON-021](../05-Conflicts/CON-021_Order-Of-The-Cluster-Fix-And-The-Data.md)): 71 Key Account accounts have manual clusters.
- Take a DWH export first ([REQ-018](../03-Requirements/REQ-018_Production-Data-Migration-Files.md)).

## 4. Deployment sequence
1 → 2 → 3, as numbered in section 2. Each package depends on the picklist values its components reference.

## 5. Tests to run during validation
`RunSpecifiedTests` with one `--tests` flag per class (production doesn't allow NoTestRun, [CON-001](../05-Conflicts/CON-001_Production-Deploy-Production-Rejects-Test-Level-NoTestRun-And.md)):
```bash
sf project deploy validate -o GDRPROD --metadata-dir 06-Deployment/Packages/KeyAccount_Rename_PROD --test-level RunSpecifiedTests --tests ClusterTeamEngineTest --tests ContactClusterTriggerTest
sf project deploy quick --job-id <validation job id> -o GDRPROD
```

## 6. Post-deployment steps
Activate flow version 4 if needed. Fix the report filters that lost "Key Accounts" ([REQ-020](../03-Requirements/REQ-020_Fix-Accounts-Without-NetSuite-Id-Report.md)).

## 7. Post-deployment verification
Work through [Post-Deployment-Checklist.md](Post-Deployment-Checklist.md) and the QA packs in [QA-Testing/](QA-Testing/):
- cluster per mapping (Key Account = 1, Planned = 5, Self Service = 6, Distributor = 7, Partnerships = 8);
- teams;
- page sections;
- a Typeform lead from Canada gets Specialty.

## 8. Rollback
Deploy the matching `_ROLLBACK` package. Picklist renames are reversed in Setup, and records follow the rename.

## 9. Risk notes
- Production pages differ from the sandbox: the sandbox has unapproved R12, Fulfillment, Order Channel and Tiers work ([CON-004](../05-Conflicts/CON-004_Sandbox-Vs-Production-Sandbox-Pages-Contain-Unapproved-Work.md)).
- 346 production Specialty CAN companies have no Billing Country ([CON-022](../05-Conflicts/CON-022_346-Production-Specialty-CAN-Companies-Have-No-Billing.md)).
- `ShopifyAssociationRetryBatch` doesn't exist in production ([CON-006](../05-Conflicts/CON-006_Sandbox-Vs-Production-ShopifyAssociationRetryBatch-Doesnt-Exist-In-Production.md)).
