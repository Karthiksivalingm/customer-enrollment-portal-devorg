# CON-023 — Several triggers on one object, and Salesforce doesn't guarantee

| | |
|---|---|
| **ID** | CON-023 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-12 |
| **Where** | Account (AccountTrigger + AccountClusterTrigger), Lead (LeadTrigger + LeadClusterTrigger), Contact (2), Case (4), EmailMessage (3) |

## Risk
Several triggers on one object, and Salesforce doesn't guarantee their order

## Mitigation
Don't rely on one trigger running before another. Test the full save
