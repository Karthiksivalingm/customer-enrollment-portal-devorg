# CR-025 — Align with the house folder standard (sandbox-only content)

| | |
|---|---|
| **Change ID** | CR-025 |
| **Date** | 2026-10-19 |
| **Requirement** | [REQ-034](../03-Requirements/REQ-034_Align-Goodr-With-MLB-Standard.md) |
| **Org** | Repository only (no org change) |
| **Deploy ID** | n/a |
| **By** | Assistant |
| **Status** | Done |

## What changed
**Folders now match MLB:**
- `01-Instructions` holds exactly `AI-Workflow.md`, `Coding-Standards.md` and `Project-Rules.md`, copied from MLB.
- `08-QA` was added, with `01-Automated-Testing` and `02-Manual-Testing`.
- No subfolders remain in `04-Change-Records` or `07-Technical`.
- `manifest/` holds only `package.xml`, and `scripts/` holds `apex/hello.apex` and `soql/account.soql`.
- The `.vscode/` settings now match MLB.

| Moved | To |
|---|---|
| `01-Instructions/Developer-Onboarding.md` | [KB-006](../02-Knowledge-Base/KB-006_Developer-Onboarding.md) |
| `02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding` | [Business-Process.md](../02-Knowledge-Base/Business-Process.md) (KB-002) |
| 3 QA workbooks | `08-QA/02-Manual-Testing/MTC-001…003` |
| Sandbox verification results | [ATR-001](../08-QA/01-Automated-Testing/ATR-001_Cluster-And-Team-Old-And-New-Mapping.md) |
| 2 impact-analysis workbooks | `07-Technical/TECH-008`, `TECH-009` |
| NetSuite placeholder templates | Folded into [TECH-007](../07-Technical/TECH-007_Secure-Configuration.md) |

**Non-sandbox details removed:**
- The whole `06-Deployment` folder: deployment packages and rollbacks, deployment documents, DEP-001 and DEP-002, checklists, and the change-set list.
- The deploy and Setup Audit Trail exports of the other org.
- Documents that existed only for another org:

  | Type | Removed |
  |---|---|
  | Requirements | REQ-005, 006, 015, 018, 019, 020, 024, 026, 031 |
  | Change records | CR-007, 010, 013, 020 |
  | Conflicts | CON-001, 002, 004, 005, 006, 015, 021, 022 |

  Their numbers are not reused.
- Aliases, usernames and URLs of other orgs, and every sentence about them, removed from the remaining documents and workbooks. One workbook sheet built from another org was deleted.

**Removed as not part of the standard:**
- Before-snapshots and data-load files (these are also in git history).
- Session logs.
- Generator scripts, the git hook and retrieve manifests.
- `CLAUDE.md`, `CONTRIBUTING.md`, `.github/`, `.editorconfig` and `.gitattributes`.
- Internal tool names in documents, which now say "Assistant".

## Verification
- A search of `Goodr/` (documents and workbooks) finds no aliases, URLs or usernames of other orgs.
- All relative links resolve.

## Rollback
Revert this commit in `sfdcut/SFDC`. Everything removed is still in git history.
