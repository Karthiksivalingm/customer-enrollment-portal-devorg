# Git Rules

## 1. Repository and branch

| Item | Value |
|---|---|
| Remote | `origin` = `https://github.com/sfdcut/SFDC.git` (never changed from this project) |
| Branch | `main`, the existing branch the user authorized for the Arizona setup push on 2026-10-15 (it is the only branch on `origin`) |
| Branch protection | Respected. If protection rejects a push, report the actual error and propose a feature branch + pull request; never bypass it. |

Each person uses their own GitHub account and credentials (Git Credential Manager). Never use someone else's credentials.

## 2. Commit procedure (manual; no automatic hooks are installed for Arizona)

1. Make sure no retrieval or other file-writing operation is still running.
2. Inspect: `git status --short`, `git branch --show-current`, `git remote -v`, `git diff -- Arizona/`.
3. Stop if anything **outside** `Arizona/` is already staged (`git diff --cached --name-only`).
4. Run `node scripts/secret-scan.js`. Fix or exclude every finding (see [Arizona-Working-Instructions.md](Arizona-Working-Instructions.md) §5).
5. Rebuild generated documents: `node scripts/build-inventory.js`.
6. Stage **explicit Arizona paths only**, for example `git add -- Arizona/01-Instructions Arizona/force-app`.
   Never `git add .`, `git add -A`, `git add -u` or `git commit -a`.
7. Check the staged names and diff: `git diff --cached --name-only` must list only `Arizona/...` paths; no `.sf/`, `.sfdx/`,
   `.arizona-state/`, auth files or credentials.
8. Commit with a descriptive message: `feat(arizona): ...`, `docs(arizona): ...`, `fix(arizona): ...`.
9. Push without force: `git push origin main`. Verify with `git status -sb` and `git ls-remote origin main`.
10. Report the commit ID, branch, file scope, and anything left uncommitted or failed.

## 3. Never

- Force-push, delete remote branches, rewrite shared history (`rebase`, `reset --hard`, `commit --amend` on pushed commits) or bypass protection.
- Stage or commit files outside `Arizona/`, or the repository-root `.sf/` folder.
- Discard, reset or overwrite other people's changes.
- Push when the secret scan fails, authentication fails or the branch is ambiguous.
- Deploy Salesforce metadata as part of a commit or push.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Rules created with the Arizona setup. Manual procedure; branch `main` as authorized for the setup push. |
