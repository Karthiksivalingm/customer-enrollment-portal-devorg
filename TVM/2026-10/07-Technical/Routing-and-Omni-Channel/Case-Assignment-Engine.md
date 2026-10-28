# Case Assignment Engine (Apex round-robin)

| Field | Value |
|---|---|
| **Type** | Apex trigger logic, batch jobs, custom metadata |
| **Components** | `CaseTrigger_FNDN` → [`CalculateCaseDueDate`](../../../force-app/main/default/classes/CalculateCaseDueDate.cls); [`CaseAssignmentBatch`](../../../force-app/main/default/classes/CaseAssignmentBatch.cls), [`CaseAssignmentHybridBatch`](../../../force-app/main/default/classes/CaseAssignmentHybridBatch.cls), [`ScheduleCaseAssignmentBatch`](../../../force-app/main/default/classes/ScheduleCaseAssignmentBatch.cls); `Case_Routing_Config__mdt` (102 records); Flows `Case_Assignment_Process`, `Update_Case_AT_and_Owner` |
| **Status** | Active. `ScheduleCaseAssignmentBatch` is scheduled hourly at :30 in Fullsandbox (CronTrigger, 2026-10-14) |
| **Tests** | `CalculateCaseDueDateTest`, `CaseAssignmentBatchTest`, `CaseAssignmentHybridBatchTest` (see [inventory](../Metadata-Inventory/Apex-Classes.md#test-classes)) |

## Purpose
Assign Foundation and "New Digital Support" Cases to the right person by request type. Assignment is by round-robin within a queue, or to an
Account-level technician. Cases are reassigned automatically when they reach "Ready for QA".

## Entry points
- **Before insert**, from `CaseTrigger_FNDN`, when `Foundation_Record__c = true` or `Case_Category__c = 'New Digital Support'`, and `Case_Assign_To__c` is blank.
- **Before update:** a category change to New Digital Support re-routes. The first transition to `Status = 'Ready for QA'` applies the QA rules.
- **Hourly batch:** `CaseAssignmentBatch` handles Non Hybrid and `CaseAssignmentHybridBatch` handles Hybrid. They take today's unassigned Cases of Case_Entry = Auto that have `Case_Assignment_Queue__c` set.

## Behaviour
1. Load the active `Case_Routing_Config__mdt` records into two maps (Hybrid and Non Hybrid), keyed by `Request_Type__c`.
2. Choose the map: Hybrid when `Account.FNDN_Billed_Through_TVM__c = true`.
3. Initial assignment:
   - **Queue:** take the members of the named queue (Group by Name) and drop users with `User.OOO__c = true`. Assign the user after the last-assigned user (round-robin). Set `Case_Assign_To__c`, `OwnerId` and `Case_Assignment_Queue__c`.
   - **Field:** take the user in the Account field named by `Field_Name__c`.
   - **Auto entry:** only set the queue; the batch assigns later and sets `Status_Filtered__c` to Assigned.
4. QA reassignment: the Campaigns rule applies first (`Campaigns__c`), then `After_QA_Assignment__c`. That assigns to the QA queue, to the field named by `QA_Field_Name__c`, or to the assignee's manager.

## Dependencies
| Depends on | Notes |
|---|---|
| Queue names in `Queue__c` (Hybrid, Action, Digital Analyst, Analyze, Digital Coop, Helpware, Helpware/Qualminds, Hybrid Weekly QA) | Text match on the Group Name. Renaming a queue breaks routing |
| Queue membership, `User.OOO__c` | Maintained by `UpdateUserOOOBatch` / `OOO_Calendar__c`. That batch is **not scheduled** in Fullsandbox |
| Account fields `Account_Technician__c`, `Secondary_Account_Technician__c`, `Account_Technician_Trainee__c`, `FNDN_Billed_Through_TVM__c` | |
| Flows `Case_Assignment_Process` (before-save), `Update_Case_AT_and_Owner` (after-save), `Case_SLA_Time_Calculation` | They run on the same records |

## Security
Runs in trigger context. NOT YET VERIFIED: the sharing declaration of the classes; see the inventory "Sharing" column.

## Tests and verification
| Date | Test / check | Result |
|---|---|---|
| 2026-10-14 | Source reading and CronTrigger query | Behaviour as described; not executed |

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-14 | Created from the baseline retrieval | — |
