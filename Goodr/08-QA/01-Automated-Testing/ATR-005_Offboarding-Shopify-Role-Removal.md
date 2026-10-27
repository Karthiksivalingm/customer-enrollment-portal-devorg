# ATR-005 — Automatic offboarding removes the Shopify ordering role

| | |
|---|---|
| **ATR ID** | ATR-005 |
| **Requirement** | [REQ-040](../../03-Requirements/REQ-040_Offboarding-Removes-Shopify-Ordering-Role.md) |
| **Change record** | [CR-035](../../04-Change-Records/CR-035_Offboarding-Batch-Removes-Shopify-Ordering-Role.md) |
| **Org** | GDRSAND (sandbox); Shopify **test** store for US locations |
| **Date** | 2026-10-27 |
| **Tester** | Assistant |
| **Overall result** | ✅ **Pass**: 10 of 10 scenarios. No change to existing processes. |

## 1. Scope
- **New:** `ShopifyOffboardRolePushQueueable` and the call to it from `ShopifyAtRiskNoticeBatch.finish()`.
- **Regression:** every existing Shopify integration class, the Account triggers, lead conversion, the Sales Sync, the order sync, R12 and the cluster logic.

**Safety:**
- Only a **US** store was used. US stores use the sandbox "Specialty" setting, which points to the Shopify test store. The "Specialty CAN" setting does not point to a test store ([CON-039](../../05-Conflicts/CON-039_Sandbox-Canada-Shopify-Setting-Is-Not-A-Test-Store.md)).
- The Shopify Sales Sync was **not** scheduled in the sandbox. Its code was run for the single test store only.

## 2. Scenario results
| Test ID | Scenario | Type | Run as | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-040-01 | Lead conversion creates a real Shopify store with an ordering role | Setup / regression | Admin + existing integration | Qualified US lead, `excltest.e2e@example.com` | Company, location and contact created in Shopify; store active; role assigned | Location `179823706423`, contact `6616351031`, role `3640590647`; store active | Pass |
| TC-040-02 | Baseline: the Sales Sync keeps an active store active | Regression | Admin (Sales Sync code, 1 store) | Store with its role | Active stays true | true | Pass |
| TC-040-03 | Problem: Salesforce-only deactivation (Shopify push skipped, as in a batch) | Negative | Admin | Active = false with the push bypassed | The role stays in Shopify | The stored role was still there | Pass (problem shown) |
| TC-040-04 | Problem: the Sales Sync then reactivates the store | Negative | Admin (Sales Sync code) | As TC-040-03 | Active flips back to true | false → **true** | Pass (problem confirmed) |
| TC-040-05 | Fix: the daily batch deactivates at 18 months | Positive | Batch `707dx000020QhhZAAS` | Last order 18 m + 1 d; Email 3 and 4 sent | Inactive, reason "Store At Risk", Email 5, notices Offboarded | As expected; 0 errors | Pass |
| TC-040-06 | Fix: role removal job runs after the batch | Positive | Queueable | Batch from TC-040-05 | `ShopifyOffboardRolePushQueueable` completes; role removed; stored role ID cleared | Completed; role ID cleared; no API errors | Pass |
| TC-040-07 | Fix: the Sales Sync then leaves the store inactive | Positive | Admin (Sales Sync code) | After TC-040-06 | Active stays false | **false** | Pass |
| TC-040-08 | Unit tests (mocked Shopify): revoke; reactivated store; 5 per job; empty list; batch queues; nothing queued; excluded store | Positive / negative / bulk | Apex tests | `ShopifyOffboardRolePushQueueableTest` | All pass | 7 / 7 | Pass |
| TC-040-09 | Existing tests for offboarding, the Shopify push and the Account trigger | Regression | Deploy `0Afdx00000GVMxWCAX` | Specified tests | All pass | 89 / 89 | Pass |
| TC-040-10 | All related test classes (32: offboarding, triggers, every Shopify sync and integration class, R12, order sync, cluster) | Regression | Test run `707dx000020R1Tq` | — | All pass | 390 / 390 | Pass |

**Active history of the test store:**

| Time (GMT) | Change | Caused by |
|---|---|---|
| 12:25:28 | false → true | Lead conversion |
| 12:27:15 | true → false | TC-040-03 |
| 12:27:27 | false → true | Sales Sync, TC-040-04 |
| 12:28:09 | true → false | Batch with the fix, TC-040-05 |
| after | stays false | Sales Sync, TC-040-07 |

## 3. Evidence
- **Deploys:** `0Afdx00000GVPtlCAH` (dry run) and `0Afdx00000GVMxWCAX`.
- **Coverage:** `ShopifyOffboardRolePushQueueable` 93.3%, `ShopifyAtRiskNoticeBatch` 94.2%.
- **API log:** one entry, "Company contact has already been assigned a role in that company location", from lead conversion (TC-040-01). This is existing behaviour: the association job assigns the role before the activation push does.

## 4. Test data
| Data | Where |
|---|---|
| Lead `00Qdx00000Ki4yrEAB` | Sandbox |
| Company `001dx00000tI5yAAAS` | Sandbox |
| Store `001dx00000tI5yBAAS` ("R12 WOT E2E Offboard Co 100 Test Harbor Rd 78701") | Sandbox |
| Contact `excltest.e2e@example.com` | Sandbox |
| 3 notices | Sandbox |
| Company, location and customer | Shopify **test** store |

The test data is kept until the project lead confirms it can be removed.

## 5. Defects found
None in the new code. The problem fixed by this change is recorded in [CON-035](../../05-Conflicts/CON-035_Offboarding-Behaviour-Vs-Client-Answers.md) (gaps 5 and 6).
