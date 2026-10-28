# CR-040 — Opportunity page: Suite Lease Details arranged, Suite Payment Plan section

| | |
|---|---|
| **Change ID** | CR-040 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | `0AfiV000000BryfSAC` (first attempt `0AfiV000000Brx3SAC` failed: new facet not referenced). Row visibility changed in CR-041 (`0AfiV000000BxSzSAK`). |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
`Ticketing_Opportunity_LRP` (Lightning page):

| Section | Left column | Right column |
|---|---|---|
| Suite Lease Details | Suite Location, Suite Number, Suite Level, Total Tickets in Suite, Total # of Games, Parking Passes | This Season Total Amount, Total Years of Contract, Year 1–5 License Fee (existing visibility kept) |
| **Suite Payment Plan** (new, shown when Agreement Type = Suite Lease) | Number of Payment Schedule, Payment 1–12 Due Date | Due Date, Payment Amount |

Each due date row is shown only when it is in use. The final rules are in [CON-020](../05-Conflicts/CON-020_Opportunity-Page-Visibility-Filter-Limits.md) and TECH-011.

## Verification
Screenshot of a saved 3-payment schedule: only Payment 1–3 Due Date shown (ATR-003 TC-019-14).

## Rollback
Redeploy `Ticketing_Opportunity_LRP` from git before this change.
