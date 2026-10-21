# ATR-002 — Exclude an Account from the Automated Offboarding

| | |
|---|---|
| **ATR ID** | ATR-002 |
| **Requirement** | [REQ-035](../../03-Requirements/REQ-035_Auto-Offboarding-Exclusion.md) |
| **Change records** | [CR-026](../../04-Change-Records/CR-026_Auto-Offboarding-Exclusion-Fields-Access-And-Pages.md) · [CR-027](../../04-Change-Records/CR-027_Auto-Offboarding-Exclusion-Batch-And-Flow.md) |
| **Conflicts** | [CON-034](../../05-Conflicts/CON-034_Auto-Offboarding-Exclusion-Open-Decisions.md) |
| **Org** | GDRSAND (sandbox) |
| **Date** | 2026-10-21 |
| **Tester** | Assistant |
| **Overall result** | ✅ **Pass**: 30 of 30 scenarios. No defects found. No change to the existing process. |

## 1. Scope
- **New:** fields `Exclude_From_Auto_Offboarding__c` and `Auto_Offboarding_Exclusion_Reason__c`, the filter in `ShopifyAtRiskNoticeBatch`, and version 2 of the flow `Create_At_Risk_Task_for_Account_Owner`.
- **Regression:** every automation connected to the Store Location and offboarding:
  - flows: Set At Risk Dates, Send Shopify At Risk Notice (with `SendWarmOffEmail`), Account – Auto-Populate Offboarding Date and User
  - validation rule `Require_Offboarding_Reason_And_Notes`
  - `AccountTriggerHelper` (rollup and cascade)
  - the notice batch's clean-up step (Recovered / Offboarded)
  - the Shopify schedules
  - all related Apex tests

**How the tests ran:**
- **Batch:** run by hand twice (runs A and B), exactly as the daily schedule runs it. The sandbox filter `R12 WOT%` limits it to test stores.
- **Records:** saved through the API as an administrator.
- **Field access:** checked against the profiles. A UI check as a real Account Management user is part of the manual test cases.

## 2. Scenario results

### 2.1 Exclusion: positive and negative
| Test ID | Scenario | Type | Run as | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-035-01 | Excluded store reaches 18 months | Positive | Admin + batch | X18: ticked, last order 18 m + 1 d, Email 3 and 4 sent | Stays active, no Email 5, no reason set | Active, no Email 5 | Pass |
| TC-035-02 | Normal store reaches 18 months (control) | Negative / regression | Admin + batch | N18: same as X18, not ticked | Deactivated, reason "Store At Risk", Email 5 sent, old notices → Offboarded | As expected; Email 5 delivered to the test address | Pass |
| TC-035-03 | Excluded store at 12 months | Positive | Admin + batch | X12: ticked, 12 m + 3 d, at risk | No notice, no email | None | Pass |
| TC-035-04 | Normal store at 12 months (control) | Regression | Admin + batch | N12: not ticked | Email 1 notice, Notice Sent | Notice Sent, email sent | Pass |
| TC-035-05 | Store under an excluded Company | Positive | Admin + batch | B12 not ticked; Company B ticked | No notice | None | Pass |
| TC-035-06 | Excluded store's Company not excluded: other stores still processed | Regression | Admin + batch | Company A not ticked; N12 / N18 under it | Processed normally | Processed | Pass |
| TC-035-07 | Box ticked with no reason | Negative | Admin | U12 inserted ticked, reason blank | Saves with no error, store skipped | Saved, skipped in run A | Pass |
| TC-035-08 | Untick, store at 12 months: resumes | Positive | Admin + batch | U12 unticked before run B | Email 1 on the next run | Email 1 sent in run B | Pass |
| TC-035-09 | Untick, store past 18 months with Email 3 already sent | Behaviour check ([CON-034](../../05-Conflicts/CON-034_Auto-Offboarding-Exclusion-Open-Decisions.md)) | Admin + batch | X18 unticked before run B | Deactivated on the next run (current design) | Deactivated, reason "Store At Risk", Email 5 | Pass: works as designed; client decision pending |
| TC-035-10 | Excluded store orders again | Regression | Admin + batch | RC: ticked, earlier Email 1, new order today | Open notice → Recovered | Recovered, date 2026-10-21 | Pass |
| TC-035-11 | Existing notices on an excluded store are not changed | Positive | Admin + batch | X18 in run A | Notices stay Notice Sent | Unchanged | Pass |

