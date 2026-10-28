# Component Change History

One row per Salesforce component created, changed, retrieved in bulk or removed in `force-app/main/default/`, newest last.
The auto-commit (`scripts/autocommit.py`) refuses source changes that are not named here, or covered by a `[bulk: <manifest>]` row.

| Date | Component(s) | Change | Source of change | Related records | Verification |
|---|---|---|---|---|---|
| 2026-10-14 | All unmanaged in-scope components [bulk: manifest/package.xml] | Baseline retrieval from Fullsandbox (metadata retrieval, not a deployment or record change). Batches `code`, `automation`, `datamodel` complete; `ui`, `routing`, `access` were still running at the first push | `scripts/retrieve.py` | CON-002, CON-003 | [Retrieval-Report.md](Retrieval/Retrieval-Report.md) |
