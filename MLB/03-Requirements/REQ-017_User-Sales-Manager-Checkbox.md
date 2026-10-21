# REQ-017 — "Sales Manager" checkbox on User

| | |
|---|---|
| **ID** | REQ-017 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-21) |
| **Requested** | 2026-10-21 (client call) |
| **Related** | CR-034 · ATR-002 · MTC-002 |

## Business need
The Sales Manager list in the Contact **Create Agreement** flow was based on a role. The client wants to choose who appears with a checkbox on the user record instead.

## Scope
- **In:** new User field Sales Manager; the Sales Manager dropdown in the Contact Create Agreement flow (`Vendor_Activation_Food_and_Beverage_Agreement`).
- **Out:** roles themselves, the Opportunity Owner Manager field, approvals.

## Functional behaviour
- **Sales Manager** checkbox on User. System Administrators can edit it; Ticket Sales and Marlins Sales Leadership users can read it.
- The Sales Manager dropdown in the Contact Create Agreement flow lists **active users with Sales Manager ticked**. Roles are no longer used for this list.
- Ticked for now: **Billy Marlin** and **Ruben Smith**.

## Acceptance criteria
1. The dropdown lists exactly the active users with Sales Manager ticked.
2. Unticking a user removes them from the dropdown.

## Assumptions
- "Ruben" means Ruben Smith (System Administrator), not Ruben Prieto Jr.

## Open questions
- Which users should be ticked in production.
