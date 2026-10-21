# CON-017 — "1 year New Business" term option not wired into the calculations

| | |
|---|---|
| **ID** | CON-017 |
| **Status** | ⚠ Open, waiting on business rules |
| **Found** | 2026-10-21 |
| **Related** | [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) · [CR-031](../04-Change-Records/CR-031_Combined-Agreement-Flow.md) |

## Problem
Agreement_Flow v67 (saved in the org on 2026-10-19 by the Billy Marlin login) added the Term Length choice **"1 year New Business"**. Only the choice was added; the formulas were not updated. Its label is stored with HTML formatting and it has no stored value. The combined flow keeps the choice exactly as added.

## Effect when chosen
| Item | Result |
|---|---|
| Term Length stored on the Opportunity and rows | "0" (only 1 / 2 / 3 are recognised) |
| Seasons | Treated like a multi-year term: asks for Contract Season Start and End, not a single Season |
| Escalator text | "No escalator applies for a 1 yr agreement" is not shown; the multi-year texts don't match either |
| Edit mode | Can't be shown prefilled (no saved value maps back to it) |

## Needed
How a 1-year New Business membership should calculate: term number, seasons asked, escalator text, first year of auto renewal.
