# CR-003 — Ticket Office email: recipients and summary rows

| | |
|---|---|
| **Change ID** | CR-003 |
| **Date** | 2026-10-06 |
| **Requirement** | [REQ-002](../03-Requirements/REQ-002_Ticket-Office-Notification-Email.md), [REQ-004](../03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | 0AfiV0000007mPhSAI · 0AfiV0000007lF9SAI · 0AfiV0000007mXlSAI |

## What changed
| Deploy | Change |
|---|---|
| 0AfiV0000007mPhSAI | Template: removed Order #, Address and Payment Plan from Customer & Agreement. Alert: removed the Sales Rep (owner) recipient. |
| 0AfiV0000007lF9SAI | Alert: Ticket Office address changed from the placeholder `ticketoffice@marlins.com.invalid` to `meshakm@unitedtechno.com` |
| 0AfiV0000007mXlSAI | `Opportunity.Suite_Lease_Agreement_Signed_Copy` alert: removed `nivethal@unitedtechno.com` from Additional Emails |

## Verification
The Opportunity workflow was retrieved after the deploy: only `meshakm@unitedtechno.com` remains in Additional Emails.
