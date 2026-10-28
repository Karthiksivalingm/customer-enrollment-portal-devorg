# CON-003 — Batched retrieval interrupted: state folder deleted

| Field | Value |
|---|---|
| **ID** | CON-003 (formerly CF-002) |
| **Found** | 2026-10-14, about 22:23 IST |
| **Related requirement / change** | TVM setup: baseline retrieval (`scripts/retrieve.py`) |
| **Status** | Resolved by workaround and re-run. Root cause not confirmed |

## Error message and evidence
```
code        Succeeded   563 components
automation  Succeeded   682 components
datamodel   Succeeded  8767 components
FileNotFoundError: [Errno 2] No such file or directory: '...\TVM\.tvm-state\retrieve\ui.json'
```
The whole `TVM/.tvm-state/` folder (git-ignored local automation state) was gone while the `ui` batch was running.
`force-app/` and the documents were intact (11,642 files).

## Affected components
`scripts/retrieve.py` (batch result logs). No Salesforce or Git impact.

## Investigation performed
| Date | Step | Finding |
|---|---|---|
| 2026-10-14 | Reviewed TVM scripts | No TVM script deletes `.tvm-state/` (only the lock file and the commit-message file are removed) |
| 2026-10-14 | Reviewed the self-tests | They run in a temporary repository with their own `.tvm-state/` |

## Potential causes (suspected, not confirmed)
- Another process removed the folder (an editor, a sync tool, or a cleanup command run in parallel).

## Confirmed root cause
Not confirmed.

## Resolution
- `scripts/retrieve.py` now recreates its output folder before every write.
- The full batched retrieval was re-run (see [Retrieval-Report.md](../07-Technical/Retrieval/Retrieval-Report.md)).

## Tests and verification
| Date | Test / check | Result |
|---|---|---|
| 2026-10-14 | Full re-run of `scripts/retrieve.py` | See the Retrieval report |

## Remaining risks and follow-up actions
- If the folder disappears again, the auto-commit lock and pending commit message are lost. That is harmless: the next run recreates them.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Recorded with workaround. |
