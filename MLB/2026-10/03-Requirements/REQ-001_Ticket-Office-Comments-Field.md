# REQ-001 — Ticket Office Comments field in the Agreement Flow

| | |
|---|---|
| **ID** | REQ-001 |
| **Status** | ✅ Built and deployed to sandbox (utdev) |
| **Requested** | 2026-10-05 |
| **Related** | CR-001 · TECH-001 |

## Business need
The Sales Rep needs to pass notes to the Ticket Office (for example seat preferences or Will Call instructions) as part of every agreement.

## Scope
- **In:** a long-text **Ticket Office Comments** field on all four agreement screens of the Agreement Flow (Membership, Multi-Product, Flex, Suite Lease), saved to the Opportunity.
- **Out:** any other change to the flow's logic (the client said explicitly: "don't change any other logic").

## Functional behaviour
- A *Ticket Office Comments* long text area appears at the bottom of each agreement screen.
- It is **prefilled** with the Opportunity's current value, so finishing the flow without touching it doesn't erase existing comments.
- On finish, the value is saved to `Opportunity.Ticket_Office_Comments__c`, which already existed as a long text area.

## Affected objects and processes
`Agreement_Flow` (screen flow) · `Opportunity.Ticket_Office_Comments__c`

## Acceptance criteria
1. The field shows on all four agreement screens.
2. The value entered is saved to the Opportunity for every type.
3. No other screen, field or logic in the flow changes.

## Assumptions
- Prefilling with the existing value is acceptable. It was proposed to the client, and no objection was raised.

## Open questions
None.
