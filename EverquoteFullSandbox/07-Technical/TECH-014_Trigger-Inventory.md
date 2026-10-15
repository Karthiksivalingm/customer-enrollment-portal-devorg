# Apex Triggers

Source: `force-app/main/default/triggers` (33 triggers). Status and API version come from each `.trigger-meta.xml`.

**Summary:** 7 triggers are **Active** and 26 are **Inactive**. The org has partly moved to a "one trigger per object" design. `LeadTrigger`, `TaskTrigger`, `EventTrigger` and `OpportunityLineTrigger` now hold the logic that used to live in the older single-purpose triggers, and those older triggers are set to Inactive but are still in the source tree.

## Trigger inventory

| Trigger | Status (API) | Object | Events | Handler class called (or "logic inline") | Purpose | Recursion guard? |
|---|---|---|---|---|---|---|
| AggregateCall | Inactive (34.0) | Task | after insert, after update, after delete | logic inline | Rolls call activity up to the related Lead: Last_Call_Time__c, Call_Count__c, Call_Duration_Seconds__c/Minutes__c, GateKeeperCallCount__c, DMCallCount__c, LastCallDispo__c, Next_Due_Date__c | No. Also runs SOQL and DML inside a loop |
| ChangeOwnerAfterSpokeDM | Inactive (39.0) | Task | after insert, after update | logic inline | When CallDisposition = "Spoke to Decision Maker", moves a queue-owned Lead to the task owner, or a Winback Opportunity owned by 2 hard-coded users to the task owner | No |
| ConvertLead | Inactive (36.0) | Event | after insert, after update | logic inline | "Initial Meeting" event with Meeting_Result__c = "Held - Correct Contact" sets Lead IMHeld__c = true, InitialMeetingDate__c, and OwnerId = event owner | No |
| ConvertLeadWhenIMHeld | Inactive (39.0) | Lead | after update | logic inline | Auto-converts the Lead (Database.convertLead) when IMHeld__c = true | No |
| CreateNewOppWhenClose | **Active** (39.0) | Opportunity | after update | logic inline (**whole body commented out**) | No-op. The commented code copied a closed Upsell opp into a new one | n/a |
| DueDate | Inactive (34.0) | Event | after insert, after update, after delete | logic inline | Recalculates Lead Next_Due_Date__c from open tasks and future events | No |
| EventCaseFirstActivity | Inactive (36.0) | Event | after insert | logic inline | Case Time_to_First_Response__c (hours from case creation to first task or event) | No |
| EventLeadFirstActivity | Inactive (37.0) | Event | after insert | logic inline | Lead Time_to_First_Response__c (hours from created or assigned date to first activity) | No |
| EventNotifyCTI | **Active** (37.0) | Event | after insert, after update | logic inline (**empty**: `NotifyCTI.sendUpdate('event')` is commented out) | No-op | n/a |
| EventTrigger | **Active** (67.0) | Event | before insert, after insert, after update | `EventHandler` (handleUpdateUserRole, handleCaseFirstActivity, handleLeadFirstActivity, handleConvertLead) | Consolidated Event logic that replaces EventUpdateUserRole, EventCaseFirstActivity, EventLeadFirstActivity and ConvertLead (bulkified) | No (static methods, no guard). `handleConvertLead` runs on every after update |
| EventUpdateUserRole | Inactive (41.0) | Event | before insert | logic inline | Stamps the owner's role and profile name into Event User_Role__c / User_Profile__c | No |
| LeadOutcomeUpdated | Inactive (48.0) | Lead | after update | logic inline, calls `OdieWrapper.updateFormDisposition` | Syncs Lead_Outcome__c changes to ODIE | Yes (`checkTriggerRecursion.canRun`) |
| LeadOwnerUpdated | Inactive (48.0) | Lead | after update | logic inline, calls `OdieWrapper.syncLeadOwnerToOdieFuture` | Syncs owner changes to ODIE when EqLeadUuid__c is set | Yes (`checkTriggerRecursion`) |
| LeadTrigger | **Active** (59.0) | Lead | before insert, before update, after insert, after update | `LeadHandler` (extends `TriggerHandler`) | Consolidated Lead logic: lead score default (gated by Trigger_Setting__mdt), MobilePhone = Phone, reset call fields when Lost, round-robin (`etcd8_RRLeadAssignment`), Life lead ODIE sync, converted-lead Referral__c update, ODIE owner/outcome sync | Partial. The TriggerHandler framework supports bypass and max loop count (none set). `checkTriggerRecursion` guards MobilePhone sync, owner sync and outcome sync |
| LifeLeadCreated | Inactive (45.0) | Lead | after insert | logic inline, calls `OdieWrapper` futures | Creates ODIE records for Life leads created in Salesforce, or syncs their owner. Record type ID is hard-coded | No |
| OpportunityLineItemTrigger | Inactive (60.0) | OpportunityLineItem | after insert, after update, after delete | logic inline | Rolls up DOCUSIGN_Ad_Spend_Amount__c and DOCUSIGN_Marketing_Services_Products__c onto the Opportunity | No |
| OpportunityLineTrigger | **Active** (67.0) | OpportunityLineItem | after insert, after update, after delete | `OpportunityLineItemHandler.recalculateOpportunityAmounts` | Same rollup as OpportunityLineItemTrigger (migrated copy) | No |
| OpportunityTrigger | Inactive (40.0) | Opportunity | before/after insert, update, delete | `OpportunityTriggerHandler.createNewOppWhenClose` (onboarding methods commented out) | When an Enrichment opp is Closed Won or Lost, creates a follow-up opp | No |
| ResetLeadWhenLost | Inactive (39.0) | Lead | before update | logic inline | Clears GateKeeperCallCount__c, DMCallCount__c and LastCallDispo__c when Status = Lost | No (before-save only) |
| TaskCaseFirstActivity | Inactive (36.0) | Task | after insert | logic inline | Case Time_to_First_Response__c | No |
| TaskLead | Inactive (45.0) | Task | after insert | logic inline | Inbound call task assigns the Lead owned by Inbound Life Queue to the task owner. User and queue IDs are hard-coded | No |
| TaskLeadFirstActivity | Inactive (37.0) | Task | after insert | logic inline | Lead Time_to_First_Response__c | No |
| TaskNotifyCTI | Inactive (37.0) | Task | after insert, after update | logic inline, calls `NotifyCTI.sendUpdate('task')` | CTI notification | No |
| TaskSetReminder | Inactive (37.0) | Task | before insert, before update | logic inline | Copies ReminderDateTime to ReminderDateTime__c | No |
| TaskTrigger | **Active** (67.0) | Task | before insert, before update, after insert, after update | `TaskHandler` (updateUserRoleAndProfile, setReminderDateTime, assignLeadOwnerOnFirstCall, notifyCTI) | Consolidated Task logic that replaces TaskUpdateUserRole, TaskSetReminder, TaskLead and TaskNotifyCTI. Looks up the queue and integration user by name rather than by ID | No |
| TaskUpdateUserRole | Inactive (41.0) | Task | before insert | logic inline | Stamps the owner's role and profile into Task User_Role__c / User_Profile__c | No |
| UpdateCaseFromTask | Inactive (39.0) | Task | after insert | logic inline | Case Last_Call_Time__c | No |
| UpdateLeadMobilePhone | Inactive (48.0) | Lead | before insert, before update | logic inline | MobilePhone = Phone (used by Twilio SMS) | Yes (`checkTriggerRecursion`) |
| UpdateOppFromEvent | Inactive (39.0) | Event | after insert, after update, after delete | logic inline | Opportunity last_call_time__c, Call_Count__c, next_due_date__c | No |
| UpdateOppFromTask | Inactive (39.0) | Task | after insert, after update, after delete | logic inline (final `update opp;` is commented out, so it writes nothing) | Same as above, from Task | No |
| UpdateReferral | Inactive (39.0) | Lead | after update | logic inline | On conversion, points Referral__c records at the converted Account, Contact and Opportunity | No |
| VoiceCallTrigger | **Active** (60.0) | VoiceCall | before insert, before update | `AutoPopulateContactOnVoiceCall` | Matches To/From phone numbers to Contact Phone/MobilePhone and sets VoiceCall Contact__c / Account__c | No (before-save only) |
| etcd8_LeadTrigger | Inactive (29.0) | Lead | before update | `etcd8_RRLeadAssignment.OnBeforeUpdate` | eightCloud round-robin assignment for leads owned by the queue named "Unassigned" | No |

