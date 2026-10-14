# CON-001 — Production deploy: Production rejects --test-level NoTestRun, and deploy validate

| | |
|---|---|
| **ID** | CON-001 |
| **Status** | ✅ Resolved |
| **Found** | 2026-10-07 |
| **Area** | Production deploy |

## Conflict
Production rejects `--test-level NoTestRun`, and `deploy validate` requires tests

## Resolution
Use `RunSpecifiedTests` with one `--tests` flag per class (a comma list is rejected)
