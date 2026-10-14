# CR-016 — Signed agreement email with the signed PDF attached

| | |
|---|---|
| **Change ID** | CR-016 |
| **Date** | 2026-10-08 |
| **Requirement** | [REQ-005](../03-Requirements/REQ-005_Signed-Agreement-Email-With-PDF.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV000000891KSAQ |

## What changed
| Component | Type | Action |
|---|---|---|
| `Ticket_Office_Email` | Custom Label | **Created** (`meshakm@unitedtechno.com`) |
| `TicketOfficeSignedEmail` + `TicketOfficeSignedEmailTest` | Apex (invocable + Queueable) | **Created**. 3 tests pass, 90% coverage. |
| `Adobe_Agreement_Notify_Ticket_Office` | Flow | New first outcome **Customer_Signed** (status = Signed) → Apex action `Send_Signed_Email_With_PDF`. The old customer outcome now handles **declined only** (label "Customer Declined"). |

## Verification
Routing simulated with a trace (rolled back):
- signed → Apex action
- declined → email alert
- manager approved → email alert
