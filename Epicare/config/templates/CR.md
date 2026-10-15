---
id: {{ID}}
date: {{DATE}}
title: {{TITLE}}
status: Planned
event_key: {{EVENT_KEY}}
---

# {{ID}} — {{TITLE}}

> Record **actual business-record or configuration-data changes** only. Metadata retrieval is not a record change.
> Before and after values must come from verified evidence (a query before and after the change), never from a Git diff.

| Field | Value |
|---|---|
| **Change ID** | {{ID}} |
| **Timestamp** | {{TIMESTAMP}} |
| **Related requirement** | REQ-___ |
| **Target org** | UTDEV — Epicare Insurance, Org ID 00DWB000008ALkv2AG, IsSandbox = true (verified at ____) |
| **Authorization** | Who approved this exact change, when, and where |
| **Method** | e.g. `sf data update record` via `scripts/sf_safe.py --approved {{ID}}`, Data Loader, Salesforce UI |
| **Final result** | Planned |

## Reason for the change

## Scope
| Object API name | Record identifier (only if safe and needed) | Records in scope |
|---|---|---|
| | | |

## Before and after values
| Record | Field API name | Before (verified) | After (verified) |
|---|---|---|---|
| | | | |

<!-- Bulk changes: give the authorized scope, the record counts (selected / succeeded / failed),
     the validation results and point to sanitized evidence files. Do not paste full data extracts. -->

## Verification evidence
- Before query:
- After query:
- Result:

## Errors and rollback
- Errors:
- Rollback plan / action taken:

## Related records
- Requirement:
- Technical documents:
- Conflicts:

## History
| Date | Change |
|---|---|
| {{DATE}} | Change record created. |
