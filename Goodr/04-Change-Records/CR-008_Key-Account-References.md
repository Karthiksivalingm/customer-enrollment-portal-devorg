# CR-008 — Key Account references

| | |
|---|---|
| **Change ID** | CR-008 |
| **Date** | 2026-10-06 (6 Oct) |
| **Requirement** | [REQ-003](../03-Requirements/REQ-003_Rename-Key-Accounts-To-Key-Account.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GAgZSCA1`, `0Afdx00000GAi4zCAD`, `0Afdx00000GAiL7CAL`, `0Afdx00000GAijJCAT`, `0Afdx00000GAizRCAT` |
| **By** | Assistant |
| **Status** | Done |

## What changed
| Time | Deploy (dry run) | Components | Result |
|---|---|---|---|
| 12:19 | `0Afdx00000GAgZSCA1` (`GAhnFCAT`) | Cluster rules Keys_Account_Account, Key_Account_Contact, Key_Account_Lead, Key_Account_Opp, Testtwoconditions → `Sales_Channel__c = 'Key Account'` | 5/5 |
| 12:22 | `0Afdx00000GAi4zCAD` (`GAgKwCAL`) | Pages Account_Company_Record_Page, Lead_Record_Page: Key Account section filter | 2/2 |
| 12:28 | `0Afdx00000GAiL7CAL` (`GAi8DCAT`; the test dry run `GAiBRCA1` showed 2 failures that already existed in ShopifyOrderSyncTest) | 9 test classes: 'Key Accounts' → 'Key Account' (24 lines) | 9/9 |
| 12:34 | `0Afdx00000GAijJCAT` (`GAfwkCAD`) | 116 `Account_Cluster_Team` records + `Account_Cluster_Team__mdt.Sales_Channel__c` (value added) | 117/117 |
| 12:38 | `0Afdx00000GAizRCAT` (`GAio9CAD`) | `ShopifyAssociationRetryBatch`: removed `AND Sales_Channel__c NOT IN ('Key Accounts')` (all channels now sync, matching the trigger handlers). Sandbox-only class | 1/1 |

Before versions: git history of `force-app/` ([CR-025](CR-025_Align-With-House-Standard-And-Remove-Production-Details.md)).

## Rollback
Redeploy the previous versions of these files from git history.
