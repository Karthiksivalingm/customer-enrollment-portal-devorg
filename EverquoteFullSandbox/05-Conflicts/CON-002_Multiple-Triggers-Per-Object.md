# CON-002: Several triggers on one object

| Field | Value |
|---|---|
| Status | ⚠ Open |
| Severity | 🟠 Medium |
| Found | 2026-10-13 |
| Related | [TECH-014](../07-Technical/TECH-014_Trigger-Inventory.md) |

Salesforce doesn't guarantee the order in which multiple triggers on the same object run. **7 of the 33 triggers are active.**

| Object | Active | Inactive (still in source) |
|---|---|---|
| Task | `TaskTrigger` | 10 legacy triggers (AggregateCall, ChangeOwnerAfterSpokeDM, TaskCaseFirstActivity, TaskLead, …) |
| Lead | `LeadTrigger` | 8 (ConvertLeadWhenIMHeld, LeadOutcomeUpdated, LeadOwnerUpdated, LifeLeadCreated, ResetLeadWhenLost, UpdateLeadMobilePhone, UpdateReferral, etcd8_LeadTrigger) |
| Event | `EventTrigger` **and** `EventNotifyCTI` (empty body) | 6 |
| Opportunity | `CreateNewOppWhenClose` (whole body commented out) | `OpportunityTrigger`, so **OpportunityTriggerHandler never runs** |
| OpportunityLineItem | `OpportunityLineTrigger` | `OpportunityLineItemTrigger`, which has identical rollup logic |

## Rule
Don't reactivate the inactive triggers. Add logic to the active handler instead. `OpportunityTriggerHandlerTest` expects a follow-up opp, so it will probably fail while `OpportunityTrigger` is inactive.

## Recommended remediation
Delete the inactive triggers (with a CR and a destructive deployment), and decide whether `OpportunityTrigger` should be active.
