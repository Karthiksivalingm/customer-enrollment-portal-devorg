# Utilities & Test Framework

## TriggerHandler

- **Purpose:** Virtual base class for trigger handlers (Kevin O'Hara pattern). Used by `LeadHandler` and `LeadTriggerHandler`. Task/Event/Opportunity/OLI/VoiceCall handlers do **not** use it.
- **Public API:** `run()`, `setMaxLoopCount(Integer)`, `clearMaxLoopCount()`, static `bypass(String)`, `clearBypass(String)`, `isBypassed(String)`, `clearAllBypasses()`.
- **Overridable:** `beforeInsert`, `beforeUpdate`, `beforeDelete`, `afterInsert`, `afterUpdate`, `afterDelete`, `afterUndelete`.
- **Behaviour:** throws `TriggerHandlerException` when run outside trigger context or when the configured max loop count is exceeded (only when `setMaxLoopCount` was called; default unlimited). Handler name from `toString()`.
- **Test:** TriggerHandlerTest.

## checkTriggerRecursion

- **Purpose:** Per-transaction "run once" guard. `static Boolean canRun(String identifier)` returns true the first time an identifier is seen; `static void reset()` clears.
- **Used by:** LeadHandler (`UpdateLeadMobilePhone`, `LeadOwnerUpdated`, `LeadOutcomeUpdated`).
- **Risk:** Never reset in production code → only the first 200-record trigger chunk / first Lead DML in a transaction gets processed for those identifiers.
- **Test:** TestCheckTriggerRecursion (also used in LeadHandlerTest / TestUpdateLeadMobilePhone).

## Rider

- `@AuraEnabled` DTO: `product` (String), `amount` (Integer), `units` (Integer). No logic; no direct test. Referenced only by ODA classes (ODALeadController, OdaQuoteRequestData and their tests).

## Test utilities

| Class | Purpose |
|---|---|
| DataFactory (`@isTest`) | `buildAccount(name)`, `buildOpportunity(name, acctId, recordTypeName)` (Stage `Open`, LeadSource `Outbound Call`), `setOnboardingDefaults()` → upserts `OnboardingSettings__c.RecordType__c = 'Agency'` |
| MockHttpResponseGenerator (`@isTest`) | HttpCalloutMock for cheat-sheet familiar-names endpoints (see Cheatsheets.md) |
| ThrowingDeleteFaliureCasesBatch (`@isTest`) | Subclass of DeleteFaliureCasesBatch whose `performDelete` throws, to cover the catch block |
| testAutomationRuntime | Tests "Process Automation Tracking" package: inserts `Process_Automation__c` (`Type__c`), runs flow `Create_Automation_Runtime`, asserts `Automation_Runtime__c.Process_Automation__c` |

## Test-class inventory & quality notes

| Concern | Classes |
|---|---|
| `SeeAllData=true` | OpportunityLineItemTriggerTest, all 10 community/site controller tests |
| Hardcoded org Ids | LeadHandlerTest L20 & LifeLeadCreatedTest L49 (`0121a000000VlZ7AAK`), TaskLeadTests L16–18 (`0051a000002j8TUAAY`, `00G2g000000HbBiEAK`, `00G1a000001WCo7EAG`), TestCreateNewOppWhenClose L13 (`0121a000000RNO1AAO`), OpportunityLineItemTriggerTest L6 (`0064z00002BsuUiAAJ`), EventHandlerTest L106 (`005000000000000`, dummy) |
| No assertions | TestCreateNewOppWhenClose, TestAutoPopulateContactOnVoiceCall, TestAggregateCall, TestTaskSetReminder, TestUpdateCase, TestConvertLead, TestResetLeadWhenLost, `unsubscribe` inline tests |
| Depend on org data/metadata | jrsl_ul_UnsubscribeLinkTest (mdt record), jrsl_ul_Unsubscribe*Test (flows), testAutomationRuntime (flow), AssignLeadToCadences* (labels/flow) |
| Main classes with **no** test | CrossUpsellInfoController, LeadTriggerHandler (dead code), Rider (no logic) |
| Tests that may fail vs. source metadata | OpportunityTriggerHandlerTest / TestCreateNewOppWhenClose (OpportunityTrigger is Inactive in source) |
| Custom fields only seen in tests | `User.Odie_Agent_ID__c`, `Opportunity.of_Apps__c`, `Lead.Traffic_Source__c`, `Process_Automation__c.Type__c`, `Automation_Runtime__c.Process_Automation__c` |
