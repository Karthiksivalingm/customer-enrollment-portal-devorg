# CON-007 — AccountCascadeHandler has an unrelated queueable call

| | |
|---|---|
| **ID** | CON-007 |
| **Status** | ⚠ Open (decision pending, [REQ-022](../03-Requirements/REQ-022_Decision-On-ContactTeamReassignQueueable-Line.md)) |
| **Found** | 2026-10-09 |
| **Area** | Apex |

## Conflict
`AccountCascadeHandler` in the sandbox contains `System.enqueueJob(new ContactTeamReassignQueueable(...))`. This line is not part of the Sales Channel / Sector work, and its origin is unknown.

## Resolution
Kept as is in the sandbox. Decision pending ([REQ-022](../03-Requirements/REQ-022_Decision-On-ContactTeamReassignQueueable-Line.md)).
