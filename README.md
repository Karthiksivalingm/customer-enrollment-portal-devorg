# Goodr — Salesforce (sandbox GDRSAND)

> Part of the shared **sfdcut/SFDC** repository (one folder per client project: `FD/`, `MLB/`, `Goodr/`).
> `force-app/` mirrors the Goodr **sandbox** (`GDRSAND`), and all record data in this folder is **sandbox data**.
> The packages in `06-Deployment/Packages/` are prepared for production (`GDRPROD`) and haven't been deployed there yet.

**New developer? Start with [01-Instructions/Developer-Onboarding.md](01-Instructions/Developer-Onboarding.md).**
Every document by number: **[DOCUMENT-INDEX.md](DOCUMENT-INDEX.md)**.

## Folders

| # | Folder | What's in it |
|---|---|---|
| 01 | [01-Instructions](01-Instructions/) | Shared `AI-Workflow.md` and `Coding-Standards.md` (read-only), Goodr `Project-Rules.md`, `Developer-Onboarding.md` |
| 02 | [02-Knowledge-Base](02-Knowledge-Base/) | KB-001 Project Overview · KB-002 Shopify At-Risk process · KB-003 Integrations · KB-004 Environment and tooling |
| 03 | [03-Requirements](03-Requirements/) | One REQ document per request: need, scope, acceptance criteria, status |
| 04 | [04-Change-Records](04-Change-Records/) | One CR document per change, with date, deploy ID, verification and rollback. Also before-snapshots, data files, the orgs' own change history and the session logs |
| 05 | [05-Conflicts](05-Conflicts/) | One CON document per conflict faced or open risk |
| 06 | [06-Deployment](06-Deployment/) | DEP documents, production packages with rollbacks, checklists, QA packs, verification evidence |
| 07 | [07-Technical](07-Technical/) | TECH documents: cluster engine, inventories of classes / triggers / flows / fields / UI, secure configuration, impact analysis |
| n/a | `force-app/`, `manifest/`, `config/`, `sfdx-project.json` | Salesforce DX project (run `sf` commands from this `Goodr/` folder) |
| n/a | [scripts/](scripts/README.md) | Verification Apex, document generators (index, inventories, org history), secret-blocking git hook |
| n/a | `CLAUDE.md` · `CONTRIBUTING.md` · `.vscode/` · `.github/` | Claude rules · how to contribute · VS Code settings · PR and issue templates (kept for reference; GitHub only reads `.github/` at the repo root) |

## Current status
- **Sales Channel / Sector transition:**
  - **Sandbox metadata:** done.
  - **Sandbox data:** the V1 backfill is done, and the Account update is applied (159 of 161).
  - **Production:** packages are ready and validated but not deployed. See [DEP-001](06-Deployment/DEP-001_Sales-Channel-Sector-Production-Deployment.md). Note: "Key Accounts" was already renamed to "Key Account" in production by hand on 2026-10-06 ([CR-007](04-Change-Records/CR-007_Key-Accounts-To-Key-Account-Rename-In-PRODUCTION.md)).
- **Shopify At-Risk / Warm-Off offboarding:** built in the sandbox and waiting on client decisions. See [KB-002](02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding.md) and [DEP-002](06-Deployment/DEP-002_Shopify-At-Risk-Offboarding-Production-Deployment.md).
- **Open items:** the ⚠ entries in [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

## Quick commands (from `Goodr/`)
```bash
sf project retrieve start -x manifest/retrieve/pkg_full_sync_20261013.xml -o GDRSAND --api-version 68.0 --ignore-conflicts
sf project deploy start --source-dir force-app/main/default/classes/ClusterRuleEngine.cls -o GDRSAND --dry-run --test-level RunSpecifiedTests --tests ClusterRuleEngineTest
powershell -ExecutionPolicy Bypass -File scripts/doc-builders/build_document_index.ps1      # after adding a REQ/CR/CON/DEP/TECH document
```

## Security
Credentials are never committed. NetSuite credential records are excluded by `.gitignore` and `.forceignore`, with placeholder templates in
[TECH-007](07-Technical/TECH-007_Secure-Configuration.md). The secret-blocking hook is enabled with `git config core.hooksPath Goodr/scripts/git-hooks`.
