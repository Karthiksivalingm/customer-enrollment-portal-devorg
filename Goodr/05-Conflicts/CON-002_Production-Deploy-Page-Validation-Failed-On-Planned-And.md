# CON-002 — Production deploy: Page validation failed on Planned and Key Account because the

| | |
|---|---|
| **ID** | CON-002 |
| **Status** | ✅ Resolved |
| **Found** | 2026-10-07 |
| **Area** | Production deploy |

## Conflict
Page validation failed on `Planned` and `Key Account` because the picklist values don't exist in production yet

## Resolution
Create the picklist values first, then deploy pages. Validate the non-page components separately (113 components, job `0AfPn000002N1BxKAK`, passed)
