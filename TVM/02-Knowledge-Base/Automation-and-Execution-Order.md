# Automation and Execution Order

Built from the retrieved source (`force-app/main/default/`, retrieved 2026-10-14). Statements marked **INFERENCE** come from names or
partial reading, not verified behaviour. Full lists: [Apex-Triggers](../07-Technical-Documents/Metadata-Inventory/Apex-Triggers.md),
[Flows](../07-Technical-Documents/Metadata-Inventory/Flows.md), [Apex-Classes](../07-Technical-Documents/Metadata-Inventory/Apex-Classes.md),
[Automation-Rules](../07-Technical-Documents/Metadata-Inventory/Automation-Rules.md).

## 1. Scale
- **620 Flows:** 428 autolaunched, 169 screen, 16 routing, 7 survey. By status: 483 Active, 91 Obsolete, 42 Draft, 4 InvalidDraft.
  - By trigger: 223 after-save, 27 before-save, 7 before-delete, 96 scheduled.
  - Of the 257 record-triggered Flows, 220 are Active.
- **20 Apex triggers** on 12 objects. Several objects have more than one trigger, so their relative order is not guaranteed:
  Account (2), Case (2), Contact (2), ContentDocumentLink (2), OpportunityLineItem (3).
- **No org-wide trigger framework.**
  - Three triggers (Attachment, Case, ContentDocumentLink) use `TriggerUtil.needToRunTrigger()` with static Id-set guards.
  - The others call a handler, or hold their logic in the trigger body.

## 2. Objects with both Apex triggers and record-triggered Flows (Active)

| Object | Triggers | Before-save Flows | After-save / delete Flows |
|---|---|---|---|
| Opportunity | OpportunityContractFileTrigger (au) | 5, e.g. `Opportunity_Created`, `Opportunity_Updated_Fast` | 51 after-save (e.g. `Create_onboarding`, `Opportunity_Lock_Opp`, `Update_MRR_and_ARR_on_Account_from_Opportunity`, 7 `Capture_Date_for_*`), plus before-delete `Opportunity_Deleted` |
| Case | CaseTrigger (bd), CaseTrigger_FNDN (bi, ai, bu, au) | 7, e.g. `Case_Assignment_Process`, `Case_Skill_Mapping_for_same_request_types`, `Case_Updated_Before_Save` | 24, e.g. `Case_Created`, `Case_SLA_Time_Calculation`, `Case_Change_Tracking_Audit_Log`, `Track_Agent_to_Agent_Case_Transfers` |
| Account | AccountTrigger (bi, bu), TouchPointAccountUpdateTrigger (au) | `Update_Dealership_Address` | 22, incl. `TP_SYNCv2`, `Account_TP_Sync_Detect_Changes_Build_Payload`, `Account_Change_Tracking_Audit_Log`; plus `Account_Deleted` |
| Contact | ContactTrigger, TouchPointContactUpdateTrigger | `Contact_Do_Not_Sync_with_Pardot`, `Duplicate_Contact` | `Contact_Created`, `Contact_Updated`, `Contact_Created_Updated_Reflag`, `Contact_Do_Not_Sync_with_Pardot_Uncheck` |
| OpportunityLineItem | OpportunityLineItemTrigger, OpportunityProductTrigger, create_OppProduct_History | `Opportunity_Product_Created_Before_Save` | `Opportunity_Product_Created_After_Save`, `Update_FD_Agency_Fee_ARR_and_Exclude_Flag`, `Opportunity_Product_Deleted` |
| Foundation_Onboarding__c | OnboardingTrigger | `Update_Onboarding_from_account_rpm_and_technician` | 14 |
| Monthly_Budget__c | TouchPointBudgetUpdateTrigger | — | 7 (e.g. `Monthly_Budget_CreatedUpdated`, `Update_Media_Budget_Fields`) |
| User_Story__c | slack_User_Ticket (calls the managed Slack package) | — | `New_Team_V_Ticket_Notification`, `User_Story_Updated` |

Top objects by Active record-triggered Flows:

| Object | Active record-triggered Flows |
|---|---|
| Opportunity | 57 |
| Case | 31 |
| Account | 24 |
| Foundation_Onboarding__c | 15 |
| Monthly_Budget__c | 7 |
| Contact | 6 |
| Onboarding_Package__c | 6 |
| Event | 6 |
| Project_Task__c | 5 |
| OpportunityLineItem | 4 |

**Execution order on save:** Salesforce standard order applies:

1. Before-save Flows.
2. Before triggers.
3. Validation rules.
4. After triggers.
5. Assignment, auto-response and workflow rules.
6. After-save Flows.

Within a group, multiple triggers on one object have **no guaranteed order**. Flows run in order only where a Trigger Order is set.
Any change to Opportunity, Case or Account must first be checked against all the automation listed above for that object.

## 3. Bypass and recursion controls
| Control | Where | Scope |
|---|---|---|
| `Process_Switches__c` hierarchy custom setting: `Account_/Contact_/Auto_Group_/Monthly_Budget_Integration_Bypass__c` | The 4 TouchPoint triggers | Skips TouchPoint callouts. The triggers also skip the "Integration User", and skip runs already in batch or future context |
| `TriggerUtil.needToRunTrigger()` with static Id sets | Attachment, Case (`CaseTrigger`), ContentDocumentLink triggers | Prevents re-entry per record |
| `OnboardingTriggerHandler.isFirstTime` | OnboardingTrigger | Guards one after-update method only |
| `OpportunityLineItemHandler.hasAlreadyRun` | OpportunityLineItemTrigger | Guards `updateOppProducts` only |
| None | CaseTrigger_FNDN, ContactTrigger, OpportunityProductTrigger, create_OppProduct_History, ContentVersionTrigger, ContentDocumentLinkTrigger_FNDN | — |

