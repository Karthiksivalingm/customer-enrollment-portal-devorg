# Epicare scripts

Run every script from the `Epicare/` folder with Python 3.9+ (`python scripts/<name>.py`). Shared helpers are in `lib/projlib.py`.
All scripts read [`config/project.json`](../config/project.json).

| Script | Purpose | Touches the org? |
|---|---|---|
| `verify_org.py` | Confirms `UTDEV` is Org `00DWB000008ALkv2AG` and a sandbox | Read-only |
| `sf_safe.py` | The only way to run `sf`: verifies the org, forces `--target-org UTDEV`, refuses org changes without `--approved <ID>` | As allowed |
| `build_manifest.py` | Rebuilds `manifest/package.xml` (unmanaged code + data model) from org metadata listings | Read-only |
| `build_inventory.py` | Regenerates `2026-10/07-Technical/Metadata-Inventory/` from `force-app` | No (offline) |
| `build_index.py` | Regenerates `DOCUMENT-INDEX.md` | No |
| `new_doc.py` | Creates a dated REQ / CR / CF / DEP record with the next free ID, without duplicates | No |
| `secret_scan.py` | Blocks credentials and forbidden files (`--all` or file list) | No |
| `autocommit.py` | Validates, commits Epicare-only paths and pushes to ``main` (on request)` (`--check`, `--no-push`, `-m`, `--hook`) | No |
| `hooks/guard.py` | Claude Code PreToolUse hook: blocks unsafe Git and direct `sf` commands | No |
| `hooks/session_context.py` | Claude Code SessionStart / UserPromptSubmit hook: adds branch status and routing reminders | No |
| `tests/test_automation.py` | Self-tests for the automation in a throwaway Git repository | No |

Hooks are registered in [`../.claude/settings.json`](../.claude/settings.json) and load when Claude Code is started from `Epicare/`.

Additional: `retrieve.py` (batched retrieval with retries and overwrite protection) and `check_retrieval.py` (manifest vs returned
components → `2026-10/07-Technical/Retrieval/Retrieval-Report.md`). Shared helpers: `lib/projlib.py`; configuration: `config/project.json`.
