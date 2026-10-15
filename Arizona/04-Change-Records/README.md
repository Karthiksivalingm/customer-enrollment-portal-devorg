# 04-Change-Records

One dated record per **actual** business-record or configuration-data change that the user **explicitly authorized**:
`YYYY-MM-DD-CR-NNN-<slug>.md`. Create with `node scripts/new-doc.js CR "<title>"` (template: [config/templates/CR.md](../config/templates/CR.md)).

- Before and after values come from queries run before and after the change, never from a Git diff or a metadata retrieval.
- Record identifiers only when safe and needed; no full data extracts or unnecessary personal data.
- Metadata retrieval is not a record change. Do not create records for operations that did not happen.

## Register
| ID | Date | Title | Authorized by | Result |
|---|---|---|---|---|
| — | — | No record changes have been made (the 2026-10-15 setup was read-only). | — | — |
