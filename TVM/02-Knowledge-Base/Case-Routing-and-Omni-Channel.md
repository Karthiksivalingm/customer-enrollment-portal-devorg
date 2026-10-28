# Case Routing and Omni-Channel

Built from the retrieved source (2026-10-14). There are two separate routing mechanisms:

- **Apex round-robin**, driven by `Case_Routing_Config__mdt`, for Foundation and digital-support Cases.
- **Omni-Channel**, for support, priority and voice queues.

INFERENCE marks statements not verified in code.

## 1. Apex round-robin driven by `Case_Routing_Config__mdt`

**Configuration:** 102 active records. Each maps **Request Type** (`Case.Case_Request__c`) + **Hybrid / Non Hybrid** to an initial owner and an after-QA owner.

| Field | Meaning |
|---|---|
| `Request_Type__c` | Key, matched against `Case.Case_Request__c` |
| `Case_Type__c` | Hybrid / Non Hybrid. Chosen by `Account.FNDN_Billed_Through_TVM__c` |
| `Case_Entry__c` | Manual (assigned on insert) / Auto (assigned by the batch) |
| `Initial_Assignment__c`, `Queue__c`, `Field_Name__c` | Queue round-robin, or the user in an Account field (`Account_Technician__c`, `Secondary_Account_Technician__c`, `Account_Technician_Trainee__c`) |
| `Auto_QA_Assignment__c`, `After_QA_Assignment__c`, `QA_Queue__c`, `QA_Field_Name__c` | Reassignment when Status first becomes "Ready for QA" (`QA_Queue__c` is empty in every record) |
| `Campaigns__c` | Enables the Campaigns QA rule |

Record mix:

| Field | Values |
|---|---|
| `Case_Type__c` | 63 Non Hybrid, 39 Hybrid |
| `Case_Entry__c` | 75 Manual, 27 Auto |
| `Initial_Assignment__c` | 82 Queue, 20 Field |
| `Queue__c` | Hybrid, Action, Digital Analyst, Analyze, Digital Coop, Helpware, Helpware/Qualminds, Hybrid Weekly QA |

**Flow of a Case:**

1. `CaseTrigger_FNDN` (before insert) calls `CalculateCaseDueDate.onBeforeInsert`. It runs for Cases with `Foundation_Record__c = true` or
   `Case_Category__c = 'New Digital Support'`, and only when `Case_Assign_To__c` is empty.
2. It loads the active configs and the queue members (Group/GroupMember). **Users with `User.OOO__c = true` are skipped.**
3. It picks the Hybrid or Non Hybrid config from the Account. Then it assigns:
   - **Manual + Queue:** round-robin after the last-assigned user. Sets `Case_Assign_To__c`, `OwnerId` and `Case_Assignment_Queue__c`.
   - **Field:** owner = the Account field's user.
   - **Auto:** only `Case_Assignment_Queue__c` is set.
4. `ScheduleCaseAssignmentBatch` runs `CaseAssignmentBatch` (Non Hybrid) and `CaseAssignmentHybridBatch` (Hybrid). They round-robin
   today's unassigned Auto Cases and set `Status_Filtered__c` from New to Assigned.
   NOT YET VERIFIED: the schedule (`CronTrigger`), which is not in source.
