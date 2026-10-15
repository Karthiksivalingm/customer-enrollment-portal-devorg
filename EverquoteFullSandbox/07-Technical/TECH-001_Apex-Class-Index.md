# Apex Classes – Index (non-ODA/Odie scope)

Source: `force-app/main/default/classes` (Everquote Full Sandbox). Business summaries reused from `docs/07-Technical-Documents/Reference-Files/ApexClass_BusinessSummary.csv`; technical detail is from the code.

**Scope:** 111 classes. Classes whose names start with `ODA`, `Oda`, `Odie` or `OdieRequest` are documented separately in [ODA-Quoting-Integration.md](TECH-009_ODA-Quoting-Integration.md). (`OdieWrapper` is called from `LeadHandler` and `syncLeadOwnerToOdie` but is documented with the ODA/Odie set.)

**Type legend:** Main = general logic · Handler = trigger handler · Batch · Schedulable · Controller = Visualforce/page controller · Invocable = `@InvocableMethod` · Email Service = `Messaging.InboundEmailHandler` · Utility · Test.

**Functional area files**

| File | Covers |
|---|---|
| [Lead-Management.md](TECH-002_Apex-Lead-Management.md) | Lead trigger handler, lead score, Odie owner sync |
| [Lead-Assignment-Round-Robin.md](TECH-003_Apex-Lead-Assignment-Round-Robin.md) | roundRobin*, etcd8_*, CSR onboarding rotation |
| [Opportunity.md](TECH-004_Apex-Opportunity.md) | Opportunity / OpportunityLineItem logic, closed-won email, cross-sell |
| [Activities-Task-Event.md](TECH-005_Apex-Activities-Task-Event.md) | TaskHandler, EventHandler |
| [Case-and-Email.md](TECH-006_Apex-Case-and-Email.md) | Email-to-Case email service, missed-call email |
| [Voice-and-CTI.md](TECH-007_Apex-Voice-and-CTI.md) | NotifyCTI, VoiceCall contact matching |
| [Cheatsheets.md](TECH-008_Apex-Cheatsheets.md) | Lead/Opportunity cheat sheet controllers + JSON wrappers |
| [Batches-and-Schedulers.md](TECH-010_Apex-Batches-and-Schedulers.md) | All batch + schedulable classes |
| [Communities-and-Sites.md](TECH-011_Apex-Communities-and-Sites.md) | Standard community/site controllers |
| [Unsubscribe.md](TECH-012_Apex-Unsubscribe.md) | Unsubscribe email service + Unsubscribe Link package |
| [Utilities-and-Test-Framework.md](TECH-013_Apex-Utilities-and-Test-Framework.md) | TriggerHandler framework, recursion guard, DTOs, test utilities, test-class inventory |

---

## Lead Management

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| LeadHandler | Handler | Lead Management | Single Lead trigger handler (score, MobilePhone sync, Lost reset, round robin, referral update, Odie sync). | LeadHandlerTest, LeadTriggerTest, LeadOwnerUpdatedTest, LifeLeadCreatedTest, TestLeadOutcomeUpdated, TestResetLeadWhenLost, TestUpdateLeadMobilePhone |
| LeadTriggerHandler | Handler | Lead Management | Legacy handler applying default lead score; **not called by any trigger** (superseded by LeadHandler). | None (no direct test) |
| LeadTriggerHelper | Utility | Lead Management | Sets `mkto71_Lead_Score__c = 90` for `LeadSource = 'Web Scrape'` leads with no score. | LeadTriggerTest, LeadHandlerTest (via LeadTrigger) |
| syncLeadOwnerToOdie | Invocable | Lead Management | Flow action "LeadOwnerSync" – pushes lead owner to Odie via `OdieWrapper` @future. | syncLeadOwnerToOdieTest |
| LeadHandlerTest | Test | Lead Management | Tests LeadHandler rules and Odie sync paths. | – |
| LeadOwnerUpdatedTest | Test | Lead Management | Owner change sync with/without `EqLeadUuid__c`. | – |
| LeadTriggerTest | Test | Lead Management | Web Scrape default score on insert/update. | – |
| LifeLeadCreatedTest | Test | Lead Management | Life lead creation with/without `EqLeadUuid__c`. | – |
| TestLeadOutcomeUpdated | Test | Lead Management | Lead outcome change. | – |
| TestResetLeadWhenLost | Test | Lead Management | Lost lead reset of call fields. | – |
| TestUpdateLeadMobilePhone | Test | Lead Management | MobilePhone = Phone sync. | – |
| syncLeadOwnerToOdieTest | Test | Lead Management | Invocable Odie owner sync. | – |

