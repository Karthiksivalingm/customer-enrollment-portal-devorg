# CR-023 — Repository best-practice setup

| | |
|---|---|
| **Change ID** | CR-023 |
| **Date** | 2026-10-13 (13 Oct) |
| **Requirement** | [REQ-023](../03-Requirements/REQ-023_Record-Every-Org-Change-In-GitHub.md) |
| **Org** | Git (no org change) |
| **Deploy ID** | n/a |
| **By** | Assistant |
| **Status** | Done |

## What changed
No org change.
- **GitHub settings:** added the repo description and topics, turned the wiki off, and set branches to be deleted after merge. Secret scanning isn't available on a free private repo; the pre-commit hook covers that gap.
- **`.github/`:** pull request checklist, issue templates (requirement, bug/conflict) and CODEOWNERS.
- **`CONTRIBUTING.md`, `.editorconfig`;** `.vscode/` gained recommended extensions and search/file settings.
- **`scripts/`:** samples moved to `samples/`; the one-off workbook builders moved to `doc-builders/archive_2026-10_workbook_builders/`; README added. `manifest/README.md` added.
- **Hook:** now also runs the project's lint-staged step when Node is installed.
- **Tag:** `sandbox-baseline-2026-10-13` marks the cleaned history, fully synced with GDRSAND.

Most of these files were removed on 2026-10-19 to match the house standard ([CR-025](CR-025_Align-With-House-Standard-And-Remove-Production-Details.md)).

## Rollback
git revert.
