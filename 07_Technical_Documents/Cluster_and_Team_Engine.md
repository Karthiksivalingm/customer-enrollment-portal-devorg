# Cluster and Team Engine

This is the logic changed by the Sales Channel / Sector transition. It was confirmed by reading the code in `force-app/main/default`.

## Flow of a save

```
Account save
  before insert/update → ClusterRuleEngine.evaluate('Account', new, oldMap)   sets Cluster__c
  after                → AccountCascadeHandler.handle(...)
                           ├─ ClusterTeamEngine.assignTeams('Account', …)        AccountTeamMember
                           ├─ open Opportunities: copy Sales Channel, Sector, Cluster
                           │    └─ ClusterTeamEngine.assignTeams('Opportunity', …)  OpportunityTeamMember
                           ├─ Contacts: copy Cluster → ClusterTeamEngine.assignTeams('Contact', …)  Contact_Team__c
                           └─ enqueue ContactTeamReassignQueueable (sandbox only, see 05_Conflicts CF-07)

Lead save
  before → ClusterRuleEngine.evaluate('Lead', …)
  after  → ClusterTeamEngine.assignTeams('Lead', changed)                      Lead_Team__c
         → LeadConversionHandler.handleConversion(...)   on conversion: syncs Sector to existing open Opportunities

Opportunity save
  before → ClusterRuleEngine.evaluate('Opportunity', …)
  after  → ClusterTeamEngine.assignTeams('Opportunity', changed)

Contact insert
  after  → ContactTeamReassignQueueable → ClusterTeamEngine.assignTeams('Contact', …)
```

## ClusterRuleEngine
- Reads `Sales_Channel_Cluster__mdt` records for the object (`ObjectAPIName__c`).
- `Rule_Condition__c` is a simple expression such as `Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service'`. Fields are read dynamically with `record.get()`.
- **The first matching rule wins.** There is no ORDER BY, so rules must not overlap.
- **Skips Contact.** A Contact's cluster comes from its Account through `AccountCascadeHandler`.
- On update it only runs when **Sales_Channel__c or Sector__c changed** (since 2026-10-09; before that it checked Sales Channel only).
  `Sector__c` is read with a safe getter, so objects without the field still work.

## ClusterTeamEngine
- Reads `Account_Cluster_Team__mdt` by `Cluster_Value__c` and object. `Sales_Channel__c` on that type is a label only and isn't used for matching.
- Only **active** users are assigned (`IsActive = true`).
- Deletes the existing team rows for the record and inserts the new ones:
  `AccountTeamMember`, `OpportunityTeamMember` (one row per user), `Contact_Team__c`, `Lead_Team__c` (one row per role).
- Roles: Sales Director, Sales Manager, Account Manager, Marketing Support, Field Support, Field Marketing Support.

## Current cluster map (Account rules; Lead, Opportunity and Contact are equivalent)
| Condition | Cluster |
|---|---|
| Sales Channel = Key Account | 1 |
| Specialty + Planned (old: Bridge, Specialty CAN + Bridge) | 5 |
| Specialty + Self Service (old: Sellgoodr USA, Specialty CAN + Sellgoodr CAN) | 6 |
| Global | 7 |
| Partnerships | 8 |
| Mid-Market (inactive channel) | 5 |

The rules for the old values are still in place, so records that haven't been migrated still get the same cluster.
The full rule list is in [Fields_and_Custom_Metadata.md](Fields_and_Custom_Metadata.md).

## Tests
`ClusterRuleEngineTest` (includes `testEvaluate_SectorOnlyChanged_RuleEngineRuns`), `AccountCascadeHandlerTest`
(includes `testHandle_SalesChannelAndSectorChanged_SectorCascadedToOpp`), `ClusterTeamEngineTest`, `ClusterTriggerTest`,
`ContactClusterTriggerTest`, `LeadConversionHandlerTest`, `LeadConversionHandlerTest1`.

Live verification scripts (they insert records, check them, then roll back): `scripts/apex/verification/`.
