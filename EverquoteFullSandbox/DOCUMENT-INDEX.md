# EverquoteFullSandbox: Document Index

Every project document, by folder and serial number. **Last updated:** 2026-10-15 (moved into sfdcut/SFDC, CR-002).

## Naming convention
`<PREFIX>-<3-digit serial>_<Short-Title-With-Hyphens>.md`, for example `REQ-003_Lead-Round-Robin-Fix.md`.

| Folder | Prefix | What goes in it | Next free number |
|---|---|---|---|
| `01-Instructions` | — | How work is done. `AI-Workflow.md` and `Coding-Standards.md` are shared and **read-only**. | — |
| `02-Knowledge-Base` | `KB-` | Background: overview, glossary, process, environment | KB-003 |
| `03-Requirements` | `REQ-` | One per requirement: need, scope, acceptance criteria, status | REQ-003 |
| `04-Change-Records` | `CR-` | One per change: what, when, before and after, deploy Id, verification, rollback | CR-003 |
| `05-Conflicts` | `CON-` | Problems, clashes with existing automation, open risks | CON-009 |
| `06-Deployment` | `DEP-` | Deployment documents, created only when something is actually deployed | DEP-001 |
| `07-Technical` | `TECH-` | Technical design and component detail | TECH-022 |

**Rules:**
- Numbers are never reused. A cancelled item keeps its number and is marked as such.
- An existing document is **updated** when its topic changes; a new number is used for a new topic.
- Every document links to its related REQ, CR, TECH, CON and DEP documents.

## 01 — Instructions
| File | Purpose |
|---|---|
| [AI-Workflow.md](01-Instructions/AI-Workflow.md) | Shared: workflows A, B and C (read-only) |
| [Coding-Standards.md](01-Instructions/Coding-Standards.md) | Shared: rules every change must meet (read-only) |
| [Project-Rules.md](01-Instructions/Project-Rules.md) | EverquoteFullSandbox-specific rules |

## 02 — Knowledge Base
| ID | Document |
|---|---|
| KB-001 | [Project Overview](02-Knowledge-Base/Project-Overview.md) |
| KB-002 | [Glossary](02-Knowledge-Base/KB-002_Glossary.md) |

## 03 — Requirements
| ID | Requirement | Status |
|---|---|---|
| REQ-001 | [GitHub source control and documentation](03-Requirements/REQ-001_GitHub-Source-Control-And-Documentation.md) | ✅ Done |
| REQ-002 | [Move the project into sfdcut/SFDC](03-Requirements/REQ-002_Move-Project-Into-SFDC-Repository.md) | ✅ Done |

## 04 — Change Records
| ID | Date | Change |
|---|---|---|
| CR-001 | 2026-10-13 | [GitHub baseline and documentation](04-Change-Records/CR-001_GitHub-Baseline-And-Documentation.md) |
| CR-002 | 2026-10-15 | [Move to sfdcut/SFDC and full metadata retrieve](04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md) |

## 05 — Conflicts
| ID | Conflict / risk | Status |
|---|---|---|
| CON-001 | [Hardcoded credentials and secrets in metadata](05-Conflicts/CON-001_Hardcoded-Credentials-And-Secrets.md) | ⚠ Open 🔴 |
| CON-002 | [Several triggers on one object](05-Conflicts/CON-002_Multiple-Triggers-Per-Object.md) | ⚠ Open |
| CON-003 | [Same field written by several automations](05-Conflicts/CON-003_Same-Field-Written-By-Several-Automations.md) | ⚠ Open |
| CON-004 | [Old and new automation both active](05-Conflicts/CON-004_Old-And-New-Automation-Both-Active.md) | ⚠ Open |
| CON-005 | [Async jobs and governor limits](05-Conflicts/CON-005_Async-And-Governor-Limit-Risks.md) | ⚠ Open |
| CON-006 | [Environment and deployment dependencies](05-Conflicts/CON-006_Environment-And-Deployment-Dependencies.md) | ⚠ Open |
| CON-007 | [Code defects found in review](05-Conflicts/CON-007_Code-Defects-Found-In-Review.md) | ⚠ Re-verify |
| CON-008 | [Cleanup backlog and over-broad access](05-Conflicts/CON-008_Cleanup-Backlog-And-Over-Broad-Access.md) | ⚠ Open |
| — | [Merge conflict guide](05-Conflicts/Merge-Conflict-Guide.md) | Guide |

## 06 — Deployment
No DEP documents yet. Guides: [Pre-Deployment Checklist](06-Deployment/Pre-Deployment-Checklist.md) · [Post-Deployment Checklist](06-Deployment/Post-Deployment-Checklist.md) · [Deployment Commands](06-Deployment/Deployment-Commands.md)

## 07 — Technical
TECH-001 to TECH-021 describe the **2026-10-13 snapshot**. 27 classes, 2 flows and 5 workflow files changed in the org since then ([CR-002](04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md)).

| ID | Document |
|---|---|
| TECH-001 | [Apex class index](07-Technical/TECH-001_Apex-Class-Index.md) |
| TECH-002 | [Apex: Lead management](07-Technical/TECH-002_Apex-Lead-Management.md) |
| TECH-003 | [Apex: Lead assignment and round robin](07-Technical/TECH-003_Apex-Lead-Assignment-Round-Robin.md) |
| TECH-004 | [Apex: Opportunity](07-Technical/TECH-004_Apex-Opportunity.md) |
| TECH-005 | [Apex: Activities (Task and Event)](07-Technical/TECH-005_Apex-Activities-Task-Event.md) |
| TECH-006 | [Apex: Case and email](07-Technical/TECH-006_Apex-Case-and-Email.md) |
| TECH-007 | [Apex: Voice and CTI](07-Technical/TECH-007_Apex-Voice-and-CTI.md) |
| TECH-008 | [Apex: Cheat sheets](07-Technical/TECH-008_Apex-Cheatsheets.md) |
| TECH-009 | [ODA / Odie quoting integration](07-Technical/TECH-009_ODA-Quoting-Integration.md) |
| TECH-010 | [Apex: Batches and schedulers](07-Technical/TECH-010_Apex-Batches-and-Schedulers.md) |
| TECH-011 | [Apex: Communities and sites](07-Technical/TECH-011_Apex-Communities-and-Sites.md) |
| TECH-012 | [Apex: Unsubscribe](07-Technical/TECH-012_Apex-Unsubscribe.md) |
| TECH-013 | [Apex: Utilities and test framework](07-Technical/TECH-013_Apex-Utilities-and-Test-Framework.md) |
| TECH-014 | [Trigger inventory](07-Technical/TECH-014_Trigger-Inventory.md) |
| TECH-015 | [Flow inventory](07-Technical/TECH-015_Flow-Inventory.md) (covers the original 4 flows only) |
| TECH-016 | [Workflow rules](07-Technical/TECH-016_Workflow-Rules.md) |
| TECH-017 | [Process flow migrations](07-Technical/TECH-017_Process-Flow-Migrations.md) |
| TECH-018 | [Fields reference](07-Technical/TECH-018_Fields-Reference.md) (built from references; field definitions are now in `force-app/main/default/objects/`) |
| TECH-019 | [Integrations](07-Technical/TECH-019_Integrations.md) |
| TECH-020 | [Security and access](07-Technical/TECH-020_Security-and-Access.md) |
| TECH-021 | [Queues](07-Technical/TECH-021_Queues.md) |
