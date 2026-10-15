# Lead Assignment & Round Robin

Four independent round-robin mechanisms exist:

| Mechanism | Class | Trigger point | State store |
|---|---|---|---|
| Generic group round robin | roundRobinAssigner | Flow / Process (invocable) | `RoundRobin__c` (custom setting) |
| Weighted advisor lead assignment | roundRobinLeadAssigner | Flow / Process (invocable) | `User.Oda_timestamp_last_ob_lead_assigned__c`, `User.ODA_HnF_Weight__c` |
| Unassigned-queue lead rotation (eightCloud 2014) | etcd8_RRLeadAssignment + etcd8_LeadRecipientController | Lead before update (LeadHandler) | `etcd8_LeadRecipient__c.nextUp__c` |
| CSR onboarding rotation (OpFocus 2018) | OnboardingOwnerAssignmentCtrl | VF page only (trigger logic commented out) | `Customer_Success_Rep__c.NextUp__c` |

---

## roundRobinAssigner

- **Purpose:** Assign any SObject (Opportunity, Case, …) to the next member of a public Group. Source: open-source package (mshanemc/roundRobinProcessBuilder). `without sharing`.
- **Entry point:** `@InvocableMethod(label='Assign objects') assign(List<RoundRobinAssignment>)`; inputs `groupName` (req), `recordId` (req), `fieldName` (optional, default `OwnerId`).
- **Public helpers:** `getNextIndex`, `recordMatcher`, `nameShortener` (custom setting Name ≤ 38 chars).
- **Objects/fields:** `RoundRobin__c` (`GroupName__c`, `FieldName__c`, `Object__c`, `IndexOfLastUsed__c`, `Name`); `GroupMember` (by `Group.Name`); target record field (dynamic `put`).
- **SOQL/DML notes:** 1 query on `RoundRobin__c`; **GroupMember SOQL inside loop** (cached per group name, so 1 per distinct group); **`insert` inside loop** in `recordMatcher` when a new rule is first seen; `update objectList`, `update RRSettings`.
- **Risks:** Throws `IllegalArgumentException` if group empty. GroupMember order is not explicitly sorted (no ORDER BY) so rotation order is not guaranteed stable. Group members that are sub-groups/roles would be assigned as owner Ids.
- **Test:** roundRobinTests (uses object names `hed__Program_Enrollment__c`, `cd_Advisor__c` only as strings for name-shortener tests).

## roundRobinLeadAssigner

- **Purpose:** Weighted-random assignment of Leads to advisors in a Group licensed in the Lead's state; create follow-up Task; stamp advisor timestamp. `with sharing`. Original implementation kept commented out at top of file (L1–218).
- **Entry point:** `@InvocableMethod(label='Assign Lead') assign(List<RoundRobinLeadAssignment>)`; inputs `groupName`, `leadRecordId`, `leadState`, `firstName`, `lastName`, `trafficSource` (Integer), `phone` (optional).
- **Other public methods:** `updateLeadsOwner(Map<Id,Id>)`, `@Future updateUserOdaTimestampLastObLeadAssigned(List<Id>)`, `loadUsersByGroupAndState`, `randomExtractUser`, `generateRandomList`, `getUserWeight`, `getUsersWeightSum`, `createTask`.
- **Algorithm:** eligible users = active Group members whose `StatesLicensedIn__c LIKE '%ST%'` and NOT `LIKE '%ST*%'`, ordered by `Oda_timestamp_last_ob_lead_assigned__c ASC`; probability = `ODA_HnF_Weight__c / sum`; if total weight 0 → first (least recently assigned) user. Cached per group|state.
- **Writes:**
  - Task: `WhoId`, `Subject` = `'Sage - Hot Lead Assigned, '` when `trafficSource == 950` else `'Sage - Fresh Lead Assigned, '` + name, `ActivityDate` today, `Priority='High'`, `Task_Phone__c`.
  - Lead: `OwnerId` only if `OwnerIsUser__c` is false (i.e., currently queue-owned).
  - User (@future): `Oda_timestamp_last_ob_lead_assigned__c = now()`.
