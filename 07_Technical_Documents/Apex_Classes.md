# Apex Classes

_Generated 2026-10-13 from `force-app/main/default/classes` by `scripts/doc-builders/build_technical_docs.ps1`._

103 classes + 82 test classes. **Kind**, **Objects** (SOQL `FROM`) and **Callouts** are read from the code.

## Account / Contact

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `AccountContactRelationHandler` | Trigger handler | Account, Contact |  | handleAfterInsert | AccountContactRelationHandlerTest | 111 |
| `AccountManualApproveController` | LWC/Aura controller | Account |  | approveAccount | AccountManualApproveControllerTest | 12 |
| `AccountTriggerHandler` | Trigger handler | Account |  | handleAfterInsert, handleAfterUpdate, handleBeforeInsert, handleBeforeUpdate, handleAfterDelete |  | 219 |
| `AccountTriggerHelper` | Trigger handler | Account |  | fillParentRecordInformation, removeSymbolsFromTaxId, updateCompanyDoors, updateCompanyTotalSales, filterAccountsWithRevenueChanges, filterAccountsWithActiveChanges | AccountTriggerHelperTest | 795 |
| `AddressDuplicateService` | Service |  |  | normalizeAddress, areAddressesIdentical, calculateSimilarity, compareFullAddresses | AddressDuplicateServiceTest | 163 |
| `ContactManualApproveController` | LWC/Aura controller | Contact |  | approveContact | ContactManualApproveControllerTest | 12 |
| `ContactTriggerHandler` | Trigger handler | Account, Contact |  | handleBeforeInsert, handleBeforeUpdate, handleAfterInsert, handleAfterUpdate | ContactTriggerHandlerTest | 156 |
| `ContactTriggerHelper` | Trigger handler | Account, Contact |  | assignContactToCompany, validateAndCleanseNewContacts, handleRejectedContacts, createStoreLocationNote, removeSymbolsFromTaxId |  | 261 |
| `CountryToCountryCodeHelper` | Helper |  |  | getCountryCode | CountryToCountryCodeHelperTest | 31 |
| `StateToStateCodeHelper` | Helper |  |  | getStateCode | StateToStateCodeHelperTest | 132 |

## API logging

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `APILogCleanupBatch` | Batch, Schedulable | API_Log__c |  | start, execute, finish, scheduleDailyJob | APILogCleanupBatchTest | 29 |
| `APILogger` | Class |  |  | logCalloutError, insertLogs, createLog | APILoggerTest | 79 |
| `ApiLogTriggerHandler` | Trigger handler | Case |  | handleAfterInsert |  | 179 |

## Case management / Service

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `AutomatedTaskTriggerHandler` | Trigger handler | Task |  | deleteAutomatedTasks | AutomatedTaskTriggerHandlerTest | 54 |
| `CaseActionController` | LWC/Aura controller | Case, CaseStatus |  | resolveCase, changeStatus, getCaseStatusesExcludingResolved | CaseActionControllerTest | 46 |
| `CaseOrchestrationEngine` | Service | BusinessHours, Case_Queue_Team_Routing__mdt, CaseTeamRole, CaseTeamTemplate, CaseTeamTemplateMember, Group, SLA_Configuration__mdt |  | process |  | 378 |
| `CaseOrchestratorHandler` | Trigger handler |  |  | enqueue |  | 16 |
| `CaseOrchestratorQueueable` | Queueable |  |  | execute |  | 18 |
| `CaseQueueAssignmentHandler` | Trigger handler |  |  |  |  | 3 |
| `CaseQueueTeamJob` | Queueable | Group, User |  | execute |  | 73 |
| `CaseReopenHandler` | Trigger handler | Case, Group |  | reopenClosedCases | CaseReopenHandlerTest | 297 |
| `CaseSLARecalculationBatch` | Batch | BusinessHours, Case, SLA_Configuration__mdt |  | start, execute, finish |  | 179 |
| `CaseSLAScheduler` | Schedulable |  |  | execute |  | 7 |
| `CaseSurveyQueueable` | Queueable | Case, EmailTemplate, Network, Survey, SurveyInvitation |  | execute | CaseSurveyQueueableTest | 221 |
| `CaseTeamAssignmentQueueable` | Queueable | Case |  | execute |  | 15 |
| `CaseTriggerHandler` | Trigger handler |  |  | processBeforeInsert | CaseTriggerHandlerTest | 17 |
| `CaseTriggerHelper` | Trigger handler | Group |  | assignCaseCluster | CaseTriggerHelperTest | 35 |
| `DeleteAutomatedTasksBatch` | Batch, Schedulable | Task |  | start, execute, finish | DeleteAutomatedTasksBatchTest | 63 |
| `EmailMessageTriggerHandler` | Trigger handler |  |  | handleAfterInsert |  | 6 |
| `EmailMessageTriggerHelper` | Trigger handler | Case, Lead |  | processNewEmailMessages | EmailMessageTriggerHelperTest | 178 |

