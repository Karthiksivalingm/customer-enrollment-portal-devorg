# MLB Project — Document Index

Master index. `01-Instructions` and `02-Knowledge-Base` are **common** and sit at the project root. All other documents are stored **by month**: each month folder has the same structure and its own `MONTH-INDEX.md` with the full history of that month. **Last updated:** 2026-10-23 (knowledge base moved to the root as a common folder).

## How to look something up
1. Read the instruction files in `01-Instructions` (always, for every requirement).
2. Look for the topic in the **Requirement lookup** table below (title and keywords).
3. If it exists, open only that month's `MONTH-INDEX.md` and the documents it links to. Don't search the other months or folders.
4. If it doesn't exist, it's a new requirement: use the next free numbers below and file it in the current month's folder.

## Months
| Month | Summary | History | Tracker (Excel) |
|---|---|---|---|
| 2026-10 | REQ-001 to REQ-018: Ticket Office email, vendor certificates, Agreement Flow create/edit and locks, Sales Vendor, Sales Manager access, QA (ATR-001/002, MTC-001/002) | [2026-10/MONTH-INDEX.md](2026-10/MONTH-INDEX.md) | [2026-10_Tracker.xlsx](2026-10/2026-10_Tracker.xlsx) |

## Requirement lookup
| REQ | Title | Keywords | Month | Status |
|---|---|---|---|---|
| REQ-001 | Ticket Office Comments field | ticket office comments, agreement flow | 2026-10 | ✅ Sandbox |
| REQ-002 | Ticket Office notification email | email alert, VF template, ticket office | 2026-10 | ✅ Sandbox |
| REQ-003 | Email triggering conditions | 50k, first send, approval, signed, declined | 2026-10 | ✅ Sandbox |
| REQ-004 | Email design and content | Marlins logo, layout, agreement summary | 2026-10 | ✅ Sandbox |
| REQ-005 | Signed email with PDF | signed PDF, attachment | 2026-10 | ✅ Sandbox |
| REQ-006 | Vendor certificate reminder and document status | banner, upload certificate, COI, W-9, food | 2026-10 | ✅ Sandbox |
| REQ-007 | Restrict to Vendor Contact | record type | 2026-10 | Superseded by REQ-016 |
| REQ-008 | Lock certificate fields to the flow | validation rule, read only | 2026-10 | ✅ Sandbox |
| REQ-009 | Demo feedback: files, status tracking, rules | agreement files, status, non-profit | 2026-10 | ✅ Sandbox |
| REQ-010 | Latest-agreement status and Send button | latest agreement, send agreement | 2026-10 | ✅ Sandbox |
| REQ-011 | Ticketing Engagement fields and Opportunity link | ticketing engagement, ProVenue | 2026-10 | ⏸ On hold |
| REQ-012 | Sales Managers role access | permission set, Marlins Sales app, sales reps | 2026-10 | ✅ Sandbox |
| REQ-013 | Suite Lease: MVP label and 40 games | suite location, total games | 2026-10 | ✅ Sandbox |
| REQ-014 | Agreement Flow: create and edit, locked agreement fields | edit agreement, prefill, membership rows, lock | 2026-10 | ✅ Sandbox |
| REQ-015 | Account Sales Vendor: Type value removed | account type, sales vendor | 2026-10 | ✅ Sandbox |
| REQ-016 | Contact Sales Vendor record type | sales vendor, certificate features | 2026-10 | ✅ Sandbox |
| REQ-017 | User Sales Manager checkbox | sales manager list | 2026-10 | ✅ Sandbox |
| REQ-018 | Certificate-only agreement attachments | send agreement, attachments, Adobe template | 2026-10 | ✅ Sandbox |

## Naming and numbering
`<PREFIX>-<3-digit serial>_<Short-Title-With-Hyphens>.md`. Serial numbers run across all months and are never reused.

| Folder | Prefix | What goes in it | Next free number |
|---|---|---|---|
| `02-Knowledge-Base` (root, common) | `KB-` | Background: overview, process, integrations, environment, users, guides | KB-007 |
| `YYYY-MM/03-Requirements` | `REQ-` | One per requirement | REQ-019 |
| `YYYY-MM/04-Change-Records` | `CR-` | One per change made to an org | CR-038 |
| `YYYY-MM/05-Conflicts` | `CON-` | Problems, clashes, open risks | CON-019 |
| `YYYY-MM/06-Deployment` | `DEP-` | Only when something is actually deployed to production | DEP-001 |
| `YYYY-MM/07-Technical` | `TECH-` | Technical design and component detail | TECH-011 |
| `YYYY-MM/08-QA/01-Automated-Testing` | `ATR-` | Automated test reports | ATR-003 |
| `YYYY-MM/08-QA/02-Manual-Testing` | `MTC-` | Manual test cases, with `MTC-###_screenshots/` | MTC-003 |

## 02 — Knowledge Base (common)
Background for the whole project, not tied to a month. Update these in place.

| ID | Document |
|---|---|
| KB-001 | [Project Overview](02-Knowledge-Base/Project-Overview.md) |
| KB-002 | [Business Process](02-Knowledge-Base/Business-Process.md) |
| KB-003 | [Integrations](02-Knowledge-Base/Integrations.md) |
| — | [Technical Architecture](02-Knowledge-Base/Technical-Architecture.md) |
| KB-004 | [Salesforce Environment and Tooling](02-Knowledge-Base/KB-004_Salesforce-Environment.md) |
| KB-005 | [Sandbox User Status](02-Knowledge-Base/KB-005_Sandbox-User-Status.md) |
| KB-006 | Agreement Testing Guide: [Word](02-Knowledge-Base/KB-006_Agreement-Testing-Guide.docx) · [HTML](02-Knowledge-Base/KB-006_Agreement-Testing-Guide.html) |

## Living documents in month folders
Updated in place in the month they were created. Open them directly; no need to search.

| Document | Location |
|---|---|
| TECH-005 Component Inventory | [2026-10/07-Technical/TECH-005_Component-Inventory.md](2026-10/07-Technical/TECH-005_Component-Inventory.md) |
| CON-012 Open data, user and tooling items | [2026-10/05-Conflicts/CON-012_Open-Data-And-Access-Items.md](2026-10/05-Conflicts/CON-012_Open-Data-And-Access-Items.md) |

## 01 — Instructions
| File | Purpose |
|---|---|
| [AI-Workflow.md](01-Instructions/AI-Workflow.md) | Workflows A, B and C; required document structures |
| [Coding-Standards.md](01-Instructions/Coding-Standards.md) | Rules every change must meet |
| [Project-Rules.md](01-Instructions/Project-Rules.md) | Environments, monthly folders, history lookup, document control, QA, test data, approvals, version control, reporting |
| [QA-Process.md](01-Instructions/QA-Process.md) | When QA runs, file locations, test IDs, how tests are run, ATR and MTC structure |
