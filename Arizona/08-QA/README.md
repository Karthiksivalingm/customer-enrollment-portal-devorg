# 08 — QA (Arizona)

Test evidence for every confirmed Arizona requirement, following [QA-Process.md](../01-Instructions/QA-Process.md).
QA runs after a requirement is built in the Arizona sandbox and the project lead confirms it works ("all good").

| Folder | Prefix | Contents | Next free number |
|---|---|---|---|
| [01-Automated-Testing](01-Automated-Testing/) | `ATR-` | Automated test reports: `ATR-###_<Requirement>.md`, plus any test class written only for the run (`ATR-###_<ClassName>.cls`) | ATR-001 |
| [02-Manual-Testing](02-Manual-Testing/) | `MTC-` | Manual test case documents: `MTC-###_<Requirement>.md`, with screenshots in `MTC-###_screenshots/` | MTC-001 |

## How the two link up
- Each scenario has one test ID, `TC-<requirement number>-<scenario number>` (for example `TC-001-03`), used in both the ATR and the MTC.
- The **expected result** in the MTC is the result the automated run actually produced.
- Every report links back to its requirement (`REQ-###`) and change record (`CR-###`).

## Arizona notes
- Run tests only in the Arizona sandbox (alias `Arizona`, Org ID `00DWH000005wW9V2AU`). Never in production.
- Don't trigger real outbound actions while testing without the project lead's approval: PandaDoc documents, SMS (360 SMS), form emails,
  and the daily certification reminder emails all reach real people.
- Portal scenarios (Provider/Member Portal) need a portal test user; record which one in the MTC "Before you start" section.

## Arizona QA documents
| ID | Document | Requirement | Result |
|---|---|---|---|
| — | No QA records yet. | — | — |
