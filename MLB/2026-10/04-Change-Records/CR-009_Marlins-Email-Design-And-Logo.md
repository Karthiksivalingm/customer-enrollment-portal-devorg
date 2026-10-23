# CR-009 — Miami Marlins email design and HD logo

| | |
|---|---|
| **Change ID** | CR-009 |
| **Date** | 2026-10-07 |
| **Requirement** | [REQ-004](../03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV00000085QjSAI |

## What changed
| Component | Type | Action |
|---|---|---|
| `Ticket_Office_Agreement_Details` | Email template | Rebuilt with the approved Marlins design |
| `TicketOfficeAgreementStatus` | VF component | Restyled as the "Agreement Update" block |
| `TicketOfficeAgreementSummary` | VF component | **Created**: Agreement Summary with per-type columns, Membership seat and parking totals, and Multi-Product allocations |
| `TicketOfficeLogo` | VF component | **Created**: logo image from the public document URL |
| `TicketOfficeAgreementStatusCtrl` / `Test` | Apex | Extended: status presentation, summary columns, money formatting, logo URL. 5 tests pass, 98% coverage. |
| `Ticket_Office_Assets` | Document folder (public) | **Created** |
| `Marlins_Logo` | Document (externally available, 600×586 PNG) | **Created**: rendered from MLB's official vector logo (team 146) |

## Verification
- The logo URL returns HTTP 200 with no login.
- All four types rendered from the sandbox.
- The preview was saved to `email-preview/`, with a desktop shortcut.

## Production note
The logo document must exist in production too. The component finds it by name (`Marlins_Logo`).
