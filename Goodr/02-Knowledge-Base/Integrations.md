# KB-003 — Integrations

| | |
|---|---|
| **Document ID** | KB-003 |
| **Last updated** | 2026-10-14 |

Credentials are **never** stored in this repository. The table shows where each integration keeps its settings in the org.

| System | Direction | Settings / credentials (in the org) | Entry points |
|---|---|---|---|
| **Shopify** | Salesforce ↔ Shopify (GraphQL Admin API) | `Shopify_Configuration__c` records (access token and endpoint, chosen by Sales Channel or country through `ShopifyConfigService`), `Shopify_At_Risk_Config__mdt` | Schedulers, batches, queueables, the `accountShopifySyncButton` LWC, flows |
| **NetSuite** | NetSuite → Salesforce (products and pricebooks) | Named credentials `NetSuite_Sandbox` and `NetSuite_JWT_Signer`, `NetSuite_Config__mdt` (OAuth 2.0 M2M), `NetSuite_Credential__mdt` (TBA). Both CMDT records are git-ignored | `NetSuiteSyncScheduler` → `NetSuiteProductSyncBatch` |
| **Typeform** | Typeform → Salesforce (retailer forms, files) | `Typeform_Config__c` custom setting (personal access token), Typeform managed package (`typeform__Form__c`) | Flow `Lead_From_US_Retailer_Form_Assignment_And_Email`, `TypeFormFileFetcherInvoker` |
| **Zendesk** | Zendesk → Salesforce (webhook) | Exposed Apex REST endpoint `/services/apexrest/zendeskSfWebhook/` | `ZendeskWebhookAPI` creates a Case (`Zendesk_ID__c`, `Zendesk_Description__c`) |

All callouts log to `API_Log__c` through `APILogger`. `APILogCleanupBatch` purges old logs.

## Shopify
| Area | Classes |
|---|---|
| Company / account sync | `ShopifyAccountIntegration`, `ShopifyAccountSyncQueuable`, `ShopifyCompanyManualSyncQueueable`, `ShopifyIntegrationService` (invocable) |
| Store locations | `ShopifyStoreLocationSyncQueuable`, `ShopifyStoreLocationManualSyncQueueable`, `ShopifyActivateStoreLocationQueueable`, `ExternalStoreCreation` |
| Contacts | `ShopifyContactIntegration`, `ShopifyContactSyncQueueable`, `ShopifyContactManualSyncQueueable` |
| Contact ↔ company associations | `ShopifyAssociationIntegration`, `ShopifyAssociationSyncQueueable`, `ShopifyAssociationSyncSchedulable`, `ShopifyAssociationRetryBatch` (sandbox only), `ShopifyManualAssociationQueueable` |
| Addresses | `ShopifyAddressSyncService`, `ShopifyAddressSyncQueueable` |
| Active status | `ShopifyActiveStatusPushService`, `ShopifyActiveStatusSyncQueueable` |
| Orders and sales | `ShopifyOrderSyncBatch`, `ShopifyOrderSyncService`, `ShopifySalesSyncScheduler`, `ShopifySalesSyncBatch`, `ShopifySalesSyncService`, `ShopifyR12SalesBatch`, `ShopifyR12SalesService`, `BackfillLastShopifyOrderDate` |
| At-risk / offboarding | `ShopifyAtRiskNoticeBatch` → `Shopify_At_Risk_Notice__c` → flow `Send_Shopify_At_Risk_Notice` → `SendWarmOffEmail`; flow `Set_At_Risk_Dates_on_Store_Location`. See `06-Deployment/Deployment-Documents/Shopify_AtRisk_Offboarding_Deployment_Document.xlsx` |
| Manual sync button | `ShopifySyncButton` + LWC `accountShopifySyncButton` |

**Note:** the classes call four different Admin API versions (2023-10, 2024-01, 2024-04, 2026-04). See `05-Conflicts` CON-027.

## NetSuite
`NetSuiteSyncScheduler` → `NetSuiteProductSyncBatch`: queries NetSuite through SuiteQL (`callout:NetSuite_Sandbox/services/rest/query/v1/suiteql`)
and upserts products and prices into the Global, USA, CAN and Standard pricebooks.
Authentication helpers: `NetSuiteOAuth2HelperES256` (JWT ES256, token cached in Platform Cache), `NetSuiteOAuth2Helper`, `NetSuiteOAuthHelper` (TBA).

## Typeform
A retailer form submission creates `typeform__Form__c`. The flow `Lead_From_US_Retailer_Form_Assignment_And_Email` (after-save) creates and assigns the Lead
and sends the email. The Canada path sets Sales Channel = **Specialty** (since 2026-10-08). `TypeFormFileFetcher*` downloads the attached files
into Salesforce Files. `TypeformBackfill` re-fetches files in bulk. The flow `Typeform_Case_Routing` routes support forms to queues.

## Zendesk
`POST /services/apexrest/zendeskSfWebhook/` → `ZendeskWebhookAPI.handleWebhook()` parses the payload, finds the Contact and the queue (`Group`),
and inserts a Case.

## Inventories (generated)
[TECH-002_Apex-Classes.md](../07-Technical/TECH-002_Apex-Classes.md) · [TECH-003_Apex-Triggers.md](../07-Technical/TECH-003_Apex-Triggers.md) · [TECH-004_Flows.md](../07-Technical/TECH-004_Flows.md) · [TECH-005_Fields-and-Custom-Metadata.md](../07-Technical/TECH-005_Fields-and-Custom-Metadata.md) · [TECH-006_UI-Components.md](../07-Technical/TECH-006_UI-Components.md)
