# Technical Architecture and Dependencies

Built from retrieved source (2026-10-15). INFERENCE marks interpretation.

## Layers
```
Users: Broker Support · Commissions · Contracting · Executive (profiles, PSGs, roles CEO → COO → …)
   │  Lightning app "Epicare Insurance" · 50 record/home pages · screen Flows (onboarding, notes, products, payment batch)
   ▼
Declarative: 15 record-triggered Flows (Account, Contact, Certification, Payment_Batch, Upline_Policy, Commission_Record)
             24 validation rules (activation gates, segregation of duties) · duplicate rules (block duplicate Contact email)
   ▼
Apex:  22 record triggers → handlers (commissions, reconciliation, referrals, NIPR targets, onboarding)
       11 platform-event subscriber triggers → Queueable callout helpers (GoAMSRetryUtil)
       38 batch/schedulable classes (17 jobs scheduled) · NIPR @future / Aura / LWC / invocable entry points
   ▼
Data:  Contact (Agent) & Account (Agency) hub → licensing (DOI/LOA/License) · contracting (Carrier/Product/Appointment)
       · commissions (Import Log → Upline Policy → Commission Record → Payment Batch) · referrals · governance
   ▼
External: GO AMS / Supabase (callout:EventAPI + inbound platform events) · NIPR PDB (Basic auth, custom labels)
```

## Critical dependencies
| Component | Depends on | Impact of change |
|---|---|---|
| Commission pipeline | `Upline_Policy__c` → `Upline_Policy_Created__e` → `UplinePolicyCreatedEventHandler` → `Commission_Record__c` (5 triggers) → `Payment_Batch__c` approval Flow → `Commission_Paid__e` → GO AMS | A change at any step affects payouts. Test bulk import, approval and the event chain end to end |
| Payment approval | Flow `Payment_Batch_Approval_Commission_Records`; rule `Approver_not_equal_to_Submitter`; owner-based sharing for the approver role | The Flow re-fires every Commission_Record trigger for each record in the batch. Watch limits on large batches |
| Agent activation | Contact validation rules (`EO_Required_for_Activation`, `NPN_Required`, `Onboarding_Forward_Only`), certifications, `Certification_Gate_Settings__mdt`, appointment Ready-to-Sell rules | Gate logic is spread across rules, Flows and triggers |
| NIPR | Custom labels (URLs and credentials, CON-002), remote sites, `NAICProducerCode__c` triggers and Flows on Account and Contact | Credential rotation breaks NIPR until labels are replaced. Beta and production hosts both exist |
| GO AMS | Named credential `EventAPI`, external credential `SF_Event_OAuth` (principal access through permission sets), integration profiles | Credential and permission changes stop event delivery. 4xx errors go to `Error_Log__c` |
| Data retention | `Data_Retention_Rule__mdt` (Test_Mode), `DataRetentionEnforcement` batch (paused) | Turning off Test_Mode or resuming the job **deletes records** |

## Where to look before changing something
1. [Metadata-Inventory](../2026-10/07-Technical/Metadata-Inventory/README.md)
2. [Automation-and-Execution-Order.md](Automation-and-Execution-Order.md)
3. [Integrations-and-External-Systems.md](Integrations-and-External-Systems.md)
4. [Security-and-Permissions.md](Security-and-Permissions.md)
5. [Known-Constraints.md](Known-Constraints.md)

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from analysis of the baseline retrieval. |
