# CON-007 — Sandbox vs production: AccountCascadeHandler in the sandbox has System

| | |
|---|---|
| **ID** | CON-007 |
| **Status** | ⚠ Open (decision pending, REQ-022) |
| **Found** | 2026-10-09 |
| **Area** | Sandbox vs production |

## Conflict
`AccountCascadeHandler` in the sandbox has `System.enqueueJob(new ContactTeamReassignQueueable(...))`, which isn't part of this work and isn't in production

## Resolution
Kept as is in the sandbox. Decision pending (REQ-022)
