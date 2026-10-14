# CR-024 — Move into the sfdcut/SFDC repository

| | |
|---|---|
| **Change ID** | CR-024 |
| **Date** | 2026-10-14 |
| **Requirement** | [REQ-033](../03-Requirements/REQ-033_Move-Goodr-Into-Sfdcut-SFDC-Repository.md) |
| **Org** | Git (no org change) |
| **Deploy ID** | n/a |
| **By** | Session A |
| **Status** | Done (merged through a pull request) |

## What changed
- The Goodr project moved into the shared repository `sfdcut/SFDC` as the folder `Goodr/`, next to `FD/` and `MLB/`. It was imported with `git subtree`, so **the full commit history is kept** (credentials already purged, [CR-022](CR-022_Credential-Hardening-In-The-Repository.md)).
- It was restructured to the FD/MLB house standard:
  - folders `01-Instructions` … `07-Technical`, with one document per item: REQ-, CR-, CON-, DEP-, TECH- and KB- documents;
  - `DOCUMENT-INDEX.md`;
  - the shared `AI-Workflow.md` and `Coding-Standards.md` copied in.
- Old to new IDs:

  | Old | New |
  |---|---|
  | CHG-01…23 | CR-001…023 |
  | CF-01…20 | CON-001…020 |
  | PC-01…13 | CON-021…033 |
  | `Working_Instructions.md` | `Project-Rules.md` |
  | `Change_Log.md`, `Conflicts_Log.md`, `Requirements_Log.md` | split into one document per item |

- Deployment workbook paths were updated to the new folders. The scripts were updated for the new paths.
- `yogemani/GDRSandbox` was left unchanged, as the user chose.

## Verification
- Every file from the old repository is present under `Goodr/`, except the logs that were split into separate documents.
- No secret values in any commit.
- `sfdx-project.json` works from the `Goodr/` folder.

## Rollback
Revert the merge commit in `sfdcut/SFDC`. The old repository is still intact.
