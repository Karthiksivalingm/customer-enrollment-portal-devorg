# ATR-005 — Automatic offboarding removes the Shopify ordering role

| | |
|---|---|
| **ATR ID** | ATR-005 |
| **Requirement** | [REQ-040](../../03-Requirements/REQ-040_Offboarding-Removes-Shopify-Ordering-Role.md) |
| **Change record** | [CR-035](../../04-Change-Records/CR-035_Offboarding-Batch-Removes-Shopify-Ordering-Role.md) |
| **Org** | GDRSAND (sandbox); Shopify **test** store for US locations |
| **Date** | 2026-10-27 |
| **Tester** | Assistant |
| **Overall result** | ✅ **Pass**: 13 of 13 scenarios on the final version. No change to existing processes. |

## 1. Scope
- **New:** `ShopifyOffboardRolePushBatch` and the call to it from `ShopifyAtRiskNoticeBatch.finish()`.
- **Regression:** every existing Shopify integration class, the Account triggers, lead conversion, the Sales Sync, the order sync, R12 and the cluster logic.

**Safety:**
- Only a **US** store was used. US stores use the "Specialty" setting, which points to the Shopify test store ([CON-039](../../05-Conflicts/CON-039_Sandbox-Canada-Shopify-Setting-Is-Not-A-Test-Store.md)).
- The Shopify Sales Sync was **not** scheduled in the sandbox. Its code was run for the single test store only.

## 2. Scenario results
| Test ID | Scenario | Type | Run as | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-040-01 | Lead conversion creates a real Shopify store with an ordering role | Setup / regression | Admin + existing integration | Qualified US lead, `excltest.e2e@example.com` | Company, location and contact in Shopify; store active; role assigned | Location `179823706423`, contact `6616351031`, role assigned; active | Pass |
| TC-040-02 | Baseline: the Sales Sync keeps an active store active | Regression | Admin (Sales Sync code, 1 store) | Store with its role | Active stays true | true | Pass |
| TC-040-03 | Problem: Salesforce-only deactivation (push skipped, as in a batch) | Negative | Admin | Active = false, push bypassed | The role stays in Shopify | Role still stored | Pass (problem shown) |
| TC-040-04 | Problem: the Sales Sync then reactivates the store | Negative | Admin (Sales Sync code) | As TC-040-03 | Active flips back to true | false → **true** | Pass (problem confirmed) |
| TC-040-05 | Existing manual reactivation still assigns a role | Regression | Admin | Active = true (normal save) | Trigger push assigns a new role | Role `3640787255`, later `3640885559` | Pass |
| TC-040-06 | Rejected design: queue the next job before the Shopify calls | Negative (design) | Queueable | Two stores | — | Failed: "You have uncommitted work pending" → design changed to a batch | Recorded |
| TC-040-07 | Role-removal batch, real store, one store per chunk | Positive | Batch | E2E store inactive with live role + N18 (dummy IDs) | 2 chunks; real role removed; N18 harmless | 2/2 chunks, 0 errors; role cleared | Pass |
| TC-040-08 | Sales Sync after TC-040-07 | Positive | Admin (Sales Sync code) | — | Stays inactive | **false** | Pass |
| TC-040-09 | Role-removal batch skips a store that is active again | Negative | Batch | E2E store active | Not selected; role kept | 1/1 chunks (N18 only); role kept | Pass |
| TC-040-10 | **Full daily flow:** notice batch at 18 months → deactivates → starts role removal → Sales Sync | Positive / end to end | Notice batch | Last order 18 m + 1 d; Email 3 and 4 sent | Inactive, "Store At Risk"; role-removal batch started by itself; role gone; Sales Sync keeps it inactive | All as expected; 0 errors; Active stays **false** | Pass |
| TC-040-11 | Unit tests (mocked Shopify): revoke; active store; only inactive selected / one per chunk; empty set; notice batch starts it; nothing started; excluded store | Positive / negative | Apex tests | `ShopifyOffboardRolePushBatchTest` | All pass | 7 / 7 | Pass |
| TC-040-12 | Existing tests for offboarding, the Shopify push and the Account trigger | Regression | Deploy `0Afdx00000GVUAHCA5` | Specified tests | All pass | 89 / 89 | Pass |
| TC-040-13 | All related test classes (32: offboarding, triggers, every Shopify sync and integration class, R12, order sync, cluster) | Regression | Test run `707dx000020RH4B` | — | All pass | 390 / 390 | Pass |

## 3. Evidence
- **Final deploy:** `0Afdx00000GVUAHCA5` (dry run `0Afdx00000GVU2DCAX`).
- **Coverage:** `ShopifyOffboardRolePushBatch` 100%, `ShopifyAtRiskNoticeBatch` 94.2%.
- **API logs:** no role-removal errors. One entry, "already assigned a role in that company location", comes from lead conversion (existing behaviour).
- **Callout sizing:** in the data where the process will run, a store has at most 11 contacts of its own. 664 stores have none, so the push uses their Company's contacts; the largest Company has 33. The worst case is about 66 calls for one store, under the limit of 100 per chunk.

## 4. Test data
| Data | Where |
|---|---|
| Lead `00Qdx00000Ki4yrEAB` | Sandbox |
| Company `001dx00000tI5yAAAS` | Sandbox |
| Store `001dx00000tI5yBAAS` (inactive) | Sandbox |
| Contact `excltest.e2e@example.com` | Sandbox |
| 3 notices | Sandbox |
| Company, location and customer | Shopify **test** store |

The test data is kept until the project lead confirms it can be removed.

## 5. Defects found
- None in the final code.
- The queueable design was replaced after TC-040-06 (see [CR-035](../../04-Change-Records/CR-035_Offboarding-Batch-Removes-Shopify-Ordering-Role.md), "Design history").
