# Git Automation Rules

## 1. Repository and branch

| Item | Value |
|---|---|
| Remote | `origin` = `https://github.com/sfdcut/SFDC.git` (never changed by automation) |
| Epicare branch | `main` (user decision 2026-10-15) |
| Project path | `Epicare/` only. Other project folders (`TVM/`, `FD/`, `Goodr/`, `MLB/`, `EverquoteFullSandbox/` …) are never staged |
| Branch protection | Respected. Never force-push, never bypass required reviews or checks |

Each person uses their own GitHub account and credentials (Git Credential Manager). Never use someone else's credentials.

## 2. What runs automatically, and what runs on request

| When | What | Changes Git? |
|---|---|---|
| End of every Claude turn (Stop hook) | `python scripts/autocommit.py --hook --check`: regenerates the inventories and the index, then runs every validation below. If documentation or a secret check fails, Claude is sent back once to fix it | **No.** Nothing is staged, committed or pushed |
| On request ("commit and push Epicare") | `python scripts/autocommit.py -m "<subject>"`: validation, then an Epicare-only commit and a normal push to `main` | Yes |
| Without pushing | `python scripts/autocommit.py --no-push -m "<subject>"` | Commit only |

Commits are not automatic because `main` is a shared branch for several projects. Every push to it must be requested.

## 3. Checks before anything is staged
1. Take a lock (`.project-state/autocommit.lock`) so runs never overlap or recurse.
2. Check the remote URL, the current branch (`main`), no detached HEAD, and no merge, rebase or cherry-pick in progress.
3. Stop if any file **outside** `Epicare/` is already staged.
4. Collect changed, new and deleted paths **under `Epicare/` only**. Ignored files are never included.
5. Regenerate `07-Technical-Documents/Metadata-Inventory/` (when source changed) and `DOCUMENT-INDEX.md`.
6. Validate:
   - Secret scan.
   - JSON and XML well-formedness.
   - Dated-record names and front matter.
   - Every changed Salesforce component named in a new row of `07-Technical-Documents/Change-History.md`.
7. Stage the exact paths by name (`git add --pathspec-from-file`). Never `git add .`, `-A` or `-u`.
8. Re-check that every staged path is inside `Epicare/`. If not, unstage everything and stop.
9. Commit, then push to `origin main` (no force). Report the commit hash.

Never commit or push while a retrieval or another file-writing task is still running.

## 4. Blocked commands
The `PreToolUse` hook (`scripts/hooks/guard.py`) blocks Claude from running:

- Force, mirror or delete pushes, and pushes to other protected branches.
- `git add .`, `-A`, `-u`, and `git commit -a`.
- Remote changes.
- `git reset --hard`, `git clean -f`, and discarding changes.
- Rebase and history rewriting.
- `core.hooksPath` changes.
- Direct `sf` commands. Use `scripts/sf_safe.py` instead.

## 5. Limits
- Hooks fire only in Claude Code sessions **started from `Epicare/`**.
- Changes made directly in Salesforce are not detected. That needs an approved Salesforce-side mechanism, for example Setup Audit
  Trail, Field History Tracking or Change Data Capture.
- No repository-wide Git hook is installed. Enabling one affects every project and needs approval.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Rules created with the Epicare setup. Branch `main` chosen by the user. Stop hook set to validate only. |
