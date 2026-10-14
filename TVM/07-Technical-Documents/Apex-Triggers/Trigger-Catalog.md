# Apex Trigger Catalog

All 20 unmanaged triggers, as retrieved from Fullsandbox on 2026-10-14. Source: [`force-app/main/default/triggers/`](../../force-app/main/default/triggers/).
Generated details (status, line counts): [Metadata-Inventory/Apex-Triggers.md](../Metadata-Inventory/Apex-Triggers.md).
Events: b = before, a = after; i = insert, u = update, d = delete, ud = undelete.

| Trigger | Object | Events | Delegates to | Guard / bypass | Notes |
|---|---|---|---|---|---|
| `AccountTrigger` | Account | bi, bu | `UpdateDMA1Helper` | Field filter: Foundation records; ShippingPostalCode change | Sets DMA |
| `TouchPointAccountUpdateTrigger` | Account | au | `TouchPointMakeAccountPOSTCallout`, `TouchPointMakeCPPOSTCallout` (@future) | `Process_Switches__c.Account_Integration_Bypass__c`, Integration User, batch/future | **Inactive** in source. Callout classes are excluded from Git (CF-001) |
| `CaseTrigger` | Case | bd | `CaseTriggerHelper.beforeDelete` | `TriggerUtil` + static Id sets | Also cleans SF2SF queue |
| `CaseTrigger_FNDN` | Case | bi, ai, bu, au | `CalculateCaseDueDate`, `CaseOOOAssignmentHandler`, `Th_CaseTrigger` | Record filter: Foundation / New Digital Support | Case routing engine ([doc](../Routing-and-Omni-Channel/Case-Assignment-Engine.md)) |
| `ContactTrigger` | Contact | ai, au, ad, aud | `ContactRoleAccountHandler.syncContacts` | None | |
| `TouchPointContactUpdateTrigger` | Contact | ai, au | `TouchPointMakeContactPOSTCallout` | `Contact_Integration_Bypass__c`, Integration User, tests | **Inactive** in source |
| `OpportunityContractFileTrigger` | Opportunity | au | Logic inside the trigger (ContentDistribution → Account.Contract_File__c) | None | SOQL in loop; hard-coded RecordType Ids |
| `OpportunityLineItemTrigger` | OpportunityLineItem | ai, au, ad | `OpportunityLineItemHandler` | `hasAlreadyRun` (partial) | `updateHybridProductFlag` runs on every event |
| `OpportunityProductTrigger` | OpportunityLineItem | bi, ai, ad | `OpportunityProductHandler` | None | |
| `create_OppProduct_History` | OpportunityLineItem | bd, ad | Logic inside the trigger (`Product_History__c`) | None | Bulk defect: only the last Opportunity is updated |
| `AttachmentTrigger` | Attachment | bi, ai, bu, au, bd | `AttachmentTriggerHelper` | `TriggerUtil` | Queues SF2SF sharing; enqueues file deletion |
| `ContentDocumentLinkTrigger` | ContentDocumentLink | ai | `ContentDocumentLinkTriggerHelper.processFilesConvert` | `TriggerUtil` | |
| `ContentDocumentLinkTrigger_FNDN` | ContentDocumentLink | bi | `Th_ContentDocumentLinkTrigger.onBeforeInsert` | None | After-insert code is commented out |
| `ContentVersionTrigger` | ContentVersion | ai | Logic inside the trigger | None | SOQL in loops; hard-coded RecordType Ids |
| `FeedItemTrigger` | FeedItem | ai | `CreateCaseCommentHandler` | None | Chatter post → case comment |
| `MeasurementTrigger` | Measurement__c | au | `Th_MeasurementTrigger` | None | |
| `OnboardingTrigger` | Foundation_Onboarding__c | bi, bu, ai, au | `OnboardingTriggerHandler` | `isFirstTime` (one method) | |
| `TouchPointAutoGroupUpdateTrigger` | Auto_Group__c | au | `TouchPointMakeAutoGroupPOSTCallout` | `Auto_Group_Integration_Bypass__c` | **Inactive** in source |
| `TouchPointBudgetUpdateTrigger` | Monthly_Budget__c | ai, au | `TouchPointMakeBudgetPOSTCallout` | `Monthly_Budget_Integration_Bypass__c`, `Sent_to_TP__c` null, tests | **Active** |
| `slack_User_Ticket` | User_Story__c | ai, au, bd | `slackv2__.utilities.startSubscriptionQueue` (managed package) | None | |

Objects with more than one trigger have no guaranteed order between them: Account, Case, Contact, ContentDocumentLink, OpportunityLineItem (3).
When changing any of these, also review the record-triggered Flows on the object
([Automation-and-Execution-Order.md](../../02-Knowledge-Base/Automation-and-Execution-Order.md)).

## Verification
| Date | Check | Result |
|---|---|---|
| 2026-10-14 | Source read after retrieval; status from `*.trigger-meta.xml` | As listed. Behaviour not tested in the org |

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-14 | Created from the baseline retrieval | — |
