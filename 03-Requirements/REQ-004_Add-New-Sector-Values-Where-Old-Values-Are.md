# REQ-004 — Add New Sector Values Where Old Values Are Used

| | |
|---|---|
| **ID** | REQ-004 |
| **Status** | ✅ Done |
| **Requested** | 2026-10-06 |
| **Related** | [CR-002](../04-Change-Records/CR-002_New-Sector-Values.md) · [CR-009](../04-Change-Records/CR-009_New-Sector-Values-In-Logic.md) · [DEP-001](../06-Deployment/DEP-001_Sales-Channel-Sector-Production-Deployment.md) |

## Business need
Add the new Sector values where the old values are used (cluster rules, page filters) without breaking existing logic

## Scope
- **In:** New Sector values (Enterprise, Strategic, Discount, Planned, Self Service, Distributor) added next to the old ones in cluster rules and page filters
- **Out:** Removing old values; data changes

## Acceptance criteria
1. Records on new values get the same cluster as the matching old value
2. Existing logic keeps working for old values

## Output
Change log 2026-10-06/07

## Open questions
None.