### 2.2 At-risk task flow and the weekly R12 chain
| Test ID | Scenario | Type | Run as | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-035-12 | At-risk task: normal store | Regression | Admin | N12: At Risk Since set | Task "Shopify sales at risk — contact this store" | Created | Pass |
| TC-035-13 | At-risk task: excluded store | Positive | Admin | X12 | No task | None | Pass |
| TC-035-14 | At-risk task: store under an excluded Company | Positive | Admin | B12 | No task | None | Pass |
| TC-035-15 | At-risk task on a **Company** record (no parent) | Negative / edge | Admin | Company A flagged at risk | Task created, no flow error | Created, no error | Pass |
| TC-035-16 | Weekly R12 chain, normal store | Regression | Admin | C1: R12 run date and at-risk flag set | Before-save flow sets At Risk Since and episode 1; task created | As expected | Pass |
| TC-035-17 | Weekly R12 chain, excluded store | Positive | Admin | C2: same | At Risk Since and episode still set (reporting kept); **no task** | As expected | Pass |

### 2.3 Saving the box and manual offboarding
| Test ID | Scenario | Type | Run as | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-035-18 | Tick then untick | Positive | Admin | N12 | Both save; no background job; history recorded | Saved; 0 jobs; 2 history rows | Pass |
| TC-035-19 | Manual offboarding of an excluded store | Regression | Admin | X12: Active off, reason and notes | Saved; date and user stamped by the existing flow | Saved; 2026-10-21 and running user | Pass |
| TC-035-20 | Manual offboarding with no reason on an excluded store | Negative | Admin | X18: Active off, no reason | Blocked by the existing validation rule | Blocked: "Please provide both an Offboarding Reason and Offboarding Notes…" | Pass |

### 2.4 Bulk (200 records)
| Test ID | Scenario | Type | Run as | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-035-21 | Bulk insert with the box | Bulk | Admin | 200 stores in one save, 100 ticked | 200 saved, no errors | 200 / 200 | Pass |
| TC-035-22 | Bulk at-risk task flow | Bulk | Admin | 200 stores, At Risk Since set in one save | 100 tasks (normal), 0 (excluded) | 200 saved; 100 / 0 | Pass |
| TC-035-23 | Bulk tick and untick | Bulk | Admin | 100 unticked, then ticked again | No errors, no background jobs | 100 / 100 both ways; 0 jobs | Pass |
| TC-035-24 | Bulk batch at 18 months | Bulk | Batch | 200 stores, Email 3 sent, 100 ticked | 100 deactivated with reason; 100 stay active; Company stays active | Exactly that; notices 100 Offboarded / 100 Notice Sent | Pass |
| TC-035-25 | Excluded stores are not even selected | Bulk | Batch | Run A | Batch scope leaves out the 100 excluded stores | 3 chunks of 50 (ticked stores not queried) | Pass |

### 2.5 Regression of the existing process, permissions and code
| Test ID | Scenario | Type | Run as | Input | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-035-26 | Existing test stores (`R12 WOT…`, 13 accounts) | Regression | Batch | Snapshot before and after run A | No change | 0 notice rows and 0 account rows differ | Pass |
| TC-035-27 | Emails only from notices; no Shopify calls | Regression | — | All runs | Emails only to the test `@example.com` contacts; no API errors | 4 emails, all to test addresses; 0 `Api_Log__c` today | Pass |
| TC-035-28 | Field access for all users | Permission | — | `FieldPermissions` | Read and edit for the 21 profiles that can edit Active; none for guest-site profiles | 21 and 21 | Pass |
| TC-035-29 | Related Apex tests (31 classes: offboarding, Account triggers, Shopify sync, R12, order sync, cluster) | Code | — | Test run `707dx00001zMP7i` | All pass | 383 / 383 | Pass |
| TC-035-30 | Schedules and flow version | Regression | — | `CronTrigger`, `Flow` | 5 Shopify schedules waiting; task flow v2 active, v1 obsolete | As expected | Pass |

