# TVM Salesforce: instructions for Claude

This folder is the complete, self-contained TVM project inside the shared `sfdcut/SFDC` repository.
Work only inside `TVM/`. Never change, stage or commit any other project folder or repository-root file.

**Start Claude Code from the `TVM/` folder.** That loads this file, the instruction files imported below, and the hooks in
`.claude/settings.json`: org guard, context reminders, and auto-commit/push.

## Key points
- The only Salesforce org is alias **`Fullsandbox`**: Team Velocity Marketing, Org ID `00DVa000006Eh6TMAS`, a sandbox.
  Run every `sf` command as `python scripts/sf_safe.py <args>`. It verifies the org and refuses org changes without `--approved <ID>`.
- Never deploy, change records, activate Flows or delete anything without the user's explicit approval of that exact operation and target.
  Production is never touched from this repository. A Git push is never a deployment.
- The real Salesforce source lives in `force-app/main/default/`. Documentation supplements it and never replaces it.
- **Every task updates its documentation in the same turn.** Use the routing table in Documentation-Rules.md:
  - REQ in `03-Requirements/` for every task received: `python scripts/new_doc.py REQ "<title>"`.
  - CR, CF and DEP records where they apply.
  - Metadata changes: `07-Technical-Documents/` plus a dated row in `07-Technical-Documents/Change-History.md`.
  - `02-Knowledge-Base/` when behaviour or architecture changes.
- When a turn ends, the Stop hook runs `scripts/autocommit.py`. It regenerates inventories and the index, runs the secret and
  documentation checks, commits **only TVM paths** and pushes to **`tvm/develop`**. If it blocks, fix what it reports.
  Write a one-line commit subject to `.tvm-state/commit-message.txt` before finishing.
- Never invent requirement IDs, approvals, record values, dates or test results. Write **TO BE CONFIRMED** instead.
- Never print, copy or commit credential values. Hardcoded credentials found in org source are handled by
  [config/secret-files.json](config/secret-files.json).
- Project background: [02-Knowledge-Base/Project-Overview.md](02-Knowledge-Base/Project-Overview.md). Every document: [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

## Standing instructions (imported)
@01-Instructions/TVM-Working-Instructions.md
@01-Instructions/Salesforce-Safety-Rules.md
@01-Instructions/Documentation-Rules.md
@01-Instructions/Git-Automation-Rules.md
