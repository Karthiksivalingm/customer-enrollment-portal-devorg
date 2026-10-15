# 04 — Change Records

Actual Salesforce **business-record or configuration-data changes** only, with verified before and after values:
`YYYY-MM-DD-CR-NNN-short-description.md`, created with `python scripts/new_doc.py CR "<title>"`. Template: [config/templates/CR.md](../config/templates/CR.md).

Metadata retrieval, metadata changes and Git commits are **not** record changes. They go to `07-Technical-Documents/Change-History.md`.

**Status 2026-10-15:** no verified record change has been made or recorded. The Epicare setup only read metadata and ran read-only queries.
Changes made in the Salesforce UI or by integrations are not detected automatically (see [Known-Constraints.md](../02-Knowledge-Base/Known-Constraints.md), A2).
