# 08 — QA

Test evidence for every requirement, created after the requirement is confirmed working.

| Folder | What goes in it | File naming | Next free number |
|---|---|---|---|
| [01-Automated-Testing](01-Automated-Testing/) | Backend test runs against the sandbox (Apex tests, API saves, data checks) with inputs, expected and actual results, and evidence | `ATR-###_<Requirement>.md` | ATR-001 |
| [02-Manual-Testing](02-Manual-Testing/) | Manual test case documents: front-end steps, screenshots and expected results | `MTC-###_<Requirement>.docx` | MTC-001 |

Each scenario has one ID (for example `TC-001-01`) used in both the automated report and the manual test cases. Every report links back to its REQ and CR.
