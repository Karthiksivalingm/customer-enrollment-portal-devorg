# REQ-040 — Automatic offboarding also removes the Shopify ordering role

| | |
|---|---|
| **ID** | REQ-040 |
| **Status** | ✅ Built and tested in the sandbox 2026-10-27 ([ATR-005](../08-QA/01-Automated-Testing/ATR-005_Offboarding-Shopify-Role-Removal.md)). Ready to release with the at-risk / offboarding process |
| **Requested** | 2026-10-27 (project lead: automatic offboarding at 18 months must work, with no change to existing processes or the integration) |
| **Related** | [CR-035](../04-Change-Records/CR-035_Offboarding-Batch-Removes-Shopify-Ordering-Role.md) · [REQ-035](REQ-035_Auto-Offboarding-Exclusion.md) · [CON-035](../05-Conflicts/CON-035_Offboarding-Behaviour-Vs-Client-Answers.md) · [CON-039](../05-Conflicts/CON-039_Sandbox-Canada-Shopify-Setting-Is-Not-A-Test-Store.md) · [KB-002](../02-Knowledge-Base/Business-Process.md) |

## Business need
The client confirmed that stores are deactivated **automatically** at 18 months without an order. A deactivated store must also stop being able to order in Shopify, and must stay inactive.

## Problem found
- **Today's behaviour:** when Active is unticked by a person, the Account trigger removes the contact's "Ordering Only" role in Shopify. That push is skipped when the change is made inside a batch job (`!System.isBatch()` in `AccountTriggerHandler`).
- **Effect on the daily notice batch:** the batch deactivates stores in a batch job, so the role stayed in Shopify.
- **Why it matters:** the Shopify Sales Sync runs every 12 hours and sets Active from those roles. It would therefore set the store active again within 12 hours.
- **Evidence:** reproduced in the sandbox on 2026-10-27 with a real store in the Shopify test store ([ATR-005](../08-QA/01-Automated-Testing/ATR-005_Offboarding-Shopify-Role-Removal.md), TC-040-04).

## Behaviour
After the daily batch deactivates stores at 18 months, it starts a small new batch, **one store per transaction**. For each store, that batch calls the **existing** Shopify status push, the same one a manual deactivation uses, which removes the store's ordering role. The Sales Sync then finds no role, and the store stays inactive. A store that fails doesn't stop the others.

## Scope
- **In:** `ShopifyAtRiskNoticeBatch` (part of the not-yet-live offboarding process), the new `ShopifyOffboardRolePushBatch`, and tests.
- **Out (unchanged):** `ShopifyActiveStatusPushService`, `ShopifyActiveStatusSyncQueueable`, `AccountTriggerHandler` / `AccountTriggerHelper`, the Shopify Sales Sync, lead conversion, manual offboarding, flows and the order sync.

## Acceptance criteria
1. A store deactivated by the daily batch loses its Shopify ordering role.
2. After that, the Shopify Sales Sync leaves the store inactive.
3. Nothing is pushed when no store is deactivated, for excluded stores, or for a store reactivated before the job runs.
4. Existing tests for the integration, triggers and offboarding still pass.

## Open questions
None.