## Cluster & Team

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `AccountCascadeHandler` | Trigger handler | Account, Contact, Opportunity |  | handle | AccountCascadeHandlerTest | 102 |
| `ClusterRuleEngine` | Service | Sales_Channel_Cluster__mdt |  | evaluate | ClusterRuleEngineTest | 96 |
| `ClusterTeamEngine` | Service | Account_Cluster_Team__mdt, AccountTeamMember, Contact_Team__c, Lead_Team__c, OpportunityTeamMember, User |  | assignTeams | ClusterTeamEngineTest | 145 |
| `ContactTeamReassignQueueable` | Queueable | Contact |  | execute |  | 22 |

## Experience Cloud (standard)

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `ChangePasswordController` | Controller |  |  | changePassword | ChangePasswordControllerTest | 14 |
| `CommunitiesLandingController` | Controller |  |  | forwardToStartPage | CommunitiesLandingControllerTest | 12 |
| `CommunitiesLoginController` | Controller |  |  | forwardToAuthPage | CommunitiesLoginControllerTest | 14 |
| `CommunitiesSelfRegConfirmController` | Controller |  |  |  | CommunitiesSelfRegConfirmControllerTest | 7 |
| `CommunitiesSelfRegController` | Controller |  |  | registerUser | CommunitiesSelfRegControllerTest | 74 |
| `ForgotPasswordController` | Controller |  |  | forgotPassword | ForgotPasswordControllerTest | 19 |
| `LightningForgotPasswordController` | LWC/Aura controller |  |  | forgotPassword, setExperienceId | LightningForgotPasswordControllerTest | 35 |
| `LightningLoginFormController` | LWC/Aura controller |  |  | login, getIsUsernamePasswordEnabled, getIsSelfRegistrationEnabled, getSelfRegistrationUrl, getForgotPasswordUrl, setExperienceId | LightningLoginFormControllerTest | 65 |
| `LightningSelfRegisterController` | LWC/Aura controller |  |  | selfRegister, getExtraFields, setExperienceId | LightningSelfRegisterControllerTest | 137 |
| `MicrobatchSelfRegController` | Controller |  |  | registerUser | MicrobatchSelfRegControllerTest | 57 |
| `MyProfilePageController` | Controller | User |  | getUser, getIsEdit, edit, save, changePassword, cancel | MyProfilePageControllerTest | 53 |
| `SiteLoginController` | Controller |  |  | login | SiteLoginControllerTest | 14 |
| `SiteRegisterController` | Controller |  |  | registerUser | SiteRegisterControllerTest | 50 |

## Lead

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `ConversionContext` | Class |  |  |  |  | 3 |
| `LeadConversionHandler` | Trigger handler | Account, Contact, Opportunity |  | handleConversion | LeadConversionHandlerTest | 78 |
| `LeadConversionService` | LWC/Aura controller, Callout | Account, AccountContactRelation, Contact, Lead, Store__c |  | canConvert, convertLead | LeadConversionServiceTest | 753 |
| `LeadManualApproveController` | LWC/Aura controller | Lead |  | approveLead | LeadManualApproveControllerTest | 30 |
| `LeadMergeService` | Service |  |  | mergeLeadsWithNote | LeadMergeServiceTest | 114 |
| `LeadTriggerHandler` | Trigger handler | Account, Lead, RecordType |  | checkIfEarlyStagesFilled, setLeadSources, setStateToStateCode, removeSymbolsFromTaxId, handleBeforeUpdate | LeadTriggerHandlerTest | 466 |