No custom-metadata trigger switch exists. `TriggerHandler.isFirstTime` and `TriggerUpdate.firstcall` are referenced only by a test.
INFERENCE: they are unused.

## 4. Asynchronous and scheduled Apex
| Area | Classes |
|---|---|
| Case | `CaseAssignmentBatch`, `CaseAssignmentHybridBatch` (via `ScheduleCaseAssignmentBatch`); `CaseStatusUpdateBatch` (via `ScheduleCaseStatusUpdateBatch`); `SLARemainingTimeSendEmailBatch` (via its schedule class); `AutoQACaseScheduler` (creates QA Cases) |
| Account / Opportunity rollups | `AllOppSummaryBatch`, `UpdateMRRARRBatch`, `UpdateAccountFromOpportunityBatch`, `mediaBudgetFlagOnAccBatch`, `PRCompleteFlagOnAccBatch`, `UpdateOpportunityStatusBatch`, `UpdateOpportunityStageAsLostBatch` (via `UpdateOpportunityStageAsLostSch`), `agency_Fees_UpdateBatch`, `ContactRoleAccountBatch` |
| Onboarding (Foundation) | `AdvertisedPayment`, `ScheduleEmail`, `OnboardingFieldUpdateBatch`, `OnboardingProductFieldUpdateBatch`, `Schedule_Onboarding_Account_Contact1` (CSV export) |
| Users | `UpdateUserOOOBatch` (via `ScheduleUpdateUserOOO`): out-of-office calendar |
| Reports | `ReportsToExternalUsers` (driven by `Reports_To_External_User__mdt`) |
| Salesforce-to-Salesforce | `QueueScheduleProcessDataBatch`: callouts; reschedules itself with `System.scheduleBatch` |
| Files | `DeleteFilesInIntergroupCommObject` (Queueable, from `AttachmentTriggerHelper`) |
| TouchPoint | `@future(callout=true)`: `TouchPointMake{Account,CP,Contact,AutoGroup,Budget}POSTCallout`, `TouchpointAPI`, `TouchpointAGAPI`, `TouchpointCallOut` |

**Scheduled in Fullsandbox (read-only `CronTrigger` query, 2026-10-14):**

| Kind | What is scheduled |
|---|---|
| Scheduled Apex | **Only `ScheduleCaseAssignmentBatch`** (`CaseAssignmentBatch`, cron `0 30 * * * ?`, hourly at :30), plus one Pardot package batch. The other schedulable classes above (`ScheduleCaseStatusUpdateBatch`, `SLARemainingTimeSendEmailBatchSchedule`, `ScheduleUpdateUserOOO`, `UpdateOpportunityStageAsLostSch`, `AutoQACaseScheduler`, `Schedule_Onboarding_Account_Contact1` …) are **not scheduled in this sandbox** |
| Scheduled Flows | 51 active schedules (job type 6). Examples: `Case_Nightly_Flow`, `Opportunity_Daily_Flow`, `Opportunity_Products_Daily_Billing_Check`, `Recurring_Compliance_Batch_1–5`, `Monthly_Compliance_Cleanup_Batch_1–4`, `Client_Interaction_Monthly_Resync_2–7`, `Survey_Deployment_Scheduled*`, `User_Nightly_Flow_Desynch`, `Create_case_based_on_account_fields` |
| Other | About 100 report/dashboard subscriptions (job type A), Experience Cloud sitemap jobs, and platform jobs |

ASSUMPTION: production may have more scheduled Apex. The sandbox copy does not prove what runs in production.

## 5. Entry points
- **Inbound email handlers:** `EmailToCaseReply`, `FetchCoreVital`, `FetchMeetingRecap`, `FetchTaskStatusfrmMail`, `Getting_Response_CSV_Record_Sheet2`.
  INFERENCE: the last four parse inbound email into `Core_Vitals__c`, `Meeting_Recap__c`, task status and CSV responses.
- **No** `@RestResource` or SOAP `webservice` classes.
- **Invocable actions used by Flows:**
  - TouchPoint: `TouchpointAPIInvocable`, `TouchpointAGAPIInvocable`, `TouchpointCallOutInvocable`.
  - Business: `AccandoppProductTypeManager`, `GeocodingService`, `InvoicePDFController`, `OrderConfirmationSend`, `UnlockOpportunity`, `SendBetterEmail*`, `CaseNotesStrip`, `RichTextStrip`.
  - About 27 generic collection-processor utilities.

## 6. Risks seen in code (not reproduced in the org)
- `create_OppProduct_History`:
  - `updateOppList` is re-created inside the loop, so only the last Opportunity is updated in a bulk delete.
  - `oppMap` is built but never used.
- `OpportunityLineItemTrigger`: `updateHybridProductFlag` runs on every event.
- `OpportunityContractFileTrigger` and `ContentVersionTrigger`: SOQL inside loops and hard-coded RecordType Ids.
- `AutoQACaseScheduler`: hard-coded Account and RecordType Ids.
- INFERENCE: Account data may reach TouchPoint by two paths: `TouchPointAccountUpdateTrigger` and the `TP_SYNCv2` / `Account_TP_Sync_*` Flows.

These are recorded so future changes take them into account. They become CF records only when they cause an observed error.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from analysis of the baseline retrieval. |
