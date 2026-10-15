# Cheat Sheets (Lead / Opportunity)

Visualforce controllers that build a one-page rep "cheat sheet". The VF pages themselves are not in this source folder. Both controllers share the same callout helper (duplicated code).

## Shared external service

| Item | Value |
|---|---|
| Base URL | `https://salesforce-cheat-sheet-staging.adh8.com` (**staging URL hardcoded – used in every environment**) |
| Paths | `/lead_familiar_names/{LeadId}`, `/account_familiar_names/{AccountId}`, `/state_marketplace_stats/{State}`, `/metric/vpl_clegs` (all with `?format=json`) |
| Method | GET (synchronous, in constructor / getters) |
| Auth | `Authorization: BASIC base64('[REDACTED – see LeadCheatsheetController.cls:81 / OpportunityCheatsheetController.cls:98]')` – **hardcoded credentials**; no Named Credential |
| Error handling | non-200 → `''`; JSON parse errors swallowed (`catch(Exception e) {}`) |

---

## LeadCheatsheetController

- **Purpose:** Lead cheat sheet with colleagues/familiar names, marketplace stats, activities, notes, campaigns, carrier promos; inline edit.
- **Entry points:** constructor (reads `id` URL param; performs callout), `save()` (update Lead + redirect), `edit()`, `cancel()`, `pullRequest(String)`, getters `getMarketplaceStats()`, `getActivityHistories()`, `getOpenActivities()`, `getNoteList()`, `getCampaignHistories()`, `getCarrier()`, `getVplclegs()`.
- **Lead fields read/edited:** `OwnerId`, `Name`, `Company`, `Carrier__c`, `Phone`, `MobilePhone`, `Alt_Phone_2__c`, `Email`, `Sales_Leader__c`, `Partner_Contact__c`, `Status`, `Lost_Reason__c`, `Unqualified_Reason__c`, address fields, `nickname__c`, `Secretary_s_Name__c`, `Additional_DM__c`, `Additional_DM_Email__c`.
- **Other reads:** Contact/Account (`Account.Wizard_Complete_Date__c`, `Account.Carrier__c`) for Account Ids returned by the service; `Carrier__c.Current_Promos__c`; ActivityHistories, OpenActivities, Note, CampaignMember.
- **Risks:** Callout in constructor on every page load; each getter that calls `pullRequest` (stats, vpl_clegs) makes another callout per render. Unbounded child queries (ActivityHistories etc.).
- **Test:** TestLeadCheatsheet (uses MockHttpResponseGenerator).

## OpportunityCheatsheetController

- **Purpose:** Same as above for an Opportunity, including Account/Contact edit and stage history.
- **Entry points:** constructor, `save()` (updates Opportunity, Contact **and** Account), `edit()`, `cancel()`, `pullRequest`, getters `getMarketplaceStats()` (by `Account.BillingState`), `getActivityHistories()`, `getOpenActivities()`, `getOpportunityStageHistories()`, `getNoteList()`, `getCarrier()`, `getRelatedContactList()`, `getCampaignHistories()`, `getVplclegs()`.
- **Fields:** Opportunity `Lost_Reason__c`, `StageName`, `CloseDate`, `NextStep`, `Type`; Account `Carrier__c`, billing address, `Wizard_Complete_Date__c`; Contact `Phone`, `MobilePhone`, `Alt_Phone_2__c`, `Email` (first Contact from OpportunityContactRole); `Carrier__c.Current_Promos__c`.
- **Defects found in code:**
  - `getCarrier()` (L154) tests `lead.Carrier__c == null` – there is no `lead` variable; Apex resolves this to the `Lead.Carrier__c` field token, which is never null, so the guard never short-circuits.
  - Constructor `contact` query has no null handling – throws `QueryException` if the opp has no contact roles.
- **Test:** TestOpportunityCheatsheet.

## JsonParseFamiliarNames

- DTO: `colleagues` (List<String> Account Ids), `familiar_names` (List<String>), `distance` (Integer); `static parse(String json)`.

## JsonParseMarketplaceStats

- DTO: `consumers`, `unsold_consumers` (inner `Consumers`: `premium`, `preferred`, `standard`, `non_standard`), `share_rate` (Double), `unsold_leads` (Integer); `static parse(String json)`.

## WrapperContactTenure

- DTO: `contact`, `account`, `tenure` = months between `Account.Wizard_Complete_Date__c` and today (null if date blank).

## MockHttpResponseGenerator (test)

- `@isTest global` `HttpCalloutMock`: returns `{"distance": 0, "colleagues": [], "familiar_names": []}` for `/lead_familiar_names/` and `/account_familiar_names/`, else empty body, status 200. Also used by EventHandlerTest and several activity tests.