5. On update, `onBeforeUpdate` handles two cases:
   - A change of category to New Digital Support re-runs routing.
   - The first move to "Ready for QA" applies the Campaigns QA rule, then the standard QA rule (QA queue, QA field, or the assignee's manager).
6. Flows on the same path:
   - `Case_Assignment_Process` (before-save, Foundation, configs with Auto QA).
   - `Update_Case_AT_and_Owner` (after-save on create; handles out-of-office account technicians).
   - `Case_SLA_Time_Calculation` (after-save; uses the `SLA_Time_Calculation__c` list setting).

The queues used by this mechanism (Action, Analyze, Digital Analyst, Hybrid …) have **no** Omni routing configuration.

## 2. Omni-Channel

| Item | Detail |
|---|---|
| Queues | 64. 43 support Case (the Morning/Afternoon/Weekend Shift queues also support VoiceCall). 10 are VoiceCall only. Others are for Audit_Log__c, ContactRequest or a managed object, or have no object |
| Routing configurations | High / Medium / Low Priority Case: Most Available, priority 1 / 2 / 3, weight 1 / 1 / 0.5. General_Support_Overflow: priority 100, push timeout 30s. Supervisors_routing_config: 60s. Default_For_Voice: External routing. TVM_Voice_Routing_Config: Least Active |
| Queues using them | Enterprise_Queue and High_Priority_Case_Queue → High priority. Medium/Low queues → their configs. General_Support → overflow. Supervisors queue → supervisors config. 5 voice queues → Default_For_Voice. Voice_Queue → TVM voice config |
| Service channels | Case, Messaging (`sfdc_livemessage`), Phone (`sfdc_phone`) |
| Presence configurations | `TVM_V1`, `default_presence_config`: capacity 10, auto-accept off |
| Routing Flows | `Case_General_Support_Router` (Active; queue-based "Pit Crew" / "Regular Case" branches). Skill-based routing Flows are Obsolete. `Basic_Routing_with_Case_Creation` is a Draft |
| Telephony | Call centers `RingCentral`, `TVMSBCC`; Amazon Connect package (`awsac`); Service Cloud Voice permission sets. See [Integrations](Integrations-and-External-Systems.md) |

## 2a. Skill-based routing (verified 2026-10-22, [ATR-001](../2026-10/08-QA/01-Automated-Testing/ATR-001_Case-Skill-Based-Routing.md))

**What is live:** the before-save Flow `Case_Skill_Mapping_for_same_request_types` (v2, Active) sets `Case.Routing_Skill__c` when a Case
(Category General Support) is created or edited:
- Inventory + Other → Inventory.
- Inventory + VDV Issue → Inventory.
- Onboarding + Other → General.
- Websites - Apollo Apps + VDV Issue → General.

Other combinations leave the field unchanged.

**What is not live:** `Skill_Based_Routing_For_Case`, the Omni-Channel routing Flow that routes by General / Inventory skill and by priority
through the High / Medium / Low routing configurations, has no active version (Obsolete since 2026-07-01).

Skills exist (General, Inventory, English, Spanish, Voice, Enterprise, Red Dealer, Difficult Ticket). 19 active agents hold General and 9 hold
Inventory. Open points are in [CON-001](../2026-10/05-Conflicts/CON-001_Case-Skill-Router-Inactive.md).

## 3. Case configuration

**Record types and business processes:**

| Record type | Status | Business process |
|---|---|---|
| Foundation – Client Services | Active | FND Client Services (8 statuses) |
| Foundation – Measurement | Active | FND Measurement (10 statuses) |
| Foundation – OEM | Active | FND OEM (9 statuses) |
| Foundation – Performance Review | Active | FND Performance Review (5 statuses) |
| Master Record Type | Active | TVM (17 statuses) |
| TVM | Inactive | — |

**Rules and entitlements:**
- Assignment rules and auto-response rules for Case exist but have **no rule entries**.
- Escalation rule "Inactivity for Cases" is **inactive**.
- Entitlement process `standard case` is Active. It has these milestones:
  - First Response to Customer, 240 min. A field update raises Priority to High 60 min before the deadline.
  - Escalate Case, 1440 min.
  - Close Case, 5760 min.

**Email:**
- `EmailToCaseReply` (inbound email handler) threads replies onto Cases by a `|::Id::|` token, or creates a General Support Case.
- `Email_Message_Created_Received` (after-save on EmailMessage) notifies the Case owner, creates an `Internal_External_Note__c` and updates the Case.
- `Email_to_case_case_category_auto_fill` fills the category on new Cases.

**Transfer tracking:** `Track_Agent_to_Agent_Case_Transfers` (after-save on owner change) creates `Case_Transfer__c` records and updates the monthly
`Agent_Transfer_Summary__c`.

**Open questions:**
- `Email_Service_Case_Assignment__c` is not referenced by any Apex, Flow or trigger in source. INFERENCE: it is unused.
- Email-service addresses are not in source, so they can't be checked here.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from analysis of the baseline retrieval. |
| 2026-10-22 | Added skill-based routing findings from ATR-001. |
