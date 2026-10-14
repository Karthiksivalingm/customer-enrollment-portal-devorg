# CR-022 — Credential hardening in the repository

| | |
|---|---|
| **Change ID** | CR-022 |
| **Date** | 2026-10-13 (13 Oct, Session A) |
| **Requirement** | [REQ-023](../03-Requirements/REQ-023_Record-Every-Org-Change-In-GitHub.md) |
| **Org** | Git (no org change) |
| **Deploy ID** | n/a |
| **By** | Session A |
| **Status** | Done |

## What changed
No org change. NetSuite credential custom metadata had been committed in the first two commits (old IDs `88fb123` and `246a9f2`). On 13 Oct:
- added placeholder templates (`07-Technical/Secure-Config-Templates/`, every value `SET_IN_ORG__<field>`) and checked that none of the real values appear in them;
- added the pre-commit hook `scripts/git-hooks/pre-commit`, which blocks credential files and secret-looking values (tested: it blocks the NetSuite file);
- added `.gitattributes` so the hook keeps LF line endings;
- **purged the history** (user approved): the 2 files were removed from every commit with `git filter-branch` and pushed with `--force-with-lease`. Every commit ID changed: `88fb123→c2b6b3e`, `246a9f2→d591374`, `7ced5d5→b7561dd`, `e3ab771→7dae7eb`. Checked: none of the 6 secret values appears in any commit. A backup bundle of the old history was kept locally (not in the repo).

**Still open:**
- Rotate the NetSuite sandbox keys (NetSuite admin).
- GitHub still serves the old commits to anyone with their exact ID until its clean-up runs. GitHub Support can remove them immediately. The repo is private.


## Rollback
Not reversible by design (the purge removes secrets from history).
