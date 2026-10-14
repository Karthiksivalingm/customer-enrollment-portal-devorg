# CON-025 — Flow Opportunity_field_update_from_Account

| | |
|---|---|
| **ID** | CON-025 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-12 |
| **Where** | Opportunity |

## Risk
Flow `Opportunity_field_update_from_Account` (before-save) and `AccountCascadeHandler` both set Sales Channel / Sector / Cluster on Opportunity

## Mitigation
Change both together, or the values may disagree
