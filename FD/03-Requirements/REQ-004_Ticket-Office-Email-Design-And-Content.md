# REQ-004 — Ticket Office email: Marlins design and content changes

| | |
|---|---|
| **ID** | REQ-004 |
| **Status** | ✅ Built and deployed to sandbox (utdev) |
| **Requested** | 2026-10-06 to 2026-10-07 (several rounds) |
| **Related** | REQ-002 · CR-003 · CR-007 · CR-009 · TECH-002 · TECH-003 |

## Business need
The email goes to Miami Marlins staff. It must look professional, clearly Marlins-branded and easy to read, not like a generic template.

## Design history (for future reference)
| Round | Direction | Client verdict |
|---|---|---|
| 1 | Generic gradient card | Accepted at first, then "looks like a standard Claude UI" |
| 2 | Editorial ticket style | Not good |
| 3 | Three concepts (Ballpark Night, Color Block, Scoreboard) | Too dark; remove the progress path |
| 4 | Light minimal | Very bad |
| 5 | Event ticket / colour cards / boarding pass | Not user friendly |
| 6 | Dynamic colour per event and per type | "Looks good, make it more professional" |
| 7 | Executive (Marlins palette) | Very bad; the client is a baseball team |
| 8 | **Miami Marlins baseball design** | ✅ **Approved** |

## Final approved design
- **Header** (medium height): Miami Blue gradient, "MIAMI MARLINS · TICKET OFFICE", `{TYPE} AGREEMENT`, ProVenue chip, **official Marlins logo** on a white badge.
- Red baseball-stitch dividers.
- **Agreement Update** block, coloured by the Adobe status.
- Greeting and **Ticket Office Comments**.
- **Customer:** name, address, ProVenue ID.
- **Agreement Summary** (renamed from "Box Score"), placed after Customer.
- Membership seat and parking "ticket" cards; Suite Lease suite card.
- Red "Open in Salesforce" button.
- **Footer:** the thank-you signature (Rep name, title, email) and a small logo. The old team footer band was removed.

## Content changes requested
| Date | Change |
|---|---|
| 2026-10-06 | Remove Order #, Address and Payment Plan from Customer & Agreement; remove the Sales Rep from recipients |
| 2026-10-07 | Add back missing requirement fields (Address, Payment Plan, Order #) |
| 2026-10-07 | Suite Lease: remove Order # and Payment Plan |
| 2026-10-07 | Multi-Product: remove Order # and Payment Plan. Flex: remove Order #. |
| 2026-10-07 | Multi-Product Agreement Summary: add `Amount_allocated_to_Flex__c`, `Amount_allocated_to_Suites__c`, `Amount_allocated_to_Groups__c` (with `Total_Multi_Product__c`) |
| 2026-10-07 | Use the official logo in HD; header medium size; Box Score after Customer, renamed |

Final field list per type: [TECH-003](../07-Technical/TECH-003_Ticket-Office-Email-Field-Mapping.md).

## Acceptance criteria
- Renders correctly for all four types (verified by rendering from the sandbox).
- The logo loads without a Salesforce login (verified: public URL returns HTTP 200).

## Open questions
- Should the logo also appear on the **Adobe Sign agreement PDFs**? The client said "use this logo also in the agreement"; still unanswered whether that meant this email or the Adobe documents.
