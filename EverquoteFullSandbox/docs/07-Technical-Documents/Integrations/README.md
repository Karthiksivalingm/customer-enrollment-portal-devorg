# Integrations Catalogue

This catalogue covers every integration found in `force-app/main/default`, from these sources:

- **Apex classes:** searched for `HttpRequest`, `callout:`, `setEndpoint`, `new Http()`, `InboundEmailHandler` and `EventBus`.
- **Triggers.**
- **Workflows:** outbound messages.
- **Flows:** apex actions and outbound messages.

Searches that found nothing:

- No Platform Events (`__e`), Named Credential, Remote Site Setting, External Service, or Custom Metadata definition exists in the repo.
- The `objects/` folder is empty.

Secrets are redacted as `[REDACTED – found in <file>:<line>]`.

## Summary

| # | Integration | Direction | Mechanism | Endpoint / credential |
|---|---|---|---|---|
| 1 | Odie quoting / e-app / policy API (ODA) | Outbound | REST callout via Named Credential (sync, from `@AuraEnabled`) | `callout:Odie_API_Credential/…` |
| 2 | Odie lead sync (form, lead, owner, disposition) | Outbound | REST callout via Named Credential (`@future` + sync) | `callout:Odie_API_Credential/forms…` |
| 3 | Odie Twilio call-recording control | Outbound | REST via Odie Named Credential | `callout:Odie_API_Credential//twilio/{pause,resume}_recording` |
| 4 | Named-Credential-as-URL-store (Omni Commerce FE comparison tool, Reliashield PDF) | Outbound link (no callout) | SOQL on `NamedCredential.Endpoint` | `omni_commerce`, `reliashield_comparison_pdf` |
| 5 | CTI Picker "refresh activity" | Outbound | REST callout, hardcoded URL, Basic auth, `@future` | `https://agents-cti-picker-{prod,staging}.adh8.com/refreshactivity/` |
| 6 | Salesforce Cheat Sheet service (familiar names, marketplace stats, metrics) | Outbound | REST GET, hardcoded URL, Basic auth, sync from VF controller constructor | `https://salesforce-cheat-sheet-staging.adh8.com` |
| 7 | Delighted (CSAT/LCS surveys) | Outbound | Workflow Outbound Messages (SOAP) on Contact | `https://delighted.com/integrations/salesforce/notification/custom/[REDACTED]` |
| 8 | Email-to-Case matcher | Inbound | Apex Email Service (`Messaging.InboundEmailHandler`) | Email Service address configured in org |
| 9 | Unsubscribe | Inbound | Apex Email Service | Email Service address configured in org |

## 1–3. Odie API (ODA quoting, lead sync, Twilio)

Full detail is in [../Apex-Classes/ODA-Quoting-Integration.md](../Apex-Classes/ODA-Quoting-Integration.md).

**Auth and transport**
- Base URL and auth both come from the Named Credential `Odie_API_Credential`, which is not in the repo.
- Every request is a POST with JSON body and `Content-Type: application/json`.
- `ODARequestCallout` adds `client`, `odie_agent_id` (`User.Odie_Agent_ID__c`) and `agent_email` to each request.

**Paths**
- `quotes`
- `carriers/{carrier}/products/{product}/rate_lookup`
- `riders/{p}/rates`
- `e_apps`, `e_apps/previous_e_apps`, `e_apps/save_policies`
- `forms`, `forms/{uuid}/leads`, `forms/update_owner`, `forms/update_sales_disposition`
- `/twilio/pause_recording`, `/twilio/resume_recording`

**Triggering components**
- `@AuraEnabled` methods on:
  - `ODAAigController`, `OdaGerberController`, `OdaLumicoQuoteController`, `OdaReliashieldController`
  - `OdaRatesController`, `ODALeadController`, `ODAEAppController`, `ODAPolicyController`, `ODANewLifeLeadController`
- `LeadTrigger` → `LeadHandler`:
  - after insert: Life_Leads create or owner sync
  - after update: owner change and `Lead_Outcome__c` change, via `OdieWrapper` `@future(callout=true)`
- `syncLeadOwnerToOdie` – `@InvocableMethod 'LeadOwnerSync'`. No flow in the repo calls it.
- Inactive legacy triggers: `LifeLeadCreated`, `LeadOwnerUpdated`, `LeadOutcomeUpdated`.

**Payloads** contain Lead PII (name, DOB, phone, email, address, health and tobacco answers) and agent email.

**Error handling**
- `ODARequestCallout` and `ODALeadController.processODARequest`: non-200 → `ODAException`, or `ODABusinessRuleException` when the body has `business_rule`.
- `OdieWrapper.processOdieRequest`: non-200 → returns `'{}'` silently. Callers then store a null `EqLeadUuid__c` and nothing is logged.
- No `setTimeout` (platform default 10 s). No retry.

**Test mock:** `OdieRequestCalloutMock` (captures path → body).

## 4. Named Credentials used as URL lookups

- `OdaUtils.getLink(devName)` queries `NamedCredential.Endpoint`. It throws `ODAException` if the Named Credential is missing.
- `omni_commerce`: `ODALeadController.getFEComparisonToolUrl` appends `age, gender, tobacco, eq_lead_uuid, advisor_id` (user email) as a query string. The URL is returned to the UI; no callout is made.
- `reliashield_comparison_pdf`: `OdaReliashieldController.getReliashieldComparisonPdfUrl`.
- **Test:** `OdaReliashieldControllerTests` needs this Named Credential to exist (see the ODA doc §7).

## 5. CTI Picker – `NotifyCTI`

