# CR-011 — Specialty CAN → Specialty

| | |
|---|---|
| **Change ID** | CR-011 |
| **Date** | 2026-10-08 (8 Oct) |
| **Requirement** | [REQ-007](../03-Requirements/REQ-007_Specialty-CAN-To-Specialty-In-Metadata.md) [REQ-008](../03-Requirements/REQ-008_Verify-Old-And-New-Mappings.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GDSZyCAP`, `0Afdx00000GDXEfCAP`, `0Afdx00000GDXrNCAX` |
| **By** | Assistant |
| **Status** | Done |

## What changed
| Time | Deploy (dry run) | Components |
|---|---|---|
| 11:10 | `0Afdx00000GDSZyCAP` (`GDWorCAH`) | Flow `Lead_From_US_Retailer_Form_Assignment_And_Email`: the Canada path now sets Specialty (v4 active, v3 obsolete) |
| 11:15 | `0Afdx00000GDXEfCAP` (`GDX1lCAH`, 13/13 tests) | LeadConversionHandlerTest1, ShopifyAssociationSyncSchedulableTest |
| 11:28 | `0Afdx00000GDXrNCAX` (`GDXWPCA5`) | Reports Cluster3/Shopify_Accounts_CANSource_Cluster_3, Shopify_Accounts_Created_CAN_Cluster_3: logic `1 AND 2 AND 4 AND (3 OR (5 AND 6))` (Specialty + country CA) |

Verification on 11:33 – 11:58: anonymous Apex inserted test records and then rolled them back, so no data persisted. Full test run: 676 tests, 87% coverage. 

## Rollback
Reactivate flow version 3; redeploy the 2 test classes and 2 reports from git history.