## Lead Assignment / Round Robin

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| roundRobinAssigner | Invocable | Round Robin | Flow action "Assign objects": generic round robin of any record to members of a public Group; index stored in `RoundRobin__c`. | roundRobinTests |
| roundRobinLeadAssigner | Invocable | Round Robin | Flow action "Assign Lead": weighted-random advisor pick by group + licensed state; creates Task; stamps user timestamp (@future). | roundRobinLeadAssignerTest |
| etcd8_RRLeadAssignment | Main (handler service) | Round Robin | Assigns Leads owned by queue "Unassigned" to next `etcd8_LeadRecipient__c` (called from LeadHandler before update). | etcd8_Test_RRLeadAssignment |
| etcd8_LeadRecipientController | Controller | Round Robin | Console (etcd8_LeadAssignmentConsole page) to manage lead recipients, availability, next-up, open lead counts. | etcd8_Test_LeadRecipientController, etcd8_Test_RRLeadAssignment |
| OnboardingOwnerAssignmentCtrl | Controller | Round Robin / Onboarding | Manage `Customer_Success_Rep__c` availability, onboarding type, next-up, open opp counts. | OnboardingOwnerAssignmentCtrlTest |
| roundRobinTests | Test | Round Robin | Tests roundRobinAssigner incl. name shortener. | – |
| roundRobinLeadAssignerTest | Test | Round Robin | Tests weighted lead assignment, task, timestamp. | – |
| etcd8_Test_RRLeadAssignment | Test | Round Robin | Unassigned-queue routing. | – |
| etcd8_Test_LeadRecipientController | Test | Round Robin | Recipient console add/save/count. | – |
| OnboardingOwnerAssignmentCtrlTest | Test | Round Robin / Onboarding | CSR save/add/validation. | – |

## Opportunity

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| OpportunityTriggerHandler | Handler | Opportunity | On Enrichment opp Closed Won/Lost, create follow-up "Inactive" opp if none open. | OpportunityTriggerHandlerTest, TestCreateNewOppWhenClose |
| OpportunityLineItemHandler | Handler | Opportunity | Recalculate `DOCUSIGN_Ad_Spend_Amount__c` / `DOCUSIGN_Marketing_Services_Products__c` on parent opp. | OpportunityLineItemTriggerTest |
| OpportuntiyClosedWonAlert | Invocable | Opportunity | Flow action "Send Eamil To Primary Contact" – sends template "Starter IA CSA Outreach". | OpportuntiyClosedWonAlertTest |
| CrossUpsellInfoController | Controller | Opportunity | Std-controller extension returning Auto/Home/Life `Upsell__c` for an Opportunity. | **None found** |
| OpportunityTriggerHandlerTest | Test | Opportunity | Enrichment follow-up opp creation. | – |
| TestCreateNewOppWhenClose | Test | Opportunity | Close-won opp update (no assertions). | – |
| OpportunityLineItemTriggerTest | Test | Opportunity | OLI insert/update/delete (SeeAllData, hardcoded Opp Id). | – |
| OpportuntiyClosedWonAlertTest | Test | Opportunity | Closed-won email invocable. | – |

## Activities (Task / Event)

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| TaskHandler | Handler | Activities | Task role/profile stamp, reminder copy, first inbound call lead owner, CTI notify. | TaskHandlerTest, TaskLeadTests, TestTaskSetReminder, TestAggregateCall, TestUpdateCase |
| EventHandler | Handler | Activities | Event role/profile stamp, Case/Lead time-to-first-response, Initial Meeting → Lead IM fields. | EventHandlerTest, TestCaseFirstActivity, TestLeadFirstActivity, TestConvertLead |
| TaskHandlerTest | Test | Activities | TaskHandler incl. bulk. | – |
| TaskLeadTests | Test | Activities | First-inbound-call owner reassignment scenarios. | – |
| EventHandlerTest | Test | Activities | EventHandler incl. bulk/update. | – |
| TestAggregateCall | Test | Activities | Task/Event create/update/delete on Lead. | – |
| TestCaseFirstActivity | Test | Activities | Case first activity. | – |
| TestLeadFirstActivity | Test | Activities | Lead first activity. | – |
| TestConvertLead | Test | Activities | Initial Meeting event on Lead. | – |
| TestTaskSetReminder | Test | Activities | Reminder on Task/Event. | – |
| TestUpdateCase | Test | Activities | Outbound call task on Case. | – |

