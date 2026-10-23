# QA Process

How every confirmed requirement is tested and how the test evidence is stored. It applies to people and AI tools alike, on any Salesforce project.

The rules for when this runs are in [Project-Rules.md](Project-Rules.md) (section 6). The test-class rules for code are in [Coding-Standards.md](Coding-Standards.md) (section 5). QA engineers should also read "For QA engineers" in [AI-Workflow.md](AI-Workflow.md).

---

## 1. When QA runs
1. The requirement is built and deployed to the sandbox.
2. The project lead confirms it works ("all good").
3. Every scenario is run in the backend and recorded as an **automated test report (ATR)**.
4. A **manual test case document (MTC)** is written for the QA tester.
5. Both are listed in the month's `MONTH-INDEX.md` and in `DOCUMENT-INDEX.md`, and committed with the other documents.

## 2. Where the files go
| Folder | Prefix | File | Contents |
|---|---|---|---|
| `YYYY-MM/08-QA/01-Automated-Testing` | `ATR-` | `ATR-###_<Requirement>.md` | The backend test run, with evidence. A test class written only for the run can be kept beside it as `ATR-###_<ClassName>.cls`. |
| `YYYY-MM/08-QA/02-Manual-Testing` | `MTC-` | `MTC-###_<Requirement>.md` | Test cases for the manual tester |
| `YYYY-MM/08-QA/02-Manual-Testing` | — | `MTC-###_screenshots/` | Screenshots used in the MTC, named by test ID, for example `TC-014-03_record_blocked.png` |

- Use the next free number from `DOCUMENT-INDEX.md` and never reuse a number.
- One ATR and one MTC can cover several requirements confirmed together. List them all in the header.
- `YYYY-MM` is the month the QA document is first created (see Project-Rules section 2).
- When a requirement changes after its QA was written, update its ATR and MTC where they are (add a retest section) instead of starting new ones, and note the retest in the current month's `MONTH-INDEX.md`.

## 3. Test IDs
- Format: `TC-<requirement number>-<scenario number>`, for example `TC-014-03` is scenario 3 of REQ-014.
- The same ID is used in the ATR and the MTC, so a manual result can always be traced to the automated one.

## 4. Running the tests
| Kind | How |
|---|---|
| Rules, automation, bulk and permission cases | An Apex test class with real assertions, run as a **validate-only deployment** (`sf project deploy validate … -l RunSpecifiedTests`), so nothing is saved in the org. Cover positive, negative, bulk (200 records) and no-access or other-profile cases. |
| Screens, buttons and end-to-end saves | Drive the real screens in the sandbox and check each save with a query. |
| Configuration and access | Query or retrieve the metadata (record types, profiles, permission sets, picklist values) and compare with what is expected. |

Before any test that saves data:
1. Take a snapshot of every record the test will change.
2. Run the test and check the result.
3. Restore the snapshot and compare field by field. The target is **0 differences**.
4. Delete every temporary record and temporary component, and confirm they are gone.

Never send real emails, agreements or external calls during tests unless the project lead has approved it. Stop before a final Save or Send unless that step is what is being tested.

## 5. Automated test report (ATR)
Sections, in this order:
1. **Header**: report ID, requirements, link to the MTC, org, run date, who it ran as, overall result (for example "16 of 16 scenarios passed").
2. **Scope**: components under test with their versions.
3. **How the tests were run**.
4. **Scenario results** table:

| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|

5. **Defects found**: ID (`DEF-###`), where found, description, fix, retest. Write "None" if there were none.
6. **Evidence**: deploy and validate IDs, test results and coverage, record IDs used.
7. **Test data and cleanup**: every record created or changed and what happened to it.

## 6. Manual test cases (MTC)
Written for a QA tester who has not seen the build. Use the client's terms and the labels shown on screen.

Sections, in this order:
1. **Header**: document ID, requirements, link to the ATR with its result, environment, how to use the document.
2. **What is being tested**: a few plain sentences.
3. **Before you start**: logins, profiles and records the tester needs.
4. **Test case summary** table:

| Test ID | Scenario | Expected result | Actual result | Status |
|---|---|---|---|---|

5. **Test cases**, one per scenario, each as a table:

| | |
|---|---|
| **Preconditions** | Login, profile, record and data needed before starting |
| **Front-end steps** | Numbered clicks and entries |
| **Backend check** | Field, record or related list to confirm afterwards |
| **Test data** | Values to enter |
| **Expected result** | The verified outcome from the automated run |
| **Actual result** | Left blank for the tester |
| **Status** | Pass / Fail, left for the tester |

   followed by any screenshots for that test case.
6. **Sign-off**: tester name, date, number passed, overall result, comments, signature.

Rules:
- The **expected result** is always the outcome the automated run actually produced, not what was hoped for.
- Backend-only scenarios (for example 200-record bulk) are still listed, with "Covered by the automated test" and an optional manual method.
- Keep personal data out of screenshots: use test records, and crop or blur real customer details.
