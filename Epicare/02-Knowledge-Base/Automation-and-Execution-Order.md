# Automation and Execution Order

Built from the retrieved source (2026-10-15). INFERENCE marks interpretation.
Full lists:
- [Apex-Triggers](../2026-10/07-Technical/Metadata-Inventory/Apex-Triggers.md)
- [Flows](../2026-10/07-Technical/Metadata-Inventory/Flows.md)
- [Apex-Classes](../2026-10/07-Technical/Metadata-Inventory/Apex-Classes.md)
- [Trigger catalog](../2026-10/07-Technical/Apex-Triggers/Trigger-Catalog.md)

## 1. Scale and style
- **Triggers:** 33, all Active.
  - 22 sit on records.
  - 11 subscribe to platform events. The event-driven design is the backbone of the integrations.
- **Apex classes:** 148, of which 73 are tests.
  - 20 batch and 18 schedulable classes, in `XBatch` / `XScheduler` pairs.
  - Queueable callout helpers.
- **Flows:** 22 (19 Active, 3 Draft).
  - 15 record-triggered on Account, Contact, Certification, Payment_Batch, Upline_Policy and Commission_Record.
  - 7 screen Flows.
  - No scheduled Flows and no subflows.
- **No trigger framework and no bypass setting.**
  - `TriggerHandler` holds only two static booleans (`isFirstTime`, `isFirstTime2`).
  - `Contact.Bypass_VR__c` lets `NIPRforFlow` bypass validation rules.
  - `EnrollmentApprovedSubscriberHandler` saves through duplicate rules (`allowSave = true`).

## 2. Objects with both triggers and record-triggered Flows
| Object | Triggers | Record-triggered Flows | Notes |
|---|---|---|---|
| **Contact (agent)** | 6: `AgentCreatedTrigger`, `AgentDeactivatedTrigger`, `ContactEncryptedFieldTrigger`, `ContactHandlerTrigger` (NIPR targets), `ContactInsuranceTrigger`, `ContactTrigger`, `ContactactiveTrigger` | 7: `Agent_Code_Assignment` and `Contact_Sync_Internal` (before-save); `Contact_dob_add`, `Auto_Certifications_Creation`, `Create_NPN_record_from_contact` (after-save); `Delete_NAIC_record_from_contact` (before-delete) | INFERENCE: creating a Contact can register NIPR targets twice. `ContactHandlerTrigger` calls `NIPRAddTargetsHelper`, and the Flow creates a `NAICProducerCode__c` whose trigger enqueues `NIPRAddTargets` |
| **Commission_Record__c** | 5: `CommissionRecordTrigger` (validation, batch roll-up), `ChargebackNotificationTrigger`, `PaymentReconciliationTrigger`, `ReferralRollupTrigger`, `CRAnaReconcileTrigger` | 1 before-save: `Update_Carrier_Name_Commission_Record_object` | Re-fired by the Payment Batch approval Flow |
| **Payment_Batch__c** | 2: `PaymentBatchTrigger` (validate on submit), `CommissionPaidTrigger` (on Paid → publish events) | `Payment_Batch_Approval_Commission_Records` (after-save) | Updates all commission records in the batch, so the 5 Commission_Record triggers run again |
| **Account (agency)** | `AccountHandlerTrigger` (NIPR targets) | 4: `Agency_name_Assignment`, `NPN_Sync_internal`, `Create_NPN_from_Account`, `Delete_NAIC_from_account` | |
| **Upline_Policy__c** | `UplinePolicyTrigger` (publishes `Upline_Policy_Created__e`) | 2 before-save: `Update_Carrier_Name`, `Upline_Policy_Key_Auto_Populate` | |

Other record triggers:
- `AppointmentStatusChangedTrigger`: publishes an event.
  INFERENCE (bug): it reads `Agent__r.NPN__c` from `Trigger.new`, so the value is null.
- `AppointmentTrigger`: its body is entirely commented out.
- `OnboardingChecklistTrigger`, `RenewalScheduleTrigger`, `TriggerNAICProducerCode` (NIPR), `UplineImportCompleteTrigger`.

Salesforce's standard order of execution applies:

1. Before-save Flows.
2. Before triggers.
3. Validation and duplicate rules.
4. After triggers.
5. After-save Flows.

There is **no guaranteed order between the 6 Contact triggers or the 5 Commission_Record triggers.**

## 3. Event-driven integration chain
`record trigger → platform event → event-subscriber trigger → Queueable (callout) → GO AMS / Supabase`

| Platform event | Published by | Subscriber |
|---|---|---|
| `Agent_Created__e` | `AgentCreatedTrigger` (Contact, Agent record type) | `AgentCreatedHelper.sendToGoAMS` |
| `Agent_Deactivated__e` | `AgentDeactivatedTrigger` (status Terminated or Suspended) | `AgentDeactivatedHelper` |
| `Appointment_Status_Changed__e` | `AppointmentStatusChangedTrigger` | `AppointmentStatusChangedHelper` |
| `Commission_Paid__e` | `CommissionPaidTrigger`, `ChargebackNotificationTrigger` | `CommissionPaidHelper` |
| `Upline_Policy_Created__e` | `UplinePolicyTrigger` | `UplinePolicyCreatedEventHandler` (creates `Commission_Record__c`) |
| `Upline_Policy_Import_Completed__e` | `UplineImportCompleteTrigger` (`Commission_Import_Log__c`) | `UplineImportCompleteHelper` |
| `Commission_Exception_Event__e` | `CommissionRecordTriggerHandler` | Inline: inserts `Commission_Exception__c` |
| `Enrollment_Approved__e`, `Appointment_Requested__e`, `EPA_Signed__e`, `Onboarding_Step__e` | External (INFERENCE: GO AMS / the agent portal) | `EnrollmentApprovedSubscriberHandler`; inline inserts of `Appointment__c` and updates of Contact |
| `License_Alert__e` | — | `LicenseAlertHelper` is called from `LicenseAlertBatch` |

## 4. Scheduled and batch processing
- **17 scheduled Apex jobs** in UTDEV: 9 waiting, 8 paused. See [Scheduled-Jobs.md](../2026-10/07-Technical/Scheduled-and-Batch-Jobs/Scheduled-Jobs.md).
- **Main jobs:**
  - Daily policy-year increment.
  - Missing-payment check.
  - NIPR stale check.
  - Onboarding checklist escalation.
  - Monthly agent scorecard and system log export.
  - Payment batch assembly and referral accrual on the 12th.
  - Data retention, driven by `Data_Retention_Rule__mdt`; all its rules are still in `Test_Mode`.
- **Paused:** commission-exception follow-up, daily scorecard, appointment and license alerts, certification and E&O expiry alerts, data retention.

## 5. Rules
- **Duplicate rules:**
  - `Block_Duplicate_Contact_Email` is active and **blocks** on insert and update.
  - The standard Account, Contact and Lead rules are active with **Allow**.
  - `Referral_Record_Duplicate` is inactive.
- **Matching rules:** Contact email, Referral `External_Id__c`.
- **Empty shells:** assignment, auto-response and escalation rules for Case and Lead exist with 0 entries.
- **Validation rules:** 24 in total, several of them segregation-of-duties and activation gates. See [Data-Model-and-Relationships.md](Data-Model-and-Relationships.md).

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from analysis of the baseline retrieval. |
