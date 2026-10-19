# EverQuote Project — Document Index

Every project document, by folder and serial number. **Last updated:** 2026-10-19 (aligned with the MLB folder structure).

## Naming convention
`<PREFIX>-<3-digit serial>_<Short-Title-With-Hyphens>.md`, for example `REQ-001_Lead-Assignment-Change.md`.

| Folder | Prefix | What goes in it | Next free number |
|---|---|---|---|
| `01-Instructions` | — | Instructions for how work is done. **Read-only; never edited by the assistant.** | — |
| `02-Knowledge-Base` | `KB-` | Background: overview, process, integrations, environment, users | KB-001 |
| `03-Requirements` | `REQ-` | One per requirement: need, scope, behaviour, acceptance criteria | REQ-001 |
| `04-Change-Records` | `CR-` | One per change made to an org: what, when, deploy ID, verification, rollback | CR-001 |
| `05-Conflicts` | `CON-` | Problems, clashes with existing automation or standards, open risks | CON-001 |
| `06-Deployment` | `DEP-` | Deployment documents; the folder is created only when something is actually deployed | DEP-001 |
| `07-Technical` | `TECH-` | Technical design and component detail | TECH-001 |
| `08-QA/01-Automated-Testing` | `ATR-` | Backend test run of every scenario | ATR-001 |
| `08-QA/02-Manual-Testing` | `MTC-` | Manual test case document with steps, screenshots and expected results | MTC-001 |

**Rules:**
- Numbers are never reused. A cancelled item keeps its number and is marked as such.
- An existing document is **updated** when its topic changes; a new number is used for a new topic.
- Every document links to its related REQ, CR, TECH, CON and DEP documents.

## 01 — Instructions (read-only)
| File | Purpose |
|---|---|
| [AI-Workflow.md](01-Instructions/AI-Workflow.md) | Workflows A, B and C; required document structures |
| [Coding-Standards.md](01-Instructions/Coding-Standards.md) | Rules every change must meet |
| [Project-Rules.md](01-Instructions/Project-Rules.md) | Environments, folders, document control, QA, test data, approvals, version control, reporting |
