# CON-009 — Logic: Saving an Account with open Opportunities failed with an invalid

| | |
|---|---|
| **ID** | CON-009 |
| **Status** | ⚠ Open |
| **Found** | 2026-10-09 |
| **Area** | Logic |

## Conflict
Saving an Account with open Opportunities failed with an invalid dependent Sector

## Resolution
`AccountCascadeHandler` and `LeadConversionHandler` now sync Sector to open Opportunities
