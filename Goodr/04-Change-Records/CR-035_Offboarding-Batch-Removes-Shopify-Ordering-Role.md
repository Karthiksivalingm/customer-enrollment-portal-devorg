# CR-035 — Offboarding batch removes the Shopify ordering role of the stores it deactivates

| | |
|---|---|
| **Change ID** | CR-035 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-040](../03-Requirements/REQ-040_Offboarding-Removes-Shopify-Ordering-Role.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GVMxWCAX` (validated by `0Afdx00000GVPtlCAH`; 89 / 89 specified tests) |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `ShopifyAtRiskNoticeBatch` | Apex class (offboarding process) | **15 lines added, none removed.** The batch remembers the stores it deactivated (`offboardedIds`). In `finish()`, if there are any, it enqueues `ShopifyOffboardRolePushQueueable` once. In tests this only happens when `pushRolesInTests` is set, the same pattern as the existing legacy-run guard. |
| `ShopifyOffboardRolePushQueueable` | **New** Apex class | Takes the deactivated store IDs and, **5 stores per job** (well under the 100-callout limit), calls the existing `ShopifyActiveStatusPushService.syncActiveStatusToShopify`. It chains the rest. It skips stores that are active again. |
| `ShopifyOffboardRolePushQueueableTest` | **New** test class | 7 tests with a mocked Shopify: role revoked and stored ID cleared; reactivated store untouched; one job takes 5 stores; empty list; batch deactivation queues the job; no deactivation means nothing queued; excluded store never pushed |

**Not changed:**
- `ShopifyActiveStatusPushService`
- `ShopifyActiveStatusSyncQueueable`
- `AccountTriggerHandler` and `AccountTriggerHelper`
- the Shopify Sales Sync classes and job
- lead conversion, manual offboarding, flows and the order sync
- `ShopifyAtRiskNoticeBatchTest`

## Verification
See [ATR-005](../08-QA/01-Automated-Testing/ATR-005_Offboarding-Shopify-Role-Removal.md):
- **End to end** with a real store created through lead conversion in the Shopify **test** store. The problem was reproduced, and the fix keeps the store inactive after the Sales Sync.
- **Related test classes:** 390 / 390 passed (32 classes).
- **Coverage:** `ShopifyOffboardRolePushQueueable` 93%, `ShopifyAtRiskNoticeBatch` 94%.

## Release
Add to the offboarding release:
- `ShopifyAtRiskNoticeBatch`
- `ShopifyOffboardRolePushQueueable`
- `ShopifyOffboardRolePushQueueableTest`
- `ShopifyAtRiskNoticeBatchTest`

Use run specified tests: `ShopifyOffboardRolePushQueueableTest`, `ShopifyAtRiskNoticeBatchTest`, `ShopifyActiveStatusPushServiceTest`, `AccountTriggerHelperTest`.

## Rollback
Redeploy the previous `ShopifyAtRiskNoticeBatch` from git history. The new class is then unused and can be deleted.