## NetSuite integration

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `NetSuiteOAuth2Helper` | Callout |  | NetSuite_JWT_Signer | getAccessToken |  | 59 |
| `NetSuiteOAuth2HelperES256` | Callout |  |  | getAccessToken, callRest | NetSuiteOAuth2HelperES256Test | 320 |
| `NetSuiteOAuthHelper` | Helper | NetSuite_Credential__mdt |  | buildAuthHeader |  | 66 |
| `NetSuiteProductSyncBatch` | Batch, Callout | Pricebook2 | NetSuite_Sandbox | start, execute, finish | NetSuiteProductSyncBatchTest | 367 |
| `NetSuiteProductWrapper` | Class |  |  |  | NetSuiteProductWrapperTest | 31 |
| `NetSuiteSyncScheduler` | Schedulable |  |  | execute |  | 7 |

## Sales ops / Files

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `CategoryRevenueGenerator` | LWC/Aura controller | Account, Category_Revenue__c, Contact |  | generateCategoryRevenueForAllStoresWithChanges, generateCategoryRevenue, compare | CategoryRevenueGeneratorTest | 332 |
| `CategoryRevenueScheduler` | Schedulable |  |  | execute | CategoryRevenueSchedulerTest | 6 |
| `ContentDocumentLinkHandler` | Trigger handler | ContentDocumentLink, ContentVersion, EmailMessage, Task |  | handleAfterInsert | ContentDocumentLinkHandlerTest | 155 |
| `ContentVersionHandler` | Trigger handler | ContentDocumentLink, EmailMessage, Task |  | handleAfterUpdate | ContentVersionHandlerTest | 121 |
| `PurchaseOrderFilesController` | LWC/Aura controller | ContentDocument, ContentDocumentLink, ContentVersion |  | getPurchaseOrderFiles, uploadFile, tagFilesAsPurchaseOrder, togglePurchaseOrder, deleteFile | PurchaseOrderFilesControllerTest | 157 |
| `WinbackStatusScheduler` | Schedulable |  |  | execute |  | 16 |
| `WinbackStatusSync` | Class | ActionCadenceStepTracker, ActionCadenceTracker, Campaign, CampaignMember |  | syncEnrollments, syncCadenceStates, syncBouncedEmails, runFullSync, getStatusPriority |  | 360 |

