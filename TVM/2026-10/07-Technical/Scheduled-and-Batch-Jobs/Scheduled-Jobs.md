# Scheduled, Batch and Asynchronous Jobs

Source classes: [Apex inventory](../Metadata-Inventory/Apex-Classes.md). The scheduled state comes from a read-only
`CronTrigger` query on Fullsandbox, 2026-10-14.

## Scheduled Apex (CronTrigger job type 7)
| Job name | Class | Cron | State |
|---|---|---|---|
| CaseAssignmentBatch | `ScheduleCaseAssignmentBatch` → `CaseAssignmentBatch`, `CaseAssignmentHybridBatch` | `0 30 * * * ?` (hourly at :30) | WAITING |
| pi_Batch_Delete_EngageCampaignRecipients_* | Pardot managed package | one-off | WAITING |

## Schedulable classes in source that are **not scheduled** in Fullsandbox
`ScheduleCaseStatusUpdateBatch` (→ `CaseStatusUpdateBatch`), `SLARemainingTimeSendEmailBatchSchedule` (→ `SLARemainingTimeSendEmailBatch`),
`ScheduleUpdateUserOOO` (→ `UpdateUserOOOBatch`), `UpdateOpportunityStageAsLostSch`, the schedule class for `UpdateOpportunityStatusBatch`,
`AutoQACaseScheduler`, `Schedule_Onboarding_Account_Contact1`, and the schedulable batches `AdvertisedPayment`, `ScheduleEmail`,
`agency_Fees_UpdateBatch`, `mediaBudgetFlagOnAccBatch`, `PRCompleteFlagOnAccBatch`, `ReportsToExternalUsers`.
Whether production schedules them is **not determined**.

## Other batch and queueable Apex
| Class | Kind | Started by |
|---|---|---|
| `AllOppSummaryBatch`, `UpdateMRRARRBatch`, `UpdateAccountFromOpportunityBatch`, `ContactRoleAccountBatch`, `OnboardingFieldUpdateBatch`, `OnboardingProductFieldUpdateBatch` | Batch | Manual or other code. TO BE CONFIRMED |
| `QueueScheduleProcessDataBatch` | Batch with callouts; reschedules itself with `System.scheduleBatch` | Not in CronTrigger at query time |
| `DeleteFilesInIntergroupCommObject` | Queueable | `AttachmentTriggerHelper` |
| TouchPoint callout classes, `SendBetterEmail` | @future | Triggers and Flows |

## Scheduled Flows (CronTrigger job type 6)
**51 active schedules.** Daily or nightly unless stated. Examples:

| Area | Flows |
|---|---|
| Case | `Case_Nightly_Flow`, `Create_case_based_on_account_fields`, `Create_case_when_Day_after_last_day_of_service_is_today`, `Create_case_when_opp_cancellation_received_and_last_day_of_service_Today`, `Case_Google_Verification_Expiration_Case_Creator`, `Create_a_case_for_Monthly_Search_Terms_Audit`, `Close_PR_cases_if_opp_stage_is_lost` |
| Opportunity | `Opportunity_Daily_Flow`, `Opportunity_Products_Daily_Billing_Check`, `Opportunity_Try_Buy_Review`, `Update_opp_stage_as_live_from_onboarding_dates_is_today`, `Update_opportunity_stage_as_lost_and_account_inactive_on_last_day_of_service_is` |
| Account | `Account_Daily_Update_Active_Only`, `Account_Pit_Crew_Scheduled`, `Account_Scheduled_Onboarding_Reset`, `Count_Days_Since_Last_PR_Closed` |
| Compliance | `Recurring_Compliance_Batch_1`–`5`, `Monthly_Compliance_Cleanup_Batch_1`–`4`, `Compliance_Request_Monthly_Release` |
| Client interaction | `Client_Interaction_Monthly_Resync_2`–`7`, `Client_Interaction_Mass_Trigger_Recalc` |
| Other | `Survey_Deployment_Scheduled*` (3), `User_User_Nightly_Flow`, `User_Nightly_Flow_Desynch`, `Event_Nightly_Flow`, `Event_Nightly_Flow_2`, `Meeting_Recap_Nightly_Flow`, `Auto_Group_Nightly_Flow`, `Rush_Request_Scheduled_Flow`, `Project_Task_Nightly_Flow`, `Onboarding_Package_Nightly_Flow`, `Onboarding_Scheduled`, `Sales_Activity_Scheduled`, `Full_Service_Creative_Request_Nightly_Flow`, `Follow_Up_Daily_Flow`, `Email_Contact_Updated_Scheduled`, `Task_Expiration` |

## Other scheduled work
About 100 report and dashboard subscriptions (job type A), Experience Cloud sitemap jobs, and Salesforce platform jobs.

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-14 | Created from the CronTrigger query and source | — |
