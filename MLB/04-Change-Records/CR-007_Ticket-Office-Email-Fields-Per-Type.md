# CR-007 — Ticket Office email: fields per agreement type

| | |
|---|---|
| **Change ID** | CR-007 |
| **Date** | 2026-10-07 |
| **Requirement** | [REQ-004](../03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | 0AfiV00000084hZSAQ · 0AfiV00000084mPSAQ · 0AfiV00000084o1SAA · 0AfiV00000084pdSAA |

## What changed (template only)
| Deploy | Change |
|---|---|
| 0AfiV00000084hZSAQ | Added Customer Address (Billing, falling back to Person Mailing), Order # (non-Membership) and Payment Plan |
| 0AfiV00000084mPSAQ | Suite Lease: Order # and Payment Plan hidden |
| 0AfiV00000084o1SAA | Order # row removed for all types; Payment Plan only for Membership and Flex |
| 0AfiV00000084pdSAA | All Ticket Office components redeployed together so the sandbox matches the local project (2 tests passed) |

## Verification
Each type rendered from the sandbox after every change.
