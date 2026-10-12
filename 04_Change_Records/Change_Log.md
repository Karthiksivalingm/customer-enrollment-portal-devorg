# Goodr Sandbox (GDRSAND): Change Log

Every change below was check-only validated first and deployed to the **sandbox** only after approval.
A copy of each component as it was before the change is in `04_Change_Records/Metadata_Before_Snapshots/`.

## 2026-10-06 · Key Account rename (`Key Accounts` → `Key Account`)
Backup: `04_Change_Records/Metadata_Before_Snapshots/2026-10-06_KeyAccount_Sector`

| Deploy ID | Components |
|---|---|
| `0Afdx00000GAgZSCA1` | Sales_Channel_Cluster rules: Keys_Account_Account, Key_Account_Lead, Key_Account_Opp, Key_Account_Contact, Testtwoconditions |
| `0Afdx00000GAijJCAT` | 116 Account_Cluster_Team records + `Account_Cluster_Team__mdt.Sales_Channel__c` field |
| `0Afdx00000GAiL7CAL` | 9 test classes (AccountCascadeHandlerTest, ClusterRuleEngineTest, ClusterTriggerTest, ContactTriggerHandlerTest, LeadConversionHandlerTest, LeadConversionHandlerTest1, ShopifyAddressSyncTest, ShopifyOrderSyncTest, ShopifySalesSyncServiceTest) |
| `0Afdx00000GAizRCAT` | ShopifyAssociationRetryBatch: removed the `NOT IN ('Key Accounts')` filter |
| `0Afdx00000GAi4zCAD` | FlexiPage visibility filters → Key Account |

Production package: `06_Deployment/Packages/KeyAccount_Rename_PROD` (+ `_ROLLBACK`).

## 2026-10-06/07 · Sector new values
Backup: `04_Change_Records/Metadata_Before_Snapshots/2026-10-06_KeyAccount_Sector`

| Deploy ID | Components |
|---|---|
| `0Afdx00000GAl4TCAT` | 8 new cluster rules: Specialty_Self_Service_Account/Lead/Opp/Contact (Cluster 6), Specialty_Planned_Account/Lead/Opp/Contact (Cluster 5) |
| `0Afdx00000GAp02CAD` | Planned added to the page filters |

Production package: `06_Deployment/Packages/Sector_NewValues_PROD` (+ `_ROLLBACK`, which includes `destructiveChangesPost.xml`).

## 2026-10-08 · Specialty CAN → Specialty (phase 1, metadata only)
Backup: `04_Change_Records/Metadata_Before_Snapshots/2026-10-08_SpecialtyCAN`

| Deploy ID | Components |
|---|---|
| `0Afdx00000GDSZyCAP` | Flow `Lead_From_US_Retailer_Form_Assignment_And_Email`: the Canada path now sets Specialty (v4, active) |
| `0Afdx00000GDXEfCAP` | LeadConversionHandlerTest1, ShopifyAssociationSyncSchedulableTest |
| `0Afdx00000GDXrNCAX` | Reports Shopify_Accounts_CANSource_Cluster_3 / Shopify_Accounts_Created_CAN_Cluster_3: filter logic `(3 OR (5 AND 6))` using Billing Country = CA |

Production package: `06_Deployment/Packages/SpecialtyCAN_Phase1_PROD` (+ `_ROLLBACK`).

## 2026-10-09 · V1 backup fields and strict page filters
Backup: `04_Change_Records/Metadata_Before_Snapshots/2026-10-09_V1_Fields_PageFilters`

| Deploy ID | Components |
|---|---|
| `0Afdx00000GEjosCAD` | Account `Sales_Channel_V1__c`, `Sector_V1__c` (Text 50) + Admin field-level security |
| `0Afdx00000GEoOjCAL` | V1 fields on the Store Location and Franchise pages (Details section, after Sector) |
| `0Afdx00000GEotNCAT` | Company page: strict new-mapping filters (Sellgoodr section = Specialty AND Self Service, Bridge section = Specialty AND Planned) + V1 fields |
| `0Afdx00000GEp9VCAT` | Lead page: strict filters; Convert = Sales Channel ≠ Specialty AND Status = Qualified |

## 2026-10-09 · Cluster fix (recalculate when only Sector changes)
Backup: `04_Change_Records/Metadata_Before_Snapshots/2026-10-09_ClusterFix`

| Deploy ID | Components |
|---|---|
| `0Afdx00000GEpsfCAD` | ClusterRuleEngine (re-evaluates when Sales Channel **or** Sector changes), AccountCascadeHandler and LeadConversionHandler (sync Sector to open Opportunities), ClusterRuleEngineTest, AccountCascadeHandlerTest |

Verification: `06_Deployment/Post_Deployment_Verification/` (32 cluster/team checks, 0 mismatches).

## Data (sandbox)
Load files are prepared in `04_Change_Records/Data_Changes/DataMigration_Account_Sandbox/` (V1 backfill 3 → pilot 7 → full 161 → rollback). **They have not been loaded.** No record data was changed.
