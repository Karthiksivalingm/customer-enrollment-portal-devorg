# Architecture and Dependencies

How the TVM org is put together, from the retrieved source (2026-10-14). Detail is in the linked pages. INFERENCE marks interpretation.

## 1. Layers

```
                    ┌──────────────────────────── Users (sales, account technicians, digital analysts, support agents, supervisors)
                    │                              Lightning apps · 205 Lightning pages · 152 layouts · LWC/Aura/Visualforce
                    ▼
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│ Declarative automation: 620 Flows (483 Active), of which 220 are active record-triggered and 51 run on schedules │
│ + workflow rules, approval processes (10), entitlement process, Omni-Channel routing         │
├───────────────────────────────────────────────────────────────────────────────────────────────┤
│ Apex: 20 triggers → handler/helper classes · batch/schedulable/queueable jobs · invocable    │
│ actions for Flows · LWC/Aura controllers · 5 inbound email handlers · TouchPoint callouts    │
├───────────────────────────────────────────────────────────────────────────────────────────────┤
│ Data: Account (dealership) hub → ~20 master-detail custom objects; Opportunity / products;   │
│ Case (support) with 6 record types; 100+ custom objects in ~11 functional areas              │
├───────────────────────────────────────────────────────────────────────────────────────────────┤
│ Configuration: Case_Routing_Config__mdt · Process_Switches__c · SLA_Time_Calculation__c ·    │
│ TouchPoint_Callout__mdt (org only) · labels · global value sets                               │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
        │ outbound                              │ inbound                     │ packages
        ▼                                       ▼                             ▼
  TouchPoint (Quickbase), Slack, Geocoding,   Email services (5)          DocuSign/SpringCM, Pardot, Maps, Jira,
  Salesforce-to-Salesforce (Foundation Direct)                             Gong, Slack, RingCentral, Amazon Connect, Data Cloud …
```

## 2. Main business flows (INFERENCE from metadata, verified where marked)

| Flow of work | Path through the org |
|---|---|
| Sell | Lead → Opportunity (17 record types) with products (`OpportunityLineItem`, discount requests) → DocuSign contract → signed-file handling (triggers) |
| Onboard | Opportunity → Flow `Create_onboarding` (verified) → `Onboarding__c` / `Onboarding_Package__c` / `Foundation_Onboarding__c` → project task groups and tasks, checklists, digital build requests |
| Produce | Creative requests (37 record types), compliance requests and tasks, rush requests, size templates |
| Run campaigns | `Monthly_Budget__c` / `Monthly_Goal__c` / `Sales_Data__c` per Account. Budgets pushed to TouchPoint (verified, active trigger) |
| Support | Case: Apex round-robin (`Case_Routing_Config__mdt`) for Foundation/digital-support requests, and Omni-Channel queues for support and voice. SLA via Flows and an entitlement process |
| Retain and report | Measurements, surveys, client interactions, cancellation/credit requests; scheduled rollups and report subscriptions |

## 3. Critical dependencies

| Component | Depends on | Impact of change |
|---|---|---|
| Case routing (`CalculateCaseDueDate`, `CaseAssignmentBatch*`) | `Case_Routing_Config__mdt` records, queue names (Group Name) and membership, `User.OOO__c`, Account technician fields, `Account.FNDN_Billed_Through_TVM__c` | Renaming a queue or request type breaks routing silently. INFERENCE: no error is raised |
| Account / Opportunity save | 2 Account triggers + 24 active Flows; 1 Opportunity trigger + 57 active Flows | High risk of governor limits and ordering side effects. Test any change with bulk data |
| TouchPoint sync | Inactive triggers, active Flows, hardcoded credentials (CF-001), `TouchPoint_Callout__mdt` | Credential rotation breaks the callouts until the code is changed |
| Salesforce-to-Salesforce sharing | Label `FDConnectionId`, PartnerNetwork connection to the Foundation Direct org | Depends on a live connection in each environment |
| Flows using screen components | Package-owned (no-namespace) LWC/Apex from flow component packages | Not in TVM source; must exist in the target org |
| Email-to-case replies | `EmailToCaseReply` + email-service address (Setup) + hard-coded RecordTypeId | RecordType Ids differ between orgs. Check before deploying elsewhere |

## 4. Where to look before changing something
1. [Metadata-Inventory](../07-Technical-Documents/Metadata-Inventory/README.md): every component with type, object, status.
2. [Automation-and-Execution-Order.md](Automation-and-Execution-Order.md): everything that runs on the object.
3. [Case-Routing-and-Omni-Channel.md](Case-Routing-and-Omni-Channel.md) and [Integrations-and-External-Systems.md](Integrations-and-External-Systems.md).
4. [Security-and-Permissions.md](Security-and-Permissions.md): who can see and do what.
5. [Known-Constraints.md](Known-Constraints.md).

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from analysis of the baseline retrieval. |
