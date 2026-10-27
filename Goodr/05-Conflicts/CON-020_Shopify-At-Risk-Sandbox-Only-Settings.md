# CON-020 — Shopify At-Risk: Sandbox-only settings

| | |
|---|---|
| **ID** | CON-020 |
| **Status** | ⚠ Open: the time zone is decided and applied in the sandbox; the test filter is still sandbox-only |
| **Found** | 2026-10-13 |
| **Area** | Shopify At-Risk |

## Conflict
Sandbox-only settings: Test Store Name Filter `R12 WOT%`, schedules in IST.

## Decision (client, 2026-10-27)
All scheduled jobs run in **Pacific Time, following daylight saving** (America/Los_Angeles), not a fixed PST offset. The notices job runs after the order sync.

## Resolution
- **Time zone:** done in the sandbox. All custom scheduled jobs were rescheduled in America/Los_Angeles ([CR-034](../04-Change-Records/CR-034_Scheduled-Jobs-Moved-To-Pacific-Time.md)). In other orgs, the user who schedules the jobs must be set to America/Los_Angeles first, because a job keeps the time zone it was scheduled with.
- **Test Store Name Filter:** stays `R12 WOT%` in the sandbox; it must be blank wherever the process goes live.
