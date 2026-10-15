# Activities – Task & Event

| Trigger | Status | Contexts → handler methods |
|---|---|---|
| TaskTrigger | Active | before insert → `updateUserRoleAndProfile`; before insert/update → `setReminderDateTime`; after insert → `assignLeadOwnerOnFirstCall`; after insert/update → `notifyCTI` |
| EventTrigger | Active | before insert → `handleUpdateUserRole`; after insert → `handleCaseFirstActivity`, `handleLeadFirstActivity`, `handleConvertLead`; after update → `handleConvertLead` |
| EventNotifyCTI | Active | Body commented out (`NotifyCTI.sendUpdate('event')` disabled) – Events do **not** notify CTI |
| TaskLead, TaskSetReminder, TaskNotifyCTI, TaskUpdateUserRole, TaskCaseFirstActivity, TaskLeadFirstActivity, AggregateCall, ChangeOwnerAfterSpokeDM, UpdateCaseFromTask, UpdateOppFromTask | Inactive | legacy |
| EventUpdateUserRole, EventCaseFirstActivity, EventLeadFirstActivity, ConvertLead, DueDate, UpdateOppFromEvent | Inactive | legacy |

Note: Task-side "first activity" (TaskCaseFirstActivity / TaskLeadFirstActivity) triggers are inactive and not ported to TaskHandler, so `Time_to_First_Response__c` is only recalculated when an **Event** is inserted.

---

## TaskHandler

- **Purpose:** Consolidated Task trigger logic (static methods, no TriggerHandler base).
- **Entry points:**

| Method | Behaviour |
|---|---|
| `updateUserRoleAndProfile(List<Task>)` | For owners whose Id starts `005`, sets `User_Role__c` (UserRole.Name) and `User_Profile__c` (Profile.Name). 1 SOQL on User. |
| `setReminderDateTime(List<Task>)` | `ReminderDateTime__c = ReminderDateTime` (for reporting). |
| `assignLeadOwnerOnFirstCall(List<Task>)` | Inbound call (`CallType='Inbound'`) on a Lead (`WhoId` prefix = Lead) where Lead owner = queue `Inbound_Life_Queue` → Lead.OwnerId = Task.OwnerId. |
| `notifyCTI()` | `NotifyCTI.sendUpdate('task')` – one @future callout per trigger invocation. |

- **Queues/users referenced by name:** Queue DeveloperName `Inbound_Life_Queue`; User `Username LIKE 'pongdeveloper@everquote.com%'` (Pong Developer). Method exits if either is missing.
- **Objects/fields:** Task `User_Role__c`, `User_Profile__c`, `ReminderDateTime__c`, `WhoId`, `CallType`, `OwnerId`; Lead `OwnerId`; User; Group.
- **SOQL/DML:** `assignLeadOwnerOnFirstCall` runs 2 SOQL (User, Group) on **every** Task insert even when no inbound lead calls; +1 Lead SOQL, 1 Lead update when relevant.
- **Logic note:** The skip condition `(owner is user AND owner ≠ Pong) OR owner ≠ Inbound_Life_Queue` means only leads owned by `Inbound_Life_Queue` are reassigned; the Pong Developer branch is effectively unused.
- **Governor / risks:** `notifyCTI` @future fires on **every** Task insert/update, including Tasks inserted from batch, @future or queueable contexts → `System.AsyncException` ("Future method cannot be called from a future or batch method"). Each 200-record chunk consumes 1 of 50 future calls. Lead update re-fires LeadTrigger (Odie owner sync).
- **Tests:** TaskHandlerTest, TaskLeadTests (hardcoded Ids `0051a000002j8TUAAY`, `00G2g000000HbBiEAK`, `00G1a000001WCo7EAG` at L16–18), TestTaskSetReminder, TestAggregateCall, TestUpdateCase.

## EventHandler

- **Purpose:** Consolidated Event trigger logic (static methods).
- **Entry points:**

| Method | Behaviour |
|---|---|
| `handleUpdateUserRole(List<Event>)` | Same as Task: `User_Role__c`, `User_Profile__c`. |
| `handleCaseFirstActivity(List<Event>)` | For Events whose `WhatId` is a Case: earliest Task/Event CreatedDate → `Case.Time_to_First_Response__c` (hours since Case.CreatedDate). |
| `handleLeadFirstActivity(List<Event>)` | For Leads in `WhoId`: start = max(`CreatedDate`, `Assigned_Date__c`); earliest Task (excluding subjects `'Lead On Pro. Please Contact!'`, `'New Lead! Please contact'`) or Event after start → `Lead.Time_to_First_Response__c` (null if none). |
| `handleConvertLead(List<Event>)` | `Subject='Initial Meeting'` and `Meeting_Result__c='Held - Correct Contact'` → Lead `IMHeld__c=true`, `InitialMeetingDate__c=ActivityDate`, `OwnerId = Event.OwnerId`. |

- **Objects/fields:** Event `User_Role__c`, `User_Profile__c`, `Meeting_Result__c`; Case `Time_to_First_Response__c`; Lead `Time_to_First_Response__c`, `Assigned_Date__c`, `IMHeld__c`, `InitialMeetingDate__c`, `OwnerId`.
- **SOQL/DML:** Up to 7 SOQL and 3 updates per after-insert. Task/Event history queries are unbounded (`WHERE WhatId/WhoId IN …`, no LIMIT) – large activity histories can hit the 50,000-row limit.
- **Risks:** `handleCaseFirstActivity` queries Case with all `WhatId`s (non-Case Ids just return nothing). Lead update re-fires LeadTrigger (owner change → Odie sync via @future). Changing Lead owner on IM held overrides prior owner.
- **Tests:** EventHandlerTest (hardcoded OwnerId `005000000000000`, L106), TestCaseFirstActivity, TestLeadFirstActivity, TestConvertLead.
