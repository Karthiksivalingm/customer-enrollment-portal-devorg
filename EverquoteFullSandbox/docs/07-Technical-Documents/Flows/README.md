# Flows

Source: `force-app/main/default/flows` (4 flow files). All 4 are **Active**.

Many more flows exist in the org as targets of the Process Builder "Migrate to Flow" tool (see `../Workflows/Process-Flow-Migrations.md`), but they were **not retrieved** into this project. Only `Case_Update_Case_Owner_to_Account_Support_Rep_1` appears both here and as a migration target.

## Summary

| API name | Label | Type | Object / trigger | Status | API |
|---|---|---|---|---|---|
| BDR_Activity_completed_change_lead_owner_to_activity_owner | BDR Activity completed - change lead owner to activity owner | **Process Builder** (processType `Workflow`, legacy) | Task, on create and every edit (`onAllChanges`) | Active | 54.0 |
| Task_BDR_Activity_Completed_Change_Lead_Owner | BDR Activity Completed - Change Lead Owner | Record-triggered, after save | Task, create and update | Active | 64.0 |
| Case_Move_to_Smart_Campaign_Queue | Case: Move to Smart Campaign Queue | Record-triggered, **before save** (fast field update) | Case, create and update | Active | 64.0 |
| Case_Update_Case_Owner_to_Account_Support_Rep_1 | Case: Update Case Owner to Account Support Rep_1 | Record-triggered, after save | Case, create and update | Active | 67.0 |

No screen flows, scheduled flows or platform-event flows are in source.

---

## 1. BDR_Activity_completed_change_lead_owner_to_activity_owner

- **Type:** Process Builder process (`processType = Workflow`), object Task, `TriggerType = onAllChanges`. Description: "Flips leads to activity owner if they are a BDR".
- **Entry criteria** (decision `myDecision`, rule "Activity completed by BDR"), all must be true:
  - `Task.WhatId` StartsWith `00Q` (the Lead key prefix)
  - `Task.Status` = `Completed`
  - `Task.Owner:User.ProfileId` = `00e1a000000hyVbAAI` (**hard-coded Profile ID**)
- **"Previously met" check** (`myRule_1_pmetdec`): the action runs only if the old record did not already meet the same criteria.
- **Key elements:**
  - Record update `myRule_1_A1` on **Lead** where `Id = Task.WhoId`, setting `OwnerId = Task.CreatedBy.Id`.
- **Fields read:** Task.WhatId, Status, Owner.ProfileId, WhoId, CreatedById.
- **Fields written:** Lead.OwnerId.

## 2. Task_BDR_Activity_Completed_Change_Lead_Owner

- **Type:** Record-triggered, after save, Task, create and update. `doesRequireRecordChangedToMeetCriteria = true`, meaning it runs only when the record changes to meet the criteria.
- **Description:** "Migrated from legacy Flow BDR_Activity_completed_change_lead_owner_to_activity_owner (Workflow process type)."
- **Entry criteria (start filters):** `WhatId` StartsWith `00Q` AND `Status = Completed`.
- **Key elements:**
  - Decision `Is_Task_Owner_a_BDR`: `$Record.Owner:User.ProfileId = 00e1a000000hyVbAAI` (**hard-coded Profile ID**).
  - Record update `Update_Lead_Owner` on Lead where `Id = $Record.WhoId`, setting `OwnerId = $Record.CreatedById`.
- **Fields read:** Task.WhatId, Status, Owner.ProfileId, WhoId, CreatedById.
- **Fields written:** Lead.OwnerId.

> **Duplicate automation:** flows 1 and 2 implement the same rule and **both are Active**, so a qualifying Task update would update the Lead owner twice. Deactivate the legacy Process Builder version.
>
> **Likely never fires:** both filter on `WhatId` starting with `00Q`. A Lead can only be a Task's `WhoId` (Name), not its `WhatId` (Related To), so the criteria appear never to match. The update itself uses `WhoId`. Check this against the original intent.

## 3. Case_Move_to_Smart_Campaign_Queue

- **Type:** Record-triggered, **before save**, Case, create and update. `doesRequireRecordChangedToMeetCriteria = true`.
- **Entry criteria:** `Remove_Smart_Campaign__c = true`.
- **Key elements:**
  - Get Records `Get_Smart_Campaign_Queue`: Group where `DeveloperName = 'Smart_Campaign'` and `Type = 'Queue'` (first record, Id only).
  - Assignment `Update_Case_Owner_to_Smart_Campaign_Queue`: `$Record.OwnerId = Get_Smart_Campaign_Queue.Id`.
- **Fields read:** Case.Remove_Smart_Campaign__c, Group.DeveloperName/Type.
- **Fields written:** Case.OwnerId.
- **Overlap:** the active Case workflow rule **"Move to Smart Campaign Queue"** has the same criteria (`Remove_Smart_Campaign__c equals True`) and does the same thing (field update `Owner_Change_to_Smart_Campaign_Queue` to queue `Smart_Campaign`). The rule looks like it was rebuilt as this flow but never deactivated.

## 4. Case_Update_Case_Owner_to_Account_Support_Rep_1

- **Type:** Record-triggered, after save, Case, create and update. `doesRequireRecordChangedToMeetCriteria` is **not set**, so it runs on **every** create and every edit that passes the filter.
- **Description:** "Migrated from the Case: Update Case Owner to Account Support Rep process using Account has a Support Rep criteria. add starter cases to customer support".
- **Entry criteria (filterFormula):** `NOT(CONTAINS({!$Record.OwnerId}, "00GVm000000alG9MAM")) && NOT(CONTAINS({!$Record.OwnerId}, "00GVm000001CG3dMAG"))`. These are **two hard-coded queue IDs**, and the `00GVm` prefix suggests they were created in this sandbox.
- **Key elements:**
  - Record update `myRule_1_A1` on `$Record`, setting `OwnerId = $Record.Account.Support_Rep__c`.
- **Fields read:** Case.OwnerId, Case.Account.Support_Rep__c.
- **Fields written:** Case.OwnerId.

**Risks**

- The original "Account has a Support Rep" criterion is **not** in the migrated filter. A Case with no Account, or an Account with a blank Support_Rep__c, would get `OwnerId = null`, and the save would likely fail.
- Because the flow runs on every edit, any Case edit, including the EmailMessage workflow "Reopen Closed Case on New Email", moves the Case back to the Account's Support Rep. The only exception is a Case owned by one of the two excluded queues.
- It competes with **Case_Move_to_Smart_Campaign_Queue** and the **"Move to Smart Campaign Queue"** workflow for Case.OwnerId. After-save flows run after workflow field updates, so this flow can override the Smart Campaign assignment unless one of the two hard-coded IDs is the Smart_Campaign queue in this org. The metadata does not show which queues these IDs are.
- The hard-coded `00GVm...` IDs will not exist in production or in other sandboxes. Replace them with a Get Records lookup by queue DeveloperName.
- The migration records also list a `Case_Update_Case_Owner_to_Account_Support_Rep_2` target flow, which is not in source. Check that only one version is active in the org.
