# CR-029 — ShopifyOrderSyncTest: test no longer depends on the "Key Account" picklist value

| | |
|---|---|
| **Change ID** | CR-029 |
| **Date** | 2026-10-22 |
| **Requirement** | [REQ-035](../03-Requirements/REQ-035_Auto-Offboarding-Exclusion.md) (release of the at-risk / offboarding process) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GRMb7CAH` (run specified tests: ShopifyOrderSyncTest, 23 / 23) |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## Why
When the release was validated against the target org, `ShopifyOrderSyncTest.testMissingConfig` failed:
*"INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST, Sales Channel: bad value for restricted picklist field: Key Account"*.

The value "Key Accounts" was renamed to "Key Account" in the sandbox only ([CR-006](CR-006_Key-Accounts-To-Key-Account-Rename-In-The.md)), and the test classes were updated to match ([CR-008](CR-008_Key-Account-References.md)). The target org still has the old value. See [CON-036](../05-Conflicts/CON-036_Sandbox-Only-Key-Account-Rename-Breaks-Test-Deploys.md).

## What changed
| Component | Type | Change |
|---|---|---|
| `ShopifyOrderSyncTest` | Apex test | `testMissingConfig` no longer sets `Sales_Channel__c` on its test store. The order sync resolves the Shopify config by **country**, so the channel played no part in the test. No other test and no production class changed |

## Verification
`0Afdx00000GRMb7CAH`: 23 / 23 tests pass in the sandbox.

## Rollback
Redeploy the previous `ShopifyOrderSyncTest` from git history.
