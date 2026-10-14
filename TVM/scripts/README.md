# TVM scripts

Run every script from the `TVM/` folder with Python 3.9+ (`python scripts/<name>.py`). Shared helpers are in `lib/tvmlib.py`.
All scripts read [`config/tvm-project.json`](../config/tvm-project.json).

| Script | Purpose | Touches the org? |
|---|---|---|
| `verify_org.py` | Confirms `Fullsandbox` is Org `00DVa000006Eh6TMAS` and a sandbox | Read-only |
| `sf_safe.py` | The only way to run `sf`: verifies the org, forces `--target-org Fullsandbox`, refuses org changes without `--approved <ID>` | As allowed |
| `build_manifest.py` | Rebuilds `manifest/package.xml` (unmanaged code + data model) from org metadata listings | Read-only |
| `build_inventory.py` | Regenerates `07-Technical-Documents/Metadata-Inventory/` from `force-app` | No (offline) |
| `build_index.py` | Regenerates `DOCUMENT-INDEX.md` | No |
| `new_doc.py` | Creates a dated REQ / CR / CF / DEP record with the next free ID, without duplicates | No |
| `secret_scan.py` | Blocks credentials and forbidden files (`--all` or file list) | No |
| `autocommit.py` | Validates, commits TVM-only paths and pushes to `tvm/develop` (`--check`, `--no-push`, `-m`, `--hook`) | No |
| `hooks/guard.py` | Claude Code PreToolUse hook: blocks unsafe Git and direct `sf` commands | No |
| `hooks/session_context.py` | Claude Code SessionStart / UserPromptSubmit hook: adds branch status and routing reminders | No |
| `tests/test_automation.py` | Self-tests for the automation in a throwaway Git repository | No |

Hooks are registered in [`../.claude/settings.json`](../.claude/settings.json) and load when Claude Code is started from `TVM/`.