- **Risks:** If any lead in the batch has no eligible advisor, method `return`s and **no** tasks/owners are committed for the whole batch (documented, preserved behaviour). @future call fails if invoked from batch/future context. Inserting Tasks fires `TaskTrigger` → `NotifyCTI` @future (second future call). Wraps errors in `RoundRobinLeadAssignerException`.
- **Test:** roundRobinLeadAssignerTest.

## etcd8_RRLeadAssignment

- **Purpose:** Rotate Leads owned by queue **"Unassigned"** to available recipients. `without sharing`.
- **Entry points:** `OnBeforeUpdate(originalLeads, updatedLeads, oldMap, newMap)` (called from `LeadHandler.beforeUpdate`); `assignRRLeads(List<Lead>, QueueSobject)`.
- **Objects/fields:** `QueueSobject` where `Queue.Name = 'Unassigned'`; `etcd8_LeadRecipient__c` (`user__c`, `available__c`, `nextUp__c`, `user__r.isActive`, ordered by `user__r.lastName`); Lead `OwnerId`, `Lead_Recipient__c`.
- **SOQL/DML:** 1 QueueSobject query on **every** Lead before update (even when no lead is queue-owned), 1 recipient query, 1 update of all recipients.
- **Risks:** Queue looked up by Name `Unassigned` – no queue with that API name exists in `force-app/.../queues` (only `Unassigned_*` variants), so in this source the method may simply return. Next-up logic sets `nextUp__c` in-loop; with several leads the rotation pointer logic is fragile (only first `nextUp__c` record receives a lead per pass).
- **Test:** etcd8_Test_RRLeadAssignment (creates its own "Unassigned" queue in @testSetup).

## etcd8_LeadRecipientController

- **Purpose:** Controller for VF page `etcd8_LeadAssignmentConsole` (page not in this source). `with sharing`.
- **Entry points (page actions):** `queryLeadRecipients()`, `onLoad()` (populateNextUp + populateOpenLeadCount), `save()` (upsert list, fix next-up), `add()` (create recipient for selected user), `getLeadRecipients()`, `populateOpenLeadCount()`.
- **Objects/fields:** `etcd8_LeadRecipient__c` (`user__c`, `available__c`, `nextUp__c`, `openLeads__c`, `User_Role__c`); child relationship `Leads__r` (Lead where `IsConverted = false`); User (`UserRole.Name`).
- **Risks:** `populateOpenLeadCount` queries **all** recipients with child Leads subquery and updates all on every page load (heap/row limits as leads grow). `getLeadRecipients` LIMIT 5000.
- **Tests:** etcd8_Test_LeadRecipientController, etcd8_Test_RRLeadAssignment.

## OnboardingOwnerAssignmentCtrl

- **Purpose:** VF console to manage Customer Success Reps for onboarding rotation. `with sharing`. (OpFocus, Feb 2018.)
- **Entry points:** `queryLeadRecipients()`, `onLoad()`, `save()`, `add()`, `getLeadRecipients()` (Map by `Onboarding_Type__c`, 'Unassigned' bucket), `populateOpenLeadCount()`; inner `OnboardingSetupException`.
- **Objects/fields:** `Customer_Success_Rep__c` (`User__c`, `Available__c`, `NextUp__c`, `Onboarding_Type__c`, `OpenOpps__c`, `User_Role__c`); child `Opportunities__r`; User where `UserRole.Name = 'Customer Support Rep'` and active (added as unsaved rows).
- **Validation:** `save()` throws "Onboarding Type is required for available CSRs".
- **SOQL/DML:** **`upsert` inside loop** over map values (one DML per onboarding type). `populateOpenLeadCount` counts *all* related opps (not only open) and updates all CSRs on each load.
- **Note:** The trigger-side consumer (`OpportunityTriggerHandler.assignOnboardingOwner`) is commented out, so `NextUp__c` is maintained but not consumed by Apex.
- **Test:** OnboardingOwnerAssignmentCtrlTest.
