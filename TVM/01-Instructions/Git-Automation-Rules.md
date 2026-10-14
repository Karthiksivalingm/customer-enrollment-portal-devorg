# Git Automation Rules

## 1. Repository and branch

| Item | Value |
|---|---|
| Remote | `origin` = `https://github.com/sfdcut/SFDC.git` (never changed by automation) |
| Authorized TVM branch | `tvm/develop` |
| Protected branches | `main`, `master`: automation never commits or pushes to them |
| Merging to `main` | Only through a reviewed pull request opened by a person. Branch protection and required reviews are respected. |

Each person uses their own GitHub account and credentials (Git Credential Manager). Never use someone else's credentials.

## 2. What happens automatically

When Claude finishes a turn, the Claude Code **Stop hook** runs `python scripts/autocommit.py --hook`. You can run the same thing
yourself: `python scripts/autocommit.py [-m "subject"]`, or `--check` to validate without committing.

Steps, in order. Any failure stops the run before anything is staged:

1. Take a lock (`.tvm-state/autocommit.lock`) so runs never overlap or recurse.
2. Check the remote URL, the current branch (`tvm/develop`), no detached HEAD, and no merge, rebase or cherry-pick in progress.
3. Stop if any file **outside** `TVM/` is already staged.
4. Collect changed, new and deleted paths **under `TVM/` only** (`git status -- TVM/`). Ignored files are never included.
5. Regenerate `07-Technical-Documents/Metadata-Inventory/` (when source changed) and `DOCUMENT-INDEX.md`.
6. Validate: secret scan; JSON and XML well-formedness; dated-record names and front matter; every changed Salesforce
   component named in a new row of `07-Technical-Documents/Change-History.md`.
7. Stage the exact paths by name (`git add --pathspec-from-file`). Never `git add .`, `-A` or `-u`.
8. Re-check that every staged path is inside `TVM/`. If not, unstage everything and stop.
9. Commit. Subject from `-m`, else from `.tvm-state/commit-message.txt` (deleted after use), else generated.
10. Push `tvm/develop` to `origin` (no force). Report the commit hash and branch.

**Idempotent:** with no TVM changes nothing happens. Generators write only when content changes. If an earlier push failed, the next
run pushes the waiting commit.

**In hook mode:** a documentation or secret failure returns exit code 2 once, so Claude fixes the problem and finishes again. If it
fails a second time, the changes stay uncommitted and the reason is shown to the user. Environment problems (wrong branch, files
staged outside TVM) are reported and never worked around.

## 3. Blocked commands

The `PreToolUse` hook (`scripts/hooks/guard.py`) blocks Claude from running: force or delete pushes; pushes to `main`/`master`;
`git add .`, `-A`, `-u`; `git commit -a`; remote changes; `git reset --hard`; `git clean -f`; discarding changes with
`checkout`/`restore .`; rebase and history rewriting; `core.hooksPath` or remote config; switching to `main`; and direct `sf` commands.

## 4. Never

- Push to `main`, force-push, rewrite shared history or bypass branch protection.
- Stage or commit files outside `TVM/`, or the untracked repository-root `.sf/` folder.
- Discard, reset or overwrite user changes.
- Push when validation fails, a secret is detected, authentication fails or the branch is ambiguous.
- Deploy Salesforce metadata as part of a commit or push.

## 5. Limits (what the automation does not do)

- Claude Code hooks fire only in Claude Code sessions **started from `TVM/`**. Edits made in other editors are committed the next time
  the Stop hook runs or when someone runs `scripts/autocommit.py`.
- The hooks do not see changes made directly in the Salesforce UI or by integrations. Those need a Salesforce-side audit mechanism
  (Setup Audit Trail, Field History Tracking or Change Data Capture), which is not set up yet. See
  [Known-Constraints.md](../02-Knowledge-Base/Known-Constraints.md).
- No repository-wide Git hook is installed. Enabling one (`core.hooksPath`) affects every project and needs approval.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Automation designed and documented with the TVM setup. Branch `tvm/develop` chosen by the user. |
| 2026-10-14 | One-off exception: the user explicitly authorized pushing the initial TVM content directly to `main` (manual, TVM-only commit, normal push). Automatic pushes still go to `tvm/develop` only. |