## Shopify integration

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `BackfillLastShopifyOrderDate` | Batch, Schedulable | Account, Order |  | execute, start, finish | BackfillLastShopifyOrderDateTest | 125 |
| `ExternalStoreCreation` | Class |  |  | createStoresFromTypeformResponse | ExternalStoreCreationTest | 251 |
| `SendWarmOffEmail` | Invocable (Flow) | EmailTemplate, OrgWideEmailAddress, Shopify_At_Risk_Notice__c |  | send |  | 170 |
| `ShopifyAccountIntegration` | Callout | Account, Contact |  | sendAccountAndStoreLocationToShopify, createCompanyLocation, createStoreLocations | ShopifyAccountIntegrationTest | 453 |
| `ShopifyAccountSyncQueuable` | Queueable, Callout |  |  | execute | ShopifyAccountSyncQueuableTest | 16 |
| `ShopifyActivateStoreLocationQueueable` | Queueable, Callout | Account |  | execute |  | 113 |
| `ShopifyActiveStatusPushService` | Callout | Account, AccountContactRelation |  | syncActiveStatusToShopify | ShopifyActiveStatusPushServiceTest | 597 |
| `ShopifyActiveStatusSyncQueueable` | Queueable, Callout |  |  | execute |  | 13 |
| `ShopifyAddressSyncQueueable` | Queueable, Callout |  |  | execute |  | 13 |
| `ShopifyAddressSyncService` | Callout | Account |  | syncAddressToShopify |  | 190 |
| `ShopifyAssociationIntegration` | Callout | Account, AccountContactRelation, Contact |  | process | ShopifyAssociationIntegrationTest | 524 |
| `ShopifyAssociationRetryBatch` | Batch, Callout | Account, AccountContactRelation |  | start, execute, finish |  | 83 |
| `ShopifyAssociationSyncQueueable` | Queueable, Callout | Account, Contact |  | execute | ShopifyAssociationSyncQueueableTest | 121 |
| `ShopifyAssociationSyncSchedulable` | Schedulable | Contact |  | execute | ShopifyAssociationSyncSchedulableTest | 71 |
| `ShopifyAtRiskNoticeBatch` | Batch, Schedulable | Account, Shopify_At_Risk_Notice__c, User |  | execute, start, finish | ShopifyAtRiskNoticeBatchTest | 566 |
| `ShopifyCompanyManualSyncQueueable` | Queueable, Callout | Account |  | execute | ShopifyCompanyManualSyncQueueableTest | 21 |
| `ShopifyConfigService` | Service | Shopify_Configuration__c |  | getConfig, getConfigByCountry |  | 42 |
| `ShopifyContactIntegration` | Callout | Contact |  | sendToShopify | ShopifyContactIntegrationTest | 230 |
| `ShopifyContactManualSyncQueueable` | Queueable, Callout | Contact |  | execute | ShopifyContactManualSyncQueueableTest | 30 |
| `ShopifyContactSyncQueueable` | Queueable, Callout |  |  | execute | ShopifyContactSyncQueueableTest | 42 |
| `ShopifyIntegrationService` | Invocable (Flow), Callout | Account, Contact |  | sendContactToShopify, createCompanyContact, getShopifyCompanyIdByName | ShopifyIntegrationServiceTest | 268 |
| `ShopifyManualAssociationQueueable` | Queueable, Callout | AccountContactRelation |  | execute | ShopifyManualAssociationQueueableTest | 55 |
| `ShopifyOrderSyncBatch` | Batch, Schedulable, Callout | Account, Order |  | execute, start, finish |  | 144 |
| `ShopifyOrderSyncService` | Callout | Order, Pricebook2 |  | syncOrders |  | 751 |
| `ShopifyR12SalesBatch` | Batch, Schedulable | Account |  | execute, start, finish |  | 104 |
| `ShopifyR12SalesService` | Service | Account, Order |  | calculateR12 |  | 280 |
| `ShopifySalesSyncBatch` | Batch, Callout | Account |  | start, execute, finish |  | 47 |
| `ShopifySalesSyncScheduler` | Schedulable |  |  | execute | ShopifySalesSyncSchedulerTest | 6 |
| `ShopifySalesSyncService` | Callout |  |  | syncStoreLocationSales | ShopifySalesSyncServiceTest | 384 |
| `ShopifyStoreLocationManualSyncQueueable` | Queueable, Callout | Account |  | execute |  | 72 |
| `ShopifyStoreLocationSyncQueuable` | Queueable, Callout |  |  | execute | ShopifyStoreLocationSyncQueuableTest | 11 |
| `ShopifySyncButton` | LWC/Aura controller | Account, Contact |  | recreateRecords | ShopifySyncButtonTest | 48 |

## Typeform integration

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `TypeformBackfill` | Batch, Callout | ContentVersion |  | start, execute, finish | TypeformBackfillTest | 124 |
| `TypeFormFileFetcher` | Callout | ContentVersion, Lead |  | fetchAndSaveFiles | TypeFormFileFetcherTest | 294 |
| `TypeFormFileFetcherInvoker` | Invocable (Flow) |  |  | invoke | TypeFormFileFetcherInvokerTest | 16 |
| `TypeFormFileFetcherQueueable` | Queueable, Callout |  |  | execute | TypeFormFileFetcherQueueableTest | 12 |

## Zendesk integration

| Class | Kind | Objects queried | Named credential | Main methods | Test class | Lines |
|---|---|---|---|---|---|---|
| `ZendeskWebhookAPI` | REST API | Contact, Group |  | handleWebhook |  | 91 |

## Test classes -  - System.Object[]