**Endpoint and auth**
- `NotifyCTI.sendUpdate(activity)` is `@future(callout=true)` and sends a POST to `https://agents-cti-picker-prod.adh8.com/refreshactivity/<activity>`.
- If the org host starts with `cs`, it uses `https://agents-cti-picker-staging.adh8.com/refreshactivity/` instead.
- Auth is a hardcoded HTTP Basic credential: `[REDACTED – found in NotifyCTI.cls:16]`.

**Request:** no body. `setTimeout(10000)`.

**Triggering components**
- `TaskTrigger` (after insert/update) → `TaskHandler.notifyCTI()` → `sendUpdate('task')`. One call per trigger invocation.
- `EventNotifyCTI.trigger` is Active but its call is commented out. `TaskNotifyCTI.trigger` is Inactive.

**Error handling**
- None: the response is ignored and exceptions propagate in the future context.
- The host check uses `URL.getSalesforceBaseUrl()` and assumes `cs*` sandbox hostnames. Enhanced-domain sandboxes will route to **prod**.

**Test mock:** `TaskHandlerTest.NotifyCTIMock` (200 `{"status":"ok"}`).

## 6. Salesforce Cheat Sheet service – `LeadCheatsheetController`, `OpportunityCheatsheetController`

**Endpoint and auth**
- `pullRequest(path)` sends a GET to `https://salesforce-cheat-sheet-staging.adh8.com<path>?format=json`. This is a **staging host hardcoded for all orgs**.
- Auth is Basic: `[REDACTED – found in LeadCheatsheetController.cls:81]` and `[REDACTED – found in OpportunityCheatsheetController.cls:98]`.

**Paths**
- `/lead_familiar_names/{LeadId}`
- `/account_familiar_names/{AccountId}`
- `/state_marketplace_stats/{State}`
- `/metric/vpl_clegs`

**Response parsing**
- `JsonParseFamiliarNames`: `colleagues`, `familiar_names` (Account Ids), `distance`.
- `JsonParseMarketplaceStats`: `consumers` and `unsold_consumers` {premium, preferred, standard, non_standard}, `share_rate`, `unsold_leads`.

**Triggering components:** Visualforce page constructors and getters. The VF pages are not in the repo. The callout runs synchronously in the constructor.

**Error handling:** non-200 → `''`. Parse errors are swallowed (`catch(Exception e){}` / return `null`). No timeout is set.

**Test mock:** `MockHttpResponseGenerator`, used by `TestLeadCheatsheet` and `TestOpportunityCheatsheet` among others. It returns `{"distance":0,"colleagues":[],"familiar_names":[]}` for familiar-name paths.

**Note:** `OpportunityCheatsheetController.getCarrier()` line 154 tests `lead.Carrier__c`, which resolves to the `Lead.Carrier__c` field token. The token is never null, so the guard is ineffective.

## 7. Delighted – Workflow Outbound Messages (`workflows/Contact.workflow-meta.xml`)

| Outbound message | Line | Endpoint | Integration user |
|---|---|---|---|
| `CSAT_Starter_Team_Delighted_Outbound` | 113–121 | `https://delighted.com/integrations/salesforce/notification/custom/[REDACTED – found in Contact.workflow-meta.xml:115]` | [named user – see XML] |
| `LCS_Survey` | 124–132 | `…/custom/[REDACTED – found in Contact.workflow-meta.xml:126]` | [named user – see XML] |
| `LCS_Survey_2` | 135–143 | same token as LCS_Survey `[REDACTED – found in Contact.workflow-meta.xml:137]` | [named user – see XML] |

- **Payload:** Contact `Id` only. `includeSessionId=false`, `useDeadLetterQueue=false`.
- **Triggering component:** no workflow rule or flow in this repo references these outbound messages. They are defined only, and the active triggers are presumably elsewhere or retired.
- **Error handling:** platform outbound-message retry only.
- **Tests:** none.

## 8–9. Inbound Email Services

- **`EmailServiceToFindMatchingCase`**
  - Matches inbound email to a Case by ref id in the subject, or by `Case.Zendesk_ID__c` (legacy Zendesk number).
  - If no case matches, it creates a new Case and emails the user from Custom Setting `Email_to_Case_Error_User__c.getInstance('User ID').User_ID_who_should_get_email__c`.
  - Test: `TestEmailServiceToFindMatchingCase`.
- **`unsubscribe`**
  - If the subject contains "unsubscribe", sets `HasOptedOutOfEmail=true` on Contacts and Leads that match the sender address.
- The Email Service definitions and addresses are not in the repo.

## Target-org configuration NOT in this repo

| Item | Type | Used by |
|---|---|---|
| `Odie_API_Credential` | Named Credential (+ External Credential / auth) | All Odie callouts |
| `omni_commerce` | Named Credential (URL only) | `ODALeadController.getFEComparisonToolUrl` |
| `reliashield_comparison_pdf` | Named Credential (URL only) | `OdaReliashieldController`, its test |
| `dvoicu_odie_local` | Named Credential (commented-out dev reference) | `ODALeadController.cls:644` |
| Remote Site Settings for `agents-cti-picker-prod.adh8.com`, `agents-cti-picker-staging.adh8.com`, `salesforce-cheat-sheet-staging.adh8.com` | Remote Site | `NotifyCTI`, Cheatsheet controllers |
| `Email_to_Case_Error_User__c` | Hierarchy/List Custom Setting (record `User ID`) | `EmailServiceToFindMatchingCase` |
| Email Services for `EmailServiceToFindMatchingCase` and `unsubscribe` | Email Service | Inbound email |
| Lead record type `Life_Leads`, field set `ODA_Info_Block`, object `ODA_Policy__c`, User fields `Odie_Agent_ID__c` / `LumicoID__c` | Metadata | ODA classes |
| Visualforce pages for the Cheatsheet controllers; LWC/Aura UIs for ODA controllers | UI | — |
