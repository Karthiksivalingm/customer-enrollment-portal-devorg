# CON-034 — Auto-Offboarding Exclusion: open decisions

| | |
|---|---|
| **ID** | CON-034 |
| **Status** | ⚠ Open (client decision) |
| **Found** | 2026-10-21 |
| **Area** | Shopify At-Risk / Offboarding |
| **Related** | [REQ-035](../03-Requirements/REQ-035_Auto-Offboarding-Exclusion.md) · [CR-027](../04-Change-Records/CR-027_Auto-Offboarding-Exclusion-Batch-And-Flow.md) |

## Decisions needed
1. **Unticking after 18 months.** If the box is unticked when the store is past 18 months and the 30-day warning (Email 3) was sent before it was excluded, the next daily run deactivates the store with no new warning. If Email 3 was never sent, the store is held and not deactivated automatically. **Built as:** resume from where it left off. **Option:** send a fresh 30-day warning first (small extra change).
2. **Manual Company offboarding.** If a user offboards a whole Company by hand, its excluded stores are still deactivated by the existing cascade. **Built as:** yes, because this is a person's decision, not the automation's.
3. **At-risk task.** The at-risk task is stopped for excluded accounts. **Built as:** stopped; to confirm with the client.

## Platform note
Account field history tracking is at 19 of 20 fields after CR-026.
