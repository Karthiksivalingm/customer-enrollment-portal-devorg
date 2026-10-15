# Batches & Schedulers

No cron expressions are scheduled from main Apex code. Scheduled-job registrations (Setup → Scheduled Jobs) are not in source; only test cron strings exist:
- `UpdateFillRateBatchTest`: `'0 0 22 ? * 6 *'` (Friday 22:00) for `FillRateBatchScheduler`.
- `deleteOldConversationBatchAndSchedular`: one-time cron +5 min for `ConversationEntryBatchScheduler`.
- `ConversationEntryBatchScheduler.sched = '0 00 00 * * ?'` (daily midnight) is declared as a public static string but not used to self-schedule.

| Scheduler | Batch | Scope |
|---|---|---|
| AssignLeadToCadencesBatchScheduler | AssignLeadToCadencesBatch(null) | 1 (not executed when `Test.isRunningTest()`) |
| ConversationEntryBatchScheduler | DeleteOldConversationEntriesBatch(query) | 200 |
| FillRateBatchScheduler | UpdateFillRateBatch | 200 |
| – (run manually) | BulkAccountLastOppUpdate, DeleteFaliureCasesBatch, OppToCSUpsellRTUpdate, OppToStateFarmRTUpdate, OpportunityLegacyRecordTypeBatch | default |

---

## AssignLeadToCadencesBatch

- **Purpose:** For each active BDR, fill up to 150 work items by enrolling their carrier's leads into a Sales Engagement cadence. `Database.Batchable<sObject>, Database.Stateful`.
- **Entry points:** constructor `(Id userId)` (null = all BDRs); `start` / `execute` / `finish`; `global static Map<Id,Boolean> checkActivity(Set<Id>)`.
- **start:** Users with `UserRole.Name = 'Core Outbound Business Development Rep'`, `IsActive`, `Carrier__c != null` (optionally `Id = :userId`).
- **execute (per user):** `workItemAmount = 150 – User.Work_Item_Amount__c`; finds `Carrier__c` record whose Name = `User.Carrier__c` (text); Leads where `Carrier__c` = that Id, `DoNotCall != true`, `HasOptedOutOfEmail != true`, `ActionCadenceId = null`, ordered by `mkto71_Lead_Score__c DESC` LIMIT 2000. Eligible if Task/Event/EmailMessage in last 60 days **and** `ScoreIntelligence.Score >= 50` (bypassed in tests). Launches flow **`Assign_lead_to_cadence_from_Apex`** with `cadenceId` = `System.Label.Only_Phone_Cadence_Id` (no email) or `System.Label.Phone_and_Email_Cadence_Id`, `targetId`, `userId`.
- **Objects/fields:** User `Work_Item_Amount__c`, `Carrier__c` (text); `Carrier__c` (object); Lead `Carrier__c`, `mkto71_Lead_Score__c`, `ActionCadenceId`; `ScoreIntelligence`; Task; Event; EmailMessage.
- **Risks:** Only `userList[0]` processed (relies on scope = 1). `carrierList[0].id` is read **before** the size check (L26) → `ListException` if no Carrier matches. `Integer.valueOf(Work_Item_Amount__c)` NPE if null. **`Flow.Interview.start()` inside a loop** – each flow run consumes limits in the same transaction (up to 150 cadence assignments per execute). Cadence Ids are stored in Custom Labels (org-specific Ids). Flow not present in this source.
- **Tests:** AssignLeadToCadencesBatchTest, AssignLeadToCadencesBatchSchedulerTest.

## AssignLeadToCadencesBatchScheduler

- `Schedulable.execute` → `Database.executeBatch(new AssignLeadToCadencesBatch(null), 1)` (skipped in tests, so the test does not run the batch).

## BulkAccountLastOppUpdate

- **Purpose:** One-off/back-fill: set `Account.Last_Opportunity_was_Close_Lost__c = true` where the most recent opp (by `CloseDate DESC`) is `Closed Lost`.
- start: Accounts with flag false + Opportunities subquery. Never sets flag back to false.
- **Risk:** Subquery returns all opps per account (only first needed).
- **Test:** BulkAccountLastOppUpdateTest.

## ConversationEntryBatchScheduler

- **Purpose:** Delete `ConversationEntry` records with `CreatedDate < today-90` via DeleteOldConversationEntriesBatch (scope 200).
- **Risk:** In tests the query is replaced with `SELECT Id FROM Account` (deletes test accounts).
- **Test:** deleteOldConversationBatchAndSchedular.

## DeleteOldConversationEntriesBatch

- Generic: constructor `(String query)`; `execute` → `delete scope` in try/catch (errors only debug-logged). `Database.Stateful` (no state used).

## DeleteFaliureCasesBatch

- **Purpose:** Generic hard-delete of whatever a caller-supplied SOQL returns (name suggests failure Cases). `global virtual`, `Database.Stateful`.
- **Entry points:** constructor `(String query)`, `start`, `execute` (calls `protected virtual performDelete` → `Database.delete(scope, true)`; `DmlException` caught and logged), `finish` (debug "delete Task finished").
- **Risk:** Executes arbitrary query passed by the caller (any object). Deleted records go to Recycle Bin (no `emptyRecycleBin`).
- **Tests:** DeleteFaliureCasesBatchTest, test-support subclass ThrowingDeleteFaliureCasesBatch.

## FillRateBatchScheduler / UpdateFillRateBatch

- **Purpose:** Reset `Account.Uncapped_Fill_Rate__c = null` and `Account.Low_Fill_Rate_Alert__c = false` for Accounts where either is set.
- `Database.update(scope, false)` with per-record error logging; `finish` queries `AsyncApexJob` and logs status. Old implementation kept commented out.
- **Test:** UpdateFillRateBatchTest (also schedules `'0 0 22 ? * 6 *'`).

## OppToCSUpsellRTUpdate

- Opportunity `RecordType.Name = 'Cross-Sell'` AND `Legacy_Record_Type__c = 'Cross-Sell'` → record type **CS Upsell** (queried by Name). If CS Upsell RT not found, sets RecordTypeId null. Test: OppToCSUpsellRTUpdateTest.

## OppToStateFarmRTUpdate

- Opportunity (`Accelerated` with legacy `Accelerated`) OR (`Accelerated-State Farm` with legacy `Accelerated-State Farm`) → record type **Accelerated-AGP**. Test: OppToStateFarmRTUpdateTest.

## OpportunityLegacyRecordTypeBatch

- Opportunity with record type `Agency CS Upsell`, `Cross-Sell` or `Accelerated` and `Legacy_Record_Type__c = null` → `Legacy_Record_Type__c = RecordType.Name`. Must run **before** the two RT-migration batches above (they filter on `Legacy_Record_Type__c`). Test: OpportunityLegacyRecordTypeBatchTest.

**Common risk (migration batches):** plain `update records` (all-or-none per chunk); Opportunity triggers/flows fire on each chunk.
