# CR-035 — Offboarding batch removes the Shopify ordering role of the stores it deactivates

| | |
|---|---|
| **Change ID** | CR-035 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-040](../03-Requirements/REQ-040_Offboarding-Removes-Shopify-Ordering-Role.md) |
| **Org** | GDRSAND |
| **Deploy ID** | Final: `0Afdx00000GVUAHCA5` (validated by `0Afdx00000GVU2DCAX`; 89 / 89 specified tests). Earlier versions of the same day: `0Afdx00000GVMxWCAX` and `0Afdx00000GVMCkCAP` (queueable, replaced; see "Design history") |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `ShopifyAtRiskNoticeBatch` | Apex class (offboarding process) | **15 lines added, none removed.** The batch remembers the stores it deactivated (`offboardedIds`). In `finish()`, if there are any, it starts `ShopifyOffboardRolePushBatch` with one store per chunk. In tests this only happens when `pushRolesInTests` is set, the same pattern as the existing legacy-run guard. |
| `ShopifyOffboardRolePushBatch` | **New** Apex batch (callouts allowed) | Selects the given stores that are inactive and have a Shopify ID. For each store, in its own transaction, it re-checks that the store is still inactive, then calls the existing `ShopifyActiveStatusPushService.syncActiveStatusToShopify`. |
| `ShopifyOffboardRolePushBatchTest` | **New** test class | 7 tests with a mocked Shopify: role revoked and stored ID cleared; active store untouched; only inactive stores selected, one per chunk; empty set; notice batch starts it after a deactivation; nothing started without a deactivation; excluded store never pushed |
| `ShopifyOffboardRolePushQueueable` + test | Apex classes | Created earlier the same day and **deleted** in deploy `0Afdx00000GVUAHCA5`. Never released. |

**Not changed:**
- `ShopifyActiveStatusPushService`
- `ShopifyActiveStatusSyncQueueable`
- `AccountTriggerHandler` and `AccountTriggerHelper`
- the Shopify Sales Sync classes and job
- lead conversion, manual offboarding, flows and the order sync
- `ShopifyAtRiskNoticeBatchTest`

## Design history (why a batch, one store per chunk)
1. **First version: a queueable, 5 stores per job, chaining the rest.**
   - The push makes about two Shopify calls per contact, and falls back to the Company's contacts when a store has none.
   - In the data where the process will run, the largest Company has 33 contacts, about 66 calls for one store. Five such stores would exceed the 100-callout limit and stop the job.
2. **Second version: one store per job, queueing the next job before the calls.**
   - Salesforce rejected this with *"You have uncommitted work pending. Please commit or rollback before calling out"*.
   - This was found in a real sandbox run; mocked tests cannot show it.
3. **Final version: a batch with one store per chunk.**
   - Each store runs in its own transaction with its own callout limit, worst case about 66 calls.
   - A failing store doesn't stop the others.
   - No chaining is needed.

## Verification
See [ATR-005](../08-QA/01-Automated-Testing/ATR-005_Offboarding-Shopify-Role-Removal.md): end to end with a real store in the Shopify **test** store, including the full daily flow, and 390 / 390 related tests. Coverage: `ShopifyOffboardRolePushBatch` 100%, `ShopifyAtRiskNoticeBatch` 94.2%.

## Release
Add to the offboarding release:
- `ShopifyAtRiskNoticeBatch`
- `ShopifyOffboardRolePushBatch`
- `ShopifyOffboardRolePushBatchTest`
- `ShopifyAtRiskNoticeBatchTest`

Use run specified tests: `ShopifyOffboardRolePushBatchTest`, `ShopifyAtRiskNoticeBatchTest`, `ShopifyActiveStatusPushServiceTest`, `AccountTriggerHelperTest`.

## Rollback
Redeploy the previous `ShopifyAtRiskNoticeBatch` from git history. The new batch is then unused and can be deleted.
