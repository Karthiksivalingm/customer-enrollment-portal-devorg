# EverquoteFullSandbox — Salesforce (full-copy sandbox)

> Part of the shared **sfdcut/SFDC** repository (one folder per client project: `FD/`, `Goodr/`, `MLB/`, `TVM/`, `EverquoteFullSandbox/`).
> `force-app/` mirrors the Everquote **full-copy sandbox** (alias `EverquotefullSandbox`), retrieved on 2026-10-15 at API 68.0.

Every document by number: **[DOCUMENT-INDEX.md](DOCUMENT-INDEX.md)**. Project background: [02-Knowledge-Base/Project-Overview.md](02-Knowledge-Base/Project-Overview.md).

## Folders

| # | Folder | What's in it |
|---|---|---|
| 01 | [01-Instructions](01-Instructions/) | Shared `AI-Workflow.md` and `Coding-Standards.md` (read-only), and the EverquoteFullSandbox `Project-Rules.md` |
| 02 | [02-Knowledge-Base](02-Knowledge-Base/) | KB-001 Project Overview · KB-002 Glossary |
| 03 | [03-Requirements](03-Requirements/) | One REQ document per request |
| 04 | [04-Change-Records](04-Change-Records/) | One CR document per change, with before and after values and rollback |
| 05 | [05-Conflicts](05-Conflicts/) | One CON document per conflict or open risk, plus the merge conflict guide |
| 06 | [06-Deployment](06-Deployment/) | DEP documents, pre- and post-deployment checklists, `sf` commands |
| 07 | [07-Technical](07-Technical/) | TECH documents: Apex by area, ODA/Odie integration, triggers, flows, workflows, fields, integrations, security, queues |
| n/a | `force-app/`, `manifest/`, `config/`, `sfdx-project.json` | Salesforce DX project. Run `sf` commands from this `EverquoteFullSandbox/` folder. |
| n/a | `CLAUDE.md` · `.vscode/` · `.husky/` | Claude rules · VS Code settings · pre-commit hook |

`force-app/` contains the org's own metadata only. Managed-package components, reports and dashboards are excluded, and only 2 profiles are kept.

## Quick commands (from `EverquoteFullSandbox/`)
```bash
sf project retrieve start -m ApexClass:LeadHandler -o EverquotefullSandbox --api-version 68.0
sf project deploy start --source-dir force-app/main/default/classes/LeadHandler.cls -o EverquotefullSandbox --dry-run --test-level RunSpecifiedTests --tests LeadHandlerTest
```
More commands are in [06-Deployment/Deployment-Commands.md](06-Deployment/Deployment-Commands.md).

## Security
The org's metadata contains hardcoded credentials and keys. They're tracked in [CON-001](05-Conflicts/CON-001_Hardcoded-Credentials-And-Secrets.md), with the remediation plan. Don't add new secrets. The `Reference-Files/` folders and `*.xlsx`, `*.docx` files are local only.
