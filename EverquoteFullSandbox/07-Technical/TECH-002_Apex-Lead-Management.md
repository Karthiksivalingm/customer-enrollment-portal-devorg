# Lead Management

Active trigger: `LeadTrigger` (before insert, before update, after insert, after update) → `new LeadHandler().run()`.
The former standalone Lead triggers (`UpdateReferral`, `UpdateLeadMobilePhone`, `LeadOwnerUpdated`, `etcd8_LeadTrigger`, `LifeLeadCreated`, `ResetLeadWhenLost`, `LeadOutcomeUpdated`, `ConvertLeadWhenIMHeld`) are still in source but **Inactive**.

---

## LeadHandler

**Purpose:** Single, bulkified Lead trigger handler that consolidates eight earlier Lead triggers. Extends `TriggerHandler`.

**Entry points (TriggerHandler overrides)**

| Context | Methods called (in order) |
|---|---|
| beforeInsert | `checkLeadScore(…,'LeadBeforeInsert')`, `syncMobilePhoneWithPhone` |
| beforeUpdate | `checkLeadScore(…,'LeadBeforeUpdate')`, `syncMobilePhoneWithPhone`, `resetCallFieldsWhenLost`, `assignRoundRobinLeads` |
| afterInsert | `syncNewLifeLeadsToOdie` |
| afterUpdate | `updateConvertedLeadReferrals`, `syncOwnerChangeToOdie`, `syncOutcomeChangeToOdie` |

**Logic per method**

| Method | Formerly | Behaviour |
|---|---|---|
| checkLeadScore | LeadTrigger → LeadTriggerHandler | Reads `Trigger_Setting__mdt.getInstance(name)`; if record exists and `Is_Active__c`, calls `LeadTriggerHelper.CheckLeadScore`. |
| syncMobilePhoneWithPhone | UpdateLeadMobilePhone | Recursion guard `checkTriggerRecursion.canRun('UpdateLeadMobilePhone')`; sets `MobilePhone = Phone` (comment: Twilio uses MobilePhone for SMS). |
| resetCallFieldsWhenLost | ResetLeadWhenLost | If `Status = 'Lost'` → nulls `GateKeeperCallCount__c`, `DMCallCount__c`, `LastCallDispo__c`. |
| assignRoundRobinLeads | etcd8_LeadTrigger | `new etcd8_RRLeadAssignment().OnBeforeUpdate(...)` (see Lead-Assignment-Round-Robin.md). |
| syncNewLifeLeadsToOdie | LifeLeadCreated | For record type DeveloperName `Life_Leads`: if `EqLeadUuid__c` set → `OdieWrapper.syncLeadOwnerToOdieFuture`; else `OdieWrapper.createRecordsForNewSalesforceLeadsFuture`. |
| updateConvertedLeadReferrals | UpdateReferral | For converted leads, queries `Referral__c` where `Referral__c IN :leadIds`; sets `Referral_Account__c`, `Referral_Contact__c`, `Referral_Opportunity__c` from ConvertedAccount/Contact/OpportunityId; one update. |
| syncOwnerChangeToOdie | LeadOwnerUpdated | Guard `'LeadOwnerUpdated'`; leads with `EqLeadUuid__c` whose OwnerId changed → `OdieWrapper.syncLeadOwnerToOdieFuture`. |
| syncOutcomeChangeToOdie | LeadOutcomeUpdated | Guard `'LeadOutcomeUpdated'`; `Lead_Outcome__c` changed → one `OdieWrapper.updateFormDispositionFuture` call. |

**Objects & fields**
- Lead (read/write): `mkto71_Lead_Score__c`, `LeadSource`, `MobilePhone`, `Phone`, `Status`, `GateKeeperCallCount__c`, `DMCallCount__c`, `LastCallDispo__c`, `EqLeadUuid__c`, `Lead_Outcome__c`, `OwnerId`, `RecordTypeId`, `IsConverted`, `Converted*Id`.
- `Referral__c` (read/update): `Referral__c` (lookup to Lead), `Referral_Account__c`, `Referral_Contact__c`, `Referral_Opportunity__c`.
- `Trigger_Setting__mdt`: records `LeadBeforeInsert`, `LeadBeforeUpdate`; field `Is_Active__c`.
- Record type: Lead `Life_Leads` (by DeveloperName).

**SOQL/DML:** 1 SOQL + 1 DML on `Referral__c` (after update, only if converted leads). Round robin adds 2 SOQL + 1 DML (see etcd8). No SOQL in loops.

**Callouts:** Indirect, via `OdieWrapper` @future methods (ODA/Odie documentation).

**Governor / risks**
- Up to 3 @future calls per after-update transaction (owner, outcome) + 1 per after-insert; @future cannot be called from batch/future context – Lead DML from a batch/future job would throw.
- `checkTriggerRecursion` guards are per-transaction and never reset: on a 200+ record DML (multiple trigger chunks) or a second Lead DML in the same transaction, MobilePhone sync and Odie sync **skip all chunks after the first**.
- `LeadTriggerHandler` (old) duplicates `checkLeadScore`; it is not wired to any trigger.

**Tests:** LeadHandlerTest, LeadTriggerTest, LeadOwnerUpdatedTest, LifeLeadCreatedTest, TestLeadOutcomeUpdated, TestResetLeadWhenLost, TestUpdateLeadMobilePhone. LeadHandlerTest/LifeLeadCreatedTest hardcode Life record type Id `0121a000000VlZ7AAK` (LeadHandlerTest L20, LifeLeadCreatedTest L49).

---

## LeadTriggerHandler

- **Purpose:** Earlier Lead handler (extends `TriggerHandler`) applying the Web Scrape default score.
- **Entry points:** `beforeInsert` (mdt `LeadBeforeInsert`), `beforeUpdate` (mdt `LeadBeforeUpdate`) → `LeadTriggerHelper.CheckLeadScore`.
- **Metadata:** `Trigger_Setting__mdt.Is_Active__c`. No null check on `getInstance` (NPE if record missing).
- **Status:** Not referenced by any trigger (LeadTrigger comment: "LeadTriggerHandler – To be commanded"). Dead code; no test.

## LeadTriggerHelper

- **Purpose:** `public static void CheckLeadScore(List<Lead>)` – if `mkto71_Lead_Score__c == null` and `LeadSource == 'Web Scrape'` → `mkto71_Lead_Score__c = 90`.
- No SOQL/DML. Called by LeadHandler (and LeadTriggerHandler).
- **Tests:** LeadTriggerTest, LeadHandlerTest.

## syncLeadOwnerToOdie

- **Purpose:** Flow/Process invocable to push lead owner to Odie.
- **Entry point:** `@InvocableMethod(label='LeadOwnerSync') sync(List<LeadToSync>)`; input `leadRecordId` (required).
- **Logic:** collects Ids → `OdieWrapper.syncLeadOwnerToOdieFuture(leadsId)`.
- `with sharing`. No SOQL/DML here. Calling flow is not present in this source.
- **Risk:** Same owner sync is also done by `LeadHandler.syncOwnerChangeToOdie` – if the flow fires on owner change, Odie may receive duplicate updates.
- **Test:** syncLeadOwnerToOdieTest.
