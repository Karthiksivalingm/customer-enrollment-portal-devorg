# TVM Salesforce: instructions for Claude

This folder is the TVM project inside the shared `sfdcut/SFDC` repository. Work only inside `TVM/`. Never change, stage or commit any
other project folder or repository-root file. Start Claude Code from the `TVM/` folder so this file and `.claude/settings.json` load.

## Project facts
- **Org:** alias `Fullsandbox` (Team Velocity Marketing, Org ID `00DVa000006Eh6TMAS`, a sandbox) is the only org. Run every `sf` command as
  `python scripts/sf_safe.py <args>`. It verifies the org and refuses org changes without `--approved <ID>`.
- **Monthly folders:** `01-Instructions` and `02-Knowledge-Base` are common at the root. All other documents live in `YYYY-MM/`
  (Project-Rules section 2):
  - `python scripts/new_doc.py REQ|CR|CON|DEP|TECH|ATR|MTC "<title>"` files a document in the current month. It creates the month folder and
    `MONTH-INDEX.md` the first time.
  - `python scripts/build_index.py` rebuilds `DOCUMENT-INDEX.md` and the month document lists.
  - After the project lead approves ("all good"), update the month's `MONTH-INDEX.md` (Summary and Requirement history), then rebuild
    the workbook: `& scripts\tracker\Build-MonthTracker.ps1 -Month YYYY-MM -ProjectRoot <full path of TVM>`.
- **Living documents** (component change history, generated metadata inventory, retrieval reports, deployment procedures) stay in
  `2026-10/` and are updated in place. They are listed in `DOCUMENT-INDEX.md`.
- **Credentials:** org source files with hardcoded credentials are listed in [config/secret-files.json](config/secret-files.json) and kept
  out of Git (CON-002). Never print, copy or commit credential values.
- **End-of-turn hook:** `scripts/autocommit.py` validates (secrets, XML/JSON, document names, Change History). It commits and pushes only on the branch set in
  `config/tvm-project.json`, and stops on any other branch.
- **Start here:** [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md) (requirement lookup) and [02-Knowledge-Base/Project-Overview.md](02-Knowledge-Base/Project-Overview.md).

## Standing instructions (imported)
@01-Instructions/Project-Rules.md
@01-Instructions/AI-Workflow.md
@01-Instructions/Coding-Standards.md
@01-Instructions/QA-Process.md