## Case & Email

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| EmailServiceToFindMatchingCase | Email Service | Case & Email | Inbound email → match Case by thread ref or `Zendesk_ID__c`, else create Case; log EmailMessage + attachments. | TestEmailServiceToFindMatchingCase |
| SendEmailForMissedCallAlertVC | Invocable | Case & Email / Voice | Flow action "Send Email on missed call". | SendEmailForMissedCallAlertVCTest |
| TestEmailServiceToFindMatchingCase | Test | Case & Email | Email service scenarios. | – |
| SendEmailForMissedCallAlertVCTest | Test | Case & Email | Missed-call email. | – |

## Voice & CTI

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| NotifyCTI | Main (@future callout) | Voice & CTI | POST to agents-cti-picker `/refreshactivity/{activity}`. | TaskHandlerTest (via TaskTrigger) |
| AutoPopulateContactOnVoiceCall | Handler | Voice & CTI | VoiceCall before insert/update – match Contact by phone, set `Contact__c`/`Account__c`. | TestAutoPopulateContactOnVoiceCall |
| TestAutoPopulateContactOnVoiceCall | Test | Voice & CTI | VoiceCall contact match (no assertions). | – |

## Cheat Sheets

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| LeadCheatsheetController | Controller | Cheat Sheets | Lead cheat sheet page; callouts to cheat-sheet service. | TestLeadCheatsheet |
| OpportunityCheatsheetController | Controller | Cheat Sheets | Opportunity cheat sheet page; callouts to cheat-sheet service. | TestOpportunityCheatsheet |
| JsonParseFamiliarNames | Utility (DTO) | Cheat Sheets | Deserialize familiar-names JSON. | TestLeadCheatsheet, TestOpportunityCheatsheet (indirect) |
| JsonParseMarketplaceStats | Utility (DTO) | Cheat Sheets | Deserialize marketplace stats JSON. | TestLeadCheatsheet, TestOpportunityCheatsheet |
| WrapperContactTenure | Utility (DTO) | Cheat Sheets | Contact + Account + tenure months. | TestLeadCheatsheet, TestOpportunityCheatsheet |
| TestLeadCheatsheet | Test | Cheat Sheets | Lead cheat sheet. | – |
| TestOpportunityCheatsheet | Test | Cheat Sheets | Opportunity cheat sheet. | – |
| MockHttpResponseGenerator | Test (HttpCalloutMock) | Cheat Sheets / tests | Mock for `/lead_familiar_names/` and `/account_familiar_names/`. | – |

## Batches & Schedulers

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| AssignLeadToCadencesBatch | Batch | Lead / Sales Engagement | Enroll high-score, recently active carrier leads into cadences for BDRs under 150 work items. | AssignLeadToCadencesBatchTest |
| AssignLeadToCadencesBatchScheduler | Schedulable | Lead / Sales Engagement | Runs AssignLeadToCadencesBatch (scope 1). | AssignLeadToCadencesBatchSchedulerTest |
| BulkAccountLastOppUpdate | Batch | Account | Set `Last_Opportunity_was_Close_Lost__c` when latest opp is Closed Lost. | BulkAccountLastOppUpdateTest |
| ConversationEntryBatchScheduler | Schedulable | Messaging cleanup | Delete `ConversationEntry` older than 90 days via DeleteOldConversationEntriesBatch. | deleteOldConversationBatchAndSchedular |
| DeleteOldConversationEntriesBatch | Batch | Messaging cleanup | Generic delete of query results. | deleteOldConversationBatchAndSchedular |
| DeleteFaliureCasesBatch | Batch | Data cleanup | Generic delete of caller-supplied query (virtual; test seam). | DeleteFaliureCasesBatchTest |
| FillRateBatchScheduler | Schedulable | Account | Runs UpdateFillRateBatch (scope 200). | UpdateFillRateBatchTest |
| UpdateFillRateBatch | Batch | Account | Clear `Uncapped_Fill_Rate__c`, `Low_Fill_Rate_Alert__c`. | UpdateFillRateBatchTest |
| OppToCSUpsellRTUpdate | Batch | Opportunity data migration | Cross-Sell → CS Upsell record type. | OppToCSUpsellRTUpdateTest |
| OppToStateFarmRTUpdate | Batch | Opportunity data migration | Accelerated / Accelerated-State Farm → Accelerated-AGP record type. | OppToStateFarmRTUpdateTest |
| OpportunityLegacyRecordTypeBatch | Batch | Opportunity data migration | Stamp `Legacy_Record_Type__c` from current record type. | OpportunityLegacyRecordTypeBatchTest |
| AssignLeadToCadencesBatchTest | Test | | | – |
| AssignLeadToCadencesBatchSchedulerTest | Test | | | – |
| BulkAccountLastOppUpdateTest | Test | | | – |
| deleteOldConversationBatchAndSchedular | Test | | Schedules ConversationEntryBatchScheduler. | – |
| DeleteFaliureCasesBatchTest | Test | | | – |
| ThrowingDeleteFaliureCasesBatch | Test (support) | | Subclass overriding `performDelete` to throw. | – |
| UpdateFillRateBatchTest | Test | | Batch + schedule `0 0 22 ? * 6 *`. | – |
| OppToCSUpsellRTUpdateTest | Test | | | – |
| OppToStateFarmRTUpdateTest | Test | | | – |
| OpportunityLegacyRecordTypeBatchTest | Test | | | – |

