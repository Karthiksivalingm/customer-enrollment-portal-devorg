# CON-003: The same field written by several automations

| Field | Value |
|---|---|
| Status | ⚠ Open |
| Severity | 🟠 Medium |
| Found | 2026-10-13 |
| Related | [TECH-014](../07-Technical/TECH-014_Trigger-Inventory.md) · [TECH-015](../07-Technical/TECH-015_Flow-Inventory.md) · [TECH-016](../07-Technical/TECH-016_Workflow-Rules.md) |

| Field | Competing automation |
|---|---|
| **Lead.OwnerId** | 5 active workflow rules (Duplicate Queue, Recycle Lost Leads, 4 "Unqualified:" rules) · LeadHandler round robin · `TaskHandler.assignLeadOwnerOnFirstCall` · `EventHandler.handleConvertLead`, which resets the owner on **every** Event update · the 2 BDR Task flows |
| **Case.OwnerId** | "Move to Smart Campaign Queue" workflow rule **and** the `Case_Move_to_Smart_Campaign_Queue` flow (same logic) · the `Case_Update_Case_Owner_to_Account_Support_Rep_1` flow runs after every save and can override both, or set the owner to null when there's no Support Rep |
| **Case.Status** | The EmailMessage workflow rule "Reopen Closed Case on New Email" re-fires the Support Rep flow and reassigns the owner |
| **Account.Core_IO_Win_Date__c** | Two active Opportunity workflow rules (Core IO Win, Mark CORE IO Win) |
| **Opportunity.StageName** | "Update stage to Pending" depends on `next_due_date__c`, which only **inactive** triggers maintain, so the value is stale |

The 2026-10-15 retrieve added 432 more flows (318 active in total). They haven't been checked for further overlaps yet; do that per object before any change.
