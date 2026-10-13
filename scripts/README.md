# Scripts

| Folder | Contents | Run from |
|---|---|---|
| `apex/verification/` | Anonymous Apex that tests cluster and team assignment on live records, then **rolls everything back** (throws `StopAndRollbackException` with the results in the message) | `sf apex run --file scripts/apex/verification/<file>.apex -o GDRSAND` |
| `apex/samples/`, `soql/samples/` | Salesforce DX template samples | n/a |
| `doc-builders/build_technical_docs.ps1` | Regenerates the inventories in `07_Technical_Documents/` (classes, triggers, flows, fields, UI) | `powershell -ExecutionPolicy Bypass -File scripts/doc-builders/build_technical_docs.ps1` |
| `doc-builders/build_org_change_history.ps1` | Pulls deploy history and the Setup Audit Trail from GDRSAND and GDRPROD into `04_Change_Records/Org_Change_History/` | same, optional `-Since 2026-08-01` |
| `doc-builders/archive_2026-10_workbook_builders/` | The one-off PowerShell + Excel COM scripts that built the October 2026 workbooks. Kept for reference; their input and output paths point to a temporary folder, so edit `$sp` / `$out` before re-running | n/a |
| `git-hooks/pre-commit` | Blocks commits containing credentials, then runs the project's npm pre-commit (lint/prettier) when Node is installed | enable with `git config core.hooksPath scripts/git-hooks` |

Requirements: Salesforce CLI (`sf`), Windows PowerShell 5.1, Excel (for the workbook builders only). No Python or Node is needed.
