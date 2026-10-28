# Integrations and External Systems

Built from retrieved source (2026-10-14). No credential values are recorded here. Hardcoded credentials found in source are tracked in
[CON-002](../2026-10/05-Conflicts/CON-002_Hardcoded-Credentials-In-Org-Apex-And-External-Credential-Source.md).
INFERENCE marks statements not verified in code.

## 1. TouchPoint CRM (Quickbase): the main custom integration
Outbound only. Salesforce pushes Account, Contact, Auto_Group__c (dealer group) and Monthly_Budget__c data to TouchPoint, which runs on Quickbase.

| Path | Components | Status |
|---|---|---|
| Apex triggers → `@future` callouts | `TouchPointAccountUpdateTrigger`, `TouchPointContactUpdateTrigger`, `TouchPointAutoGroupUpdateTrigger`, `TouchPointBudgetUpdateTrigger` call `TouchPointMake{Account,CP,Contact,AutoGroup,Budget}POSTCallout` (POST to the Quickbase records API) | Account, Contact and Auto Group triggers are **Inactive** in source. The Budget trigger is **Active**. `TouchPointMakeCPPOSTCallout` has its body commented out |
| Flow → invocable Apex | `SendAccountToTouchpoint` (Active) → `TouchpointAPIInvocable` → `TouchpointAPI`. `TouchpointAGAPIInvocable` → `TouchpointAGAPI` | Active |
| Flow → legacy XML API | `TP_SYNCv2` (Active, Account after-save) → `TouchpointCallOutInvocable` → `TouchpointCallOut`. Builds the URL from `TouchPoint_Callout__mdt` records (`BaseURL`, `act`, `apptoken`, `usertoken`) | Active |
| Flow → External Service | `Account_TP_Sync_Detect_Changes_Build_Payload` (Active). `Account_TP_Staging_Push` (**Draft**) calls External Service `SFtoTPAccount` | Staging push not active |
| Named / external credential | Named credential `TP` (Quickbase API) with external credential `TPAuth` (custom headers, named principal). **Not used by the Apex classes** | Defined |

Supporting pieces:
- **Bypass:** `Process_Switches__c.*_Integration_Bypass__c`. The triggers also skip the "Integration User" and batch/future contexts.
- **Logging:** `Event_Log__c` stores the request and response: object, body, status code and message. `TouchpointCallOut` only writes debug logs. None of the classes has try/catch.
- **Fields:** `Account.Touchpoint_Master_ID__c`, `Monthly_Budget__c.Sent_to_TP__c`.

**Risks:**
- Credentials are hardcoded in 7 classes (CON-002).
- INFERENCE: up to three Account sync paths could fire on one change: the trigger if reactivated, `TP_SYNCv2`, and `SendAccountToTouchpoint`.

## 2. Salesforce-to-Salesforce (Foundation Direct org)
- Flows `Forward_to_FD`, `Forward_to_SD` and `Forward_Onboarding_to_FD` (Active) share records over Salesforce-to-Salesforce.
  They create `PartnerNetworkRecordConnection` records using the label `$Label.FDConnectionId`.
- `AttachmentTriggerHelper` queues the attachments of shared Cases in `SF2SF_Sharing_Queue__c`. `CaseTriggerHelper` handles deletes.
  `QueueScheduleProcessDataBatch` processes the queue and reschedules itself.
- `ShareStatusController` with Aura `ShareStatus` shows the sharing status, mapped through `SharingStatusMapping__mdt`.
- `SF2SF_Automation_Setting__mdt` (record `GM_Connection`) is not referenced in code. INFERENCE: it is configuration only.
- `Foundation_SFtoSF_integration` is a permission set.

## 3. Inbound interfaces
- **Email services** (`Messaging.InboundEmailHandler`):
  - `EmailToCaseReply`: Case threading or creation.
  - `FetchTaskStatusfrmMail`: Task updates.
  - `FetchMeetingRecap`: `Meeting_Recap__c`.
  - `FetchCoreVital`: `Core_Vitals__c`.
  - `Getting_Response_CSV_Record_Sheet2`: `Foundation_Onboarding__c`.
  - Email-service addresses are configured in Setup and are not in source.
- **No** Apex REST (`@RestResource`) or SOAP `webservice` endpoints.
- **Connected apps** (15, definitions retrieved in the routing batch): for example DocuSign, Google_Integration, TableauID.
  Consumer secrets are never retrieved.

## 4. Managed-package integrations
Configuration lives in the packages. TVM source references them.

| System | Evidence in TVM source |
|---|---|
| DocuSign (`dfsle`, `dsfs`) and SpringCM CLM | Remote sites for the DocuSign and SpringCM hosts. About 35 Flows and many fields reference DocuSign. Workflow `Notify_Opp_owner_when_DocuSign_document_is_signed`. Signed-contract handling in `OpportunityContractFileTrigger` and `ContentVersionTrigger` |
| Slack (`slackv2`) | Trigger `slack_User_Ticket` calls the package queue. Flows `Archive_Slack_Channel`, `Account_Slack_Channel_Creator`, `Case_Created`. Labels for the Slack app, workspace and channel. Channel-Id fields on Account and Opportunity |
| Jira Cloud (`JCFS`, Appfire) | Remote sites. Jira LWCs on pages. `Jira_ID__c`, `Jira_Status__c` and `Jira_Link__c` fields |
| Pardot / Account Engagement (`pi`) | Do-not-sync Flows on Contact and Lead. Pardot campaign record type |
| Highspot | Named credential `highspot_connection`, tab `Highspot_Content`, 3 Flows |
| Telephony | Call centers `RingCentral` and `TVMSBCC` (RingCentral package `rcsfl`). Amazon Connect / Service Cloud Voice (`awsac`). Voice queues and routing (see [Case-Routing-and-Omni-Channel.md](Case-Routing-and-Omni-Channel.md)) |
| Google Ads / Data Cloud | Named credentials `FD_Google_Ads`, `FD_Google_Ads_Account` and `fndn_google_ads` (OAuth). INFERENCE: used by Data Cloud |
| MuleSoft | Named credential, external credential and remote site. **No Apex uses them** |
| Geocoding | `GeocodingService` → nominatim.openstreetmap.org (Flow `Create_property`) |

## 5. Hardcoded org URLs
Aura components `OnboardingCheckListReport` and `RecentlyLaunchedAccounts` link to fixed org domains (Foundation Direct and TVM production).
These links point at production from the sandbox.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from analysis of the baseline retrieval. |
