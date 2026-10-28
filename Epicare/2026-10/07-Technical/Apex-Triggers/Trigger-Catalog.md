# Apex Trigger Catalog

All 33 unmanaged triggers, as retrieved from UTDEV on 2026-10-15. All are **Active**. Source: [`triggers/`](../../../force-app/main/default/triggers/).
Generated details: [Metadata-Inventory/Apex-Triggers.md](../Metadata-Inventory/Apex-Triggers.md).
Events: b = before, a = after; i = insert, u = update, d = delete, ud = undelete.

## Record triggers
| Object | Trigger | Events | Delegates to / does |
|---|---|---|---|
| Contact | `AgentCreatedTrigger` | ai | Publishes `Agent_Created__e` (Agent record type); writes `Error_Log__c` on failure |
| Contact | `AgentDeactivatedTrigger` | au | Publishes `Agent_Deactivated__e` when status becomes Terminated or Suspended |
| Contact | `ContactEncryptedFieldTrigger` | bi, bu | Copies SSN into the encrypted field |
| Contact | `ContactHandlerTrigger` | ai, au, bd | `NIPRAddTargetsHelper` / `NIPRRemoveTargetsHelper` (@future), `NiprSSNsearch`. Guarded by `TriggerHandler.isFirstTime` |
| Contact | `ContactInsuranceTrigger` | ai, au | `ContactInsuranceHandler.syncInsurance` (creates `Certification__c` and `Onboarding_Checklist__c`) |
| Contact | `ContactTrigger` | bi, bu, ai, au | `ContactTriggerHandler.run` (captive-agent validation, SSN tracking) |
| Contact | `ContactactiveTrigger` | ai, au, ad, aud | `ContactactiveTriggerHandler` (active-agent count on Account) |
| Account | `AccountHandlerTrigger` | ai, bd | NIPR targets add / remove |
| Commission_Record__c | `CommissionRecordTrigger` | bi, bu | `CommissionRecordTriggerHandler.beforeSave`, `CommissionPaymentBatchRollupHandler` |
| Commission_Record__c | `ChargebackNotificationTrigger` | ai | Publishes `Commission_Paid__e` |
| Commission_Record__c | `PaymentReconciliationTrigger` | ai | `PaymentReconciliationHandler` (match key: policy + period + NPN) |
| Commission_Record__c | `ReferralRollupTrigger` | ai, au | `ReferralRollupHandler` |
| Commission_Record__c | `CRAnaReconcileTrigger` | au | `CRAnaReconcileHandler` (commission record for the referral agent) |
| Payment_Batch__c | `PaymentBatchTrigger` | bu | `PaymentBatchTriggerHandler.validateOnSubmit` |
| Payment_Batch__c | `CommissionPaidTrigger` | au | On Paid: aggregates by agent, then `CommissionPaidHelper.publishEvents` |
| Appointment__c | `AppointmentTrigger` | bi, bu, ai, au | **No-op**: body commented out |
| Appointment__c | `AppointmentStatusChangedTrigger` | au | Publishes `Appointment_Status_Changed__e` (parent-field risk) |
| Upline_Policy__c | `UplinePolicyTrigger` | bi, ai, au | `UplinePolicyTriggerHandler`, `UplinePolicyToCommissionHandler` |
| Onboarding_Checklist__c | `OnboardingChecklistTrigger` | ai, au, ad, aud | `OnboardingChecklistTriggerHandler` |
| Renewal_Schedule__c | `RenewalScheduleTrigger` | bi, bu | `RenewalScheduleTriggerHandler.run` |
| NAICProducerCode__c | `TriggerNAICProducerCode` | ai, ad | Enqueues `NIPRAddTargets` / `NIPRRemoveTargets` |
| Commission_Import_Log__c | `UplineImportCompleteTrigger` | ai, au | Publishes `Upline_Policy_Import_Completed__e` |

## Platform-event subscriber triggers (after insert)
| Event | Handler |
|---|---|
| `Agent_Created__e` | `AgentCreatedHelper.sendToGoAMS` |
| `Agent_Deactivated__e` | `AgentDeactivatedHelper` |
| `Appointment_Status_Changed__e` | `AppointmentStatusChangedHelper` |
| `Commission_Paid__e` | `CommissionPaidHelper` |
| `Upline_Policy_Import_Completed__e` | `UplineImportCompleteHelper` |
| `Upline_Policy_Created__e` | `UplinePolicyCreatedEventHandler` |
| `Enrollment_Approved__e` | `EnrollmentApprovedSubscriberHandler` |
| `Commission_Exception_Event__e` | Inline: inserts `Commission_Exception__c` |
| `Appointment_Requested__e` | Inline: inserts `Appointment__c`, updates Contact |
| `EPA_Signed__e`, `Onboarding_Step__e` | Inline: update Contact |

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-15 | Created from the baseline retrieval | — |
