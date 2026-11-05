# Epicare Salesforce: instructions for Claude

This folder is the Epicare project inside the shared `sfdcut/SFDC` repository. Work only inside `Epicare/`. Never change, stage or commit
any other project folder or repository-root file. Start Claude Code from the `Epicare/` folder so this file and `.claude/settings.json` load.

## Project facts
- **Org:** alias `UTDEV` (Epicare Insurance sandbox, Org ID `00DWB000008ALkv2AG`) is the only org.
  - `PROD` is production and is **never** used.
  - Run every `sf` command as `python scripts/sf_safe.py <args>`. It verifies the org and refuses org changes without `--approved <ID>`.
- **Monthly folders:** `01-Instructions` and `02-Knowledge-Base` are common at the root. All other documents live in `YYYY-MM/`
  (Project-Rules section 2):
  - `python scripts/new_doc.py REQ|CR|CON|DEP|TECH|ATR|MTC "<title>"` files a document in the current month. The current month's folder (03 to 08 and
    `MONTH-INDEX.md`) is created automatically at the start of each month by the session hook and by `build_index.py`.
  - `python scripts/build_index.py` rebuilds `DOCUMENT-INDEX.md` and the month document lists.
  - After the project lead approves ("all good"), update the month's `MONTH-INDEX.md` (Summary and Requirement history), then rebuild
    the workbook: `& scripts\tracker\Build-MonthTracker.ps1 -Month YYYY-MM -ProjectRoot <full path of Epicare>`.
- **Living documents** (component change history, generated metadata inventory, retrieval reports, deployment procedures) stay in
  `2026-10/` and are updated in place. They are listed in `DOCUMENT-INDEX.md`.
- **Credentials:** the NIPR credential sits in custom labels, so the labels file is kept out of Git (CON-002,
  [config/secret-files.json](config/secret-files.json)). Never print, copy or commit credential values.
- **Git:** standing instruction from the user: every Epicare change is committed and pushed to `main` without asking. The end-of-turn hook runs
  `scripts/autocommit.py`, which makes a Epicare-only commit (explicit paths, secret scan) and a normal push.
- **Start here:** [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md) (requirement lookup) and [02-Knowledge-Base/Project-Overview.md](02-Knowledge-Base/Project-Overview.md).

## Standing instructions (imported)
@01-Instructions/Project-Rules.md
@01-Instructions/AI-Workflow.md
@01-Instructions/Coding-Standards.md
@01-Instructions/QA-Process.md
