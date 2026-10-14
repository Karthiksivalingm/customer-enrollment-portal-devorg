# CR-002 — New Sector values

| | |
|---|---|
| **Change ID** | CR-002 |
| **Date** | 2026-09-28 (28 Sep, Setup) |
| **Requirement** | [REQ-004](../03-Requirements/REQ-004_Add-New-Sector-Values-Where-Old-Values-Are.md) |
| **Org** | GDRSAND |
| **Deploy ID** | n/a |
| **By** | User (Setup) |
| **Status** | Done |

## What changed
- 11:34: values **Enterprise, Strategic, Development, Discount, Planned, Self Service, Distributor** added to the global value set `Sector`.
  **Development** isn't in the approved mapping (see `05-Conflicts` CON-016).
- 11:41 – 11:44: Sector ← Sales Channel dependencies updated on Lead, Account, Contact and Opportunity.


## Rollback
Deactivate the new Sector values and restore the dependencies in Setup (only while no records use them).