## Communities & Sites

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| ChangePasswordController | Controller | Communities | `Site.changePassword`. | ChangePasswordControllerTest |
| CommunitiesLandingController | Controller | Communities | `Network.communitiesLanding()`. | CommunitiesLandingControllerTest |
| CommunitiesLoginController | Controller | Communities | `Network.forwardToAuthPage`. | CommunitiesLoginControllerTest |
| CommunitiesSelfRegConfirmController | Controller | Communities | Empty confirm-page controller. | CommunitiesSelfRegConfirmControllerTest |
| CommunitiesSelfRegController | Controller | Communities | `Site.createExternalUser` self-registration. | CommunitiesSelfRegControllerTest |
| ForgotPasswordController | Controller | Communities | `Site.forgotPassword`. | ForgotPasswordControllerTest |
| MicrobatchSelfRegController | Controller | Communities | `Network.createExternalUserAsync` self-registration. | MicrobatchSelfRegControllerTest |
| MyProfilePageController | Controller | Communities | Edit portal User and sync to Contact. | MyProfilePageControllerTest |
| SiteLoginController | Controller | Communities | `Site.login`. | SiteLoginControllerTest |
| SiteRegisterController | Controller | Communities | `Site.createPortalUser` with hardcoded placeholder account Id. | SiteRegisterControllerTest |
| (10 × *ControllerTest) | Test | Communities | All `SeeAllData=true`. | – |

## Unsubscribe

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| unsubscribe | Email Service | Unsubscribe | Subject contains "unsubscribe" → opt out matching Contacts/Leads. | Inline `testMethod`s (API 12.0); jrsl_ul_UnsubscribeLinkTest / jrsl_ul_UnsubscribeControllerTest reference it |
| jrsl_ul_UnsubscribeController | Controller | Unsubscribe | Confirmation text based on `jrsl_ul_Unsubscribe_Link__mdt`. | jrsl_ul_UnsubscribeControllerTest |
| jrsl_ul_TestContext | Utility | Unsubscribe | Static `testCase` filter for the mdt query. | jrsl_ul_UnsubscribeControllerTest |
| jrsl_ul_UnsubscribeContactsTest | Test | Unsubscribe | Runs flow `jrsl_ul_Unsubscribe_Contacts`. | – |
| jrsl_ul_UnsubscribeLeadsTest | Test | Unsubscribe | Runs flow `jrsl_ul_Unsubscribe_Leads`. | – |
| jrsl_ul_UnsubscribeLinkTest | Test | Unsubscribe | Asserts mdt record "Unsubscribe" exists. | – |
| jrsl_ul_UnsubscribeControllerTest | Test | Unsubscribe | Controller message variants. | – |

## Utilities & Test Framework

| Class | Type | Functional area | One-line purpose | Test class |
|---|---|---|---|---|
| TriggerHandler | Utility (framework) | Framework | Virtual trigger-handler base (context dispatch, bypass, max loop count). | TriggerHandlerTest |
| checkTriggerRecursion | Utility | Framework | Static per-transaction "run once" guard by identifier. | TestCheckTriggerRecursion |
| Rider | Utility (DTO) | Life products | `@AuraEnabled` product/amount/units DTO. | None (properties only) |
| DataFactory | Test (factory) | Test framework | Builds Account/Opportunity, sets `OnboardingSettings__c`. | – |
| TriggerHandlerTest | Test | Framework | | – |
| TestCheckTriggerRecursion | Test | Framework | | – |
| testAutomationRuntime | Test | Process Automation Tracking pkg | Runs flow `Create_Automation_Runtime`; asserts `Automation_Runtime__c`. | – |
