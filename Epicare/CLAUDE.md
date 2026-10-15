# Epicare Salesforce: instructions for Claude

This folder is the self-contained Epicare project inside the shared `sfdcut/SFDC` repository.
Work only inside `Epicare/`. Never change, stage or commit any other project folder or repository-root file.

**Read and follow the standing instructions imported below before doing any Epicare work.** Start Claude Code from the `Epicare/`
folder so this file and the hooks in `.claude/settings.json` load. The hooks provide the org and Git guard, context reminders,
and the end-of-turn validation.

## Key points
- **The only Salesforce org is alias `UTDEV`:** Epicare Insurance sandbox, Org ID `00DWB000008ALkv2AG`.
  - `PROD` is production and is **never** used.
  - Run every `sf` command as `python scripts/sf_safe.py <args>`. It verifies the org and refuses org changes without `--approved <ID>`.
- **Approvals:** never deploy, change records, activate Flows or delete anything without the user's explicit approval of that exact operation and target.
  A Git push is never a deployment.
- **Before a task:** read [Project-Overview.md](02-Knowledge-Base/Project-Overview.md) and the relevant
  [Metadata-Inventory](07-Technical-Documents/Metadata-Inventory/README.md) pages. Retrieve the current version of each component before editing it.
- **Source:** the real Salesforce source lives in `force-app/main/default/`. Documentation supplements it and never replaces it.
- **Documentation, in the same turn as the work.** Routing is in Documentation-Rules.md:
  - Every task received → a REQ record (`python scripts/new_doc.py REQ "<title>"`).
  - Records changed → CR. Errors → CF. Deployments → DEP.
  - Metadata changes → `07-Technical-Documents/`, plus a dated row in `07-Technical-Documents/Change-History.md`.
  - Behaviour or architecture changes → `02-Knowledge-Base/`.
- **Git:** the Stop hook validates every turn but does not commit. When the user asks to publish, run
  `python scripts/autocommit.py -m "<subject>"`. That makes an Epicare-only commit and a normal push to `main`.
- **Never invent** requirement IDs, approvals, record values, dates or test results. Write **TO BE CONFIRMED** instead.
- **Credentials:** never print, copy or commit them.
- **Index:** every document is listed in [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

## Standing instructions (imported)
@01-Instructions/Epicare-Working-Instructions.md
@01-Instructions/Salesforce-Safety-Rules.md
@01-Instructions/Documentation-Rules.md
@01-Instructions/Git-Automation-Rules.md
