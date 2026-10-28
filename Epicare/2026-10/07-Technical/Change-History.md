# Component Change History

One row per Salesforce component created, changed, retrieved in bulk or removed in `force-app/main/default/`, newest last.
`scripts/autocommit.py` refuses source changes that are not named here or covered by a `[bulk: <manifest>]` row.

| Date | Component(s) | Change | Source of change | Related records | Verification |
|---|---|---|---|---|---|
| 2026-10-15 | All in-scope components [bulk: manifest/package.xml] | Baseline retrieval from UTDEV (metadata retrieval, not a deployment or record change). All 6 batches succeeded; 882 of 909 named components returned, 27 explained gaps | `scripts/retrieve.py` | CON-001, CON-002 | [Retrieval-Report.md](Retrieval/Retrieval-Report.md) |
