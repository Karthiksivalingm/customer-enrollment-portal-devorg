# CON-010 — Ticket Office email address stored in two places

| | |
|---|---|
| **ID** | CON-010 |
| **Status** | ⚠ **Open risk** |

## Conflict
| Where | Used by |
|---|---|
| Email alert `Opportunity.Ticket_Office_Agreement_Details` → Additional Emails | Sent ($50k+), manager approved or declined, customer declined emails |
| Custom Label `Ticket_Office_Email` | Customer **signed** email with the PDF (Apex can't read the alert's address) |

Both hold `meshakm@unitedtechno.com`, a **test address**.

## Risk
If only one is updated, some events go to the old address.

## Action needed
- Before production, get the **real Ticket Office mailbox** and update **both**.
- Option for later: move every event to Apex reading the label, so there's one source of truth.
