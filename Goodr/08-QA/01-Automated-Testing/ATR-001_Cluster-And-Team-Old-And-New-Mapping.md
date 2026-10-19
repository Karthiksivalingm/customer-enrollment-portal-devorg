# ATR-001 — Cluster and team assignment for old and new Sales Channel / Sector values

| | |
|---|---|
| **ATR ID** | ATR-001 |
| **Requirements** | [REQ-008](../../03-Requirements/REQ-008_Verify-Old-And-New-Mappings.md) · [REQ-012](../../03-Requirements/REQ-012_Cluster-Not-Updating-For-Sector-Only-Change.md) |
| **Change records** | [CR-009](../../04-Change-Records/CR-009_New-Sector-Values-In-Logic.md) · [CR-011](../../04-Change-Records/CR-011_Specialty-CAN-To-Specialty.md) · [CR-018](../../04-Change-Records/CR-018_Cluster-Fix.md) |
| **Org** | GDRSAND (sandbox) |
| **Date** | 2026-10-08 (old/new mapping) and 2026-10-09 (after the cluster fix) |
| **Tester** | Assistant |

## 1. Scope
`ClusterRuleEngine` (via the Account, Lead and Opportunity cluster triggers), `ClusterTeamEngine`, `AccountCascadeHandler`,
the `Sales_Channel_Cluster__mdt` rules and the `Account_Cluster_Team__mdt` team records.

## 2. Scenario results
Each scenario saved a record with the given Sales Channel / Sector and read back the cluster and the team members.

| Test ID | Scenario | Type | Run as | Input (Sales Channel / Sector) | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-012-01 | Key Account, old Sector | API save + data check | Admin | Key Account / Core, Mid-Market, Off-Price | Cluster 1 | Cluster 1 (Account, Lead, Opportunity) | Pass |
| TC-012-02 | Key Account, new Sector | API save + data check | Admin | Key Account / Enterprise, Strategic, Discount, Development | Cluster 1 | Cluster 1 (Account, Lead, Opportunity) | Pass |
| TC-012-03 | Specialty, old Sector | API save + data check | Admin | Specialty / Sellgoodr USA; Specialty / Bridge | Cluster 6; Cluster 5 | Cluster 6; Cluster 5 | Pass |
| TC-012-04 | Specialty, new Sector | API save + data check | Admin | Specialty / Self Service; Specialty / Planned | Cluster 6; Cluster 5 | Cluster 6; Cluster 5 | Pass |
| TC-012-05 | Specialty CAN (old) | API save + data check | Admin | Specialty CAN / Sellgoodr CAN; Specialty CAN / Bridge | Cluster 6; Cluster 5 | Cluster 6; Cluster 5 | Pass |
| TC-012-06 | Global, old and new | API save + data check | Admin | Global / Global; Global / Distributor | Cluster 7 | Cluster 7 | Pass |
| TC-012-07 | Partnerships | API save + data check | Admin | Partnerships / Partnerships | Cluster 8 | Cluster 8 | Pass |
| TC-012-08 | No matching rule | API save + data check | Admin | Specialty / blank; Specialty / Sellgoodr CAN | No cluster | No cluster | Pass (by design) |
| TC-012-09 | Sector-only change re-clusters | API save + data check | Admin | Specialty / Planned → Specialty / Self Service | Cluster 5 → 6 | Cluster 6 (after [CR-018](../../04-Change-Records/CR-018_Cluster-Fix.md)) | Pass |
| TC-012-10 | Account change cascades to open Opportunity | API save + data check | Admin | Account Key Account / Enterprise, Strategic | Opportunity gets the same Sales Channel / Sector and cluster | Copied | Pass |
| TC-012-11 | Team per cluster and object | API save + data check | Admin | One record per mapping on Account, Contact, Lead, Opportunity | Roles from `Account_Cluster_Team__mdt` | 32 checks, 0 mismatches | Pass |
| TC-012-12 | Typeform lead routing | API save + data check | Admin | Canada and US retailer form | Sales Channel Specialty; correct queue | Specialty; Lead Retailers Canada / US | Pass |

## 3. Evidence
- Deploys: `0Afdx00000GAl4TCAT` (new rules), `0Afdx00000GDSZyCAP` (flow), `0Afdx00000GEpsfCAD` (cluster fix; dry run `0Afdx00000GEpUTCA1`, 119/119 tests).
- Coverage after the fix: ClusterRuleEngine 93%, AccountCascadeHandler 100%, LeadConversionHandler 88%.
- The Global team has 4 members, because the Sales Director user is inactive and skipped by design ([CON-012](../../05-Conflicts/CON-012_Users-Planda-Goodr.md)).

## 4. Cleanup
All records were created in anonymous Apex that ended with a forced exception, so **nothing was saved**. Counts of records created that day were the same before and after (0).

## 5. Defects found
- Sector-only change didn't re-cluster, and an Account save with open Opportunities failed on the dependent Sector. Both fixed in [CR-018](../../04-Change-Records/CR-018_Cluster-Fix.md).
