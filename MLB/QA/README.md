# QA

Test evidence for every requirement, created after the requirement is confirmed working ("all good").

| Folder | What goes in it | File naming | Next free number |
|---|---|---|---|
| [01-Automated-Testing](01-Automated-Testing/) | Backend test runs: every scenario executed against the sandbox (Apex tests, API saves, data checks), with inputs, expected result, actual result and evidence | `ATR-###_<Requirement>.md` (Automated Test Report) | ATR-001 |
| [02-Manual-Testing](02-Manual-Testing/) | Test case documents for the manual QA tester: front-end steps with screenshots, backend checks and the expected result for each scenario | `MTC-###_<Requirement>.docx` (Manual Test Cases) | MTC-001 |

## How the two link up
- Each test scenario has one ID, for example `TC-014-03` (requirement REQ-014, scenario 3). The same ID is used in the automated report and in the manual test case document.
- The **Expected Result** in the manual test cases is the result the automated run actually produced, so the manual tester can compare against a verified outcome.
- Every report links back to its requirement (`REQ-###`) and change record (`CR-###`).

## When it is done
1. The requirement is built and deployed to the sandbox.
2. The user confirms it works ("all good").
3. All scenarios are run in the backend and recorded in `01-Automated-Testing` (ATR).
4. The manual test case document is created in `02-Manual-Testing` (MTC), with screenshots, steps and expected results.
5. Both are listed in `DOCUMENT-INDEX.md` and committed to GitHub.