## Triggers per object

Salesforce does **not** guarantee the order in which multiple triggers on the same object and event run. Every object below has more than one trigger in source.

| Object | Triggers (Active in bold) | Notes |
|---|---|---|
| Task (11) | **TaskTrigger**, AggregateCall, ChangeOwnerAfterSpokeDM, TaskCaseFirstActivity, TaskLead, TaskLeadFirstActivity, TaskNotifyCTI, TaskSetReminder, TaskUpdateUserRole, UpdateCaseFromTask, UpdateOppFromTask | Only TaskTrigger is active. Reactivating TaskLead, TaskNotifyCTI, TaskSetReminder or TaskUpdateUserRole would duplicate TaskHandler logic, for example double CTI callouts. |
| Lead (9) | **LeadTrigger**, ConvertLeadWhenIMHeld, LeadOutcomeUpdated, LeadOwnerUpdated, LifeLeadCreated, ResetLeadWhenLost, UpdateLeadMobilePhone, UpdateReferral, etcd8_LeadTrigger | Only LeadTrigger is active. The inactive triggers duplicate LeadHandler methods. ConvertLeadWhenIMHeld is **not** in LeadHandler, so leads flagged IMHeld__c by EventHandler are no longer auto-converted. |
| Event (8) | **EventTrigger**, **EventNotifyCTI**, ConvertLead, DueDate, EventCaseFirstActivity, EventLeadFirstActivity, EventUpdateUserRole, UpdateOppFromEvent | **2 active triggers on Event.** EventNotifyCTI is empty, so there is no functional conflict today, but it should be deleted or merged into EventTrigger. |
| Opportunity (2) | **CreateNewOppWhenClose**, OpportunityTrigger | The active trigger is a no-op because its code is commented out. The real logic in OpportunityTrigger/OpportunityTriggerHandler is inactive. |
| OpportunityLineItem (2) | **OpportunityLineTrigger**, OpportunityLineItemTrigger | Identical rollup logic. If both were active, the parent Opportunity would be updated twice. |
| VoiceCall (1) | **VoiceCallTrigger** | n/a |