## 3. Evidence
- **Deploys:** `0Afdx00000GQ6wcCAD` (fields, pages) and `0Afdx00000GQ8WzCAL` (batch, flow, field access; 63 / 63 tests).
- **Batch runs:**
  - 2026-10-21 earlier run `707dx00001zLyNkAAK` (TC-01 to 06, 11)
  - run A `707dx00001zMKERAA4` (3 chunks, 0 errors)
  - run B `707dx00001zMLOxAAO` (0 errors)
- **Coverage (run `707dx00001zMP7i`):**

  | Class | Coverage |
  |---|---|
  | `ShopifyAtRiskNoticeBatch` | 94% |
  | `SendWarmOffEmail` | 88% |
  | `AccountTriggerHandler` | 98% |
  | `AccountTriggerHelper` | 86% |
  | `ShopifyR12SalesService` | 98% |
  | `ShopifyActiveStatusPushService` | 94% |

- **Full org run** `707dx00001zLx8e` (after the deploy): 690 tests, 681 passed. The 9 failures are older and not related to this change; the same 9 methods failed on 2026-10-08:
  - `CaseSLAOrchestrationTest` ×2
  - `DeleteAutomatedTasksBatchTest.testScheduler`
  - `LightningSelfRegisterControllerTest`
  - `NetSuiteOAuth2HelperES256Test` ×5
- **Emails sent** (`EmailMessage`, status Sent), all to test contacts:

  | To | Email |
  |---|---|
  | `excltest.n12@example.com` | Email 1 |
  | `excltest.u12@example.com` | Email 1 |
  | `excltest.n18@example.com` | Email 5 |
  | `excltest.x18@example.com` | Email 5 |

## 4. Test data
| Data | Count | Note |
|---|---|---|
| Companies `R12 WOT EXCLTEST Co A`, `Co B`, `R12 WOT EXCLBULK Co` | 3 | Dummy Shopify IDs, so no Shopify calls |
| Stores `R12 WOT EXCLTEST …` (X18, N18, X12, N12, B12, U12, RC, C1, C2) | 9 | |
| Stores `R12 WOT EXCLBULK N001–X200` | 200 | |
| Contacts `excltest.*@example.com` | 8 | Not approved and no Shopify ID, so no Shopify sync |
| Notices / tasks | 209 / 103 | |

- **Safety:** the Shopify push was switched off for the one manual-offboarding save (TC-035-19), because the stores have dummy Shopify IDs. Existing records were not changed.
- **Cleanup:**
  - **Bulk set deleted on 2026-10-21** at the project lead's request: `R12 WOT EXCLBULK Co`, its 200 stores, the contact `excltest.bulk@example.com`, 200 notices and 100 tasks. No background jobs started, and no API errors were logged. A query afterwards confirmed 0 records left.
  - **Small set kept** for the manual tester: `R12 WOT EXCLTEST Co A` / `Co B`, the 9 `R12 WOT EXCLTEST` stores, 7 contacts, and their notices and tasks. It is to be deleted when manual testing is finished. Deleting accounts only recalculates internal totals; it makes no Shopify call.

## 5. Defects found
None.

**Observations (not defects):**
- TC-035-09: unticking after 18 months deactivates on the next run. Client decision in [CON-034](../../05-Conflicts/CON-034_Auto-Offboarding-Exclusion-Open-Decisions.md).
- TC-035-11: notices already sent stay "Notice Sent" while a store is excluded. They could be shown as "Cancelled" if the client prefers.
- The 9 older failing org tests will block a production deploy that runs all tests. Use Run Specified Tests (`ShopifyAtRiskNoticeBatchTest`, `AccountTriggerHelperTest`).
