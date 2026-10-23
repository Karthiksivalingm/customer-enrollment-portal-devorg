# CON-015 — Suite Location: flow saved "MPV", Opportunity only accepts "MVP"

| | |
|---|---|
| **ID** | CON-015 |
| **Status** | ✅ Resolved by [CR-026](../04-Change-Records/CR-026_Agreement-Flow-MVP-Label-And-40-Games.md) |
| **Found** | 2026-10-13 |
| **Related** | [REQ-013](../03-Requirements/REQ-013_Suite-Lease-MVP-Label-And-40-Games.md) |

## Problem
The Agreement Flow's Suite Location choice stored **MPV**, but `Opportunity.Suite_Location__c` is a **restricted** picklist whose value is **MVP**. Any rep who picked MPV would have hit a "bad value for restricted picklist" error when the flow saved the Opportunity. Existing Opportunities already held MVP (2 records), so the value had been set some other way.

## Resolution
The flow choice label and value, and the formula that reads it, were changed to MVP. The internal API names `SuiteChoice_MPV` and `Suite_Tickets_MPV` were kept, because users don't see them and renaming them would touch more of the flow.