## Inline-logic triggers (no handler class)

These triggers put their business logic directly in the trigger body: AggregateCall, ChangeOwnerAfterSpokeDM, ConvertLead, ConvertLeadWhenIMHeld, CreateNewOppWhenClose (commented), DueDate, EventCaseFirstActivity, EventLeadFirstActivity, EventNotifyCTI (empty), EventUpdateUserRole, LeadOutcomeUpdated, LeadOwnerUpdated, LifeLeadCreated, OpportunityLineItemTrigger, ResetLeadWhenLost, TaskCaseFirstActivity, TaskLead, TaskLeadFirstActivity, TaskNotifyCTI, TaskSetReminder, TaskUpdateUserRole, UpdateCaseFromTask, UpdateLeadMobilePhone, UpdateOppFromEvent, UpdateOppFromTask, UpdateReferral.

All of them are **Inactive** except CreateNewOppWhenClose and EventNotifyCTI, which are active but contain no executable code. Most of the inactive ones also run SOQL or DML inside `for` loops and are not bulk-safe.

## Observations and risks

- **Hard-coded IDs in trigger code (all in inactive or commented code):**
  - ChangeOwnerAfterSpokeDM: users `0051a000001UvIRAA0` and `0051a000002RkQgAAK`.
  - TaskLead: user `0051a000002j8TUAAY` and queue `00G2g000000HbBiEAK`.
  - LifeLeadCreated: record type `0121a000000VlZ7AAK`.
  - CreateNewOppWhenClose (comments): record type `0121a000000VlQPAAO`.
  - The active handlers resolve these by DeveloperName or Username instead.
- **`checkTriggerRecursion` is "run once per transaction":**
  - It keeps a static list of identifiers. In LeadHandler, the ODIE owner and outcome sync and the MobilePhone sync run only the first time they are called in a transaction.
  - A second pass is skipped. That covers a second 200-record chunk, a workflow field update that re-fires the update trigger, and an insert followed by an update in the same transaction.
  - Example: a Lead owner change made by a workflow field update (Recycle Lost Leads, Unqualified queues, Duplicate Queue) re-fires after update with the guard already used, so it **will not be synced to ODIE**.
- **Round-robin depends on a queue named exactly `Unassigned`:**
  - `etcd8_RRLeadAssignment` (called by LeadHandler.beforeUpdate) queries `QueueSobject WHERE Queue.Name = 'Unassigned'`.
  - None of the 103 queues in source has that label. The closest are the "Unassigned Queue - ..." and "Unassigned ..." queues. If the queue does not exist in the target org, round-robin does nothing.
- **Several automations write Lead.OwnerId:**
  - EventHandler.handleConvertLead.
  - TaskHandler.assignLeadOwnerOnFirstCall.
  - LeadHandler (round-robin).
  - Two active Task flows (see Flows README).
  - Five active Lead workflow rules (queue assignments).
- **EventHandler.handleConvertLead runs on every Event update.** Editing an "Initial Meeting / Held - Correct Contact" event resets the Lead owner to the event owner each time.
- **VoiceCallTrigger:** `AutoPopulateContactOnVoiceCall.comparePhoneNumber` calls `FromPhoneNumber.substring(2)` when only ToPhoneNumber is checked for blank. A VoiceCall with a To number but no From number would throw a NullPointerException.
- **Clean-up candidate:** 26 inactive triggers plus 2 active no-op triggers. Deleting them needs a destructive deployment (destructiveChanges.xml).
