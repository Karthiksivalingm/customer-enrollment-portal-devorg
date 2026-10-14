# REQ-003 — Rename Key Accounts to Key Account

| | |
|---|---|
| **ID** | REQ-003 |
| **Status** | ✅ Done |
| **Requested** | 2026-10-06 |
| **Related** | [CR-006](../04-Change-Records/CR-006_Key-Accounts-To-Key-Account-Rename-In-The.md) · [CR-007](../04-Change-Records/CR-007_Key-Accounts-To-Key-Account-Rename-In-PRODUCTION.md) · [CR-008](../04-Change-Records/CR-008_Key-Account-References.md) · [DEP-001](../06-Deployment/DEP-001_Sales-Channel-Sector-Production-Deployment.md) |

## Business need
Rename `Key Accounts` → `Key Account` everywhere it's used, one component at a time, with no data change

## Scope
- **In:** Cluster rules, team records, test classes, page filters and classes that reference 'Key Accounts'
- **Out:** Record data (renamed by the picklist rename itself); Specialty CAN

## Acceptance criteria
1. No component references 'Key Accounts'
2. Cluster and team assignment unchanged for Key Account records
3. Each component deployed only after 'Deploy to Sandbox'

## Output
Change log 2026-10-06

## Open questions
None.
