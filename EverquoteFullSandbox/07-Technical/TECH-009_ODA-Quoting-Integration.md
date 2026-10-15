# ODA / Odie Quoting Integration – Apex Technical Reference

Source: `force-app/main/default/classes`. Business one-liners come from `docs/07-Technical-Documents/Reference-Files/ApexClass_BusinessSummary.csv`. Technical detail below comes from reading the code. Nothing here is inferred beyond what the code shows.

## 1. What ODA / Odie is, based on the code

- **Odie** is an external EverQuote REST service. Every call goes through the Named Credential **`Odie_API_Credential`** (`callout:Odie_API_Credential/<path>`). The base URL and auth live in that Named Credential, which is **not in this repo**.
- **ODA** is the prefix for the Salesforce-side Apex classes. Agents use them to quote, rate and start e-applications (e-apps) for **Life Leads** (Lead record type `Life_Leads`) across carriers: **Lumico** (products `sife`, `siterm`, `term`, `term19`, `ad`, `wl`), **AIG**, **Gerber** and **Reliashield**. They also save the resulting policies as `ODA_Policy__c` records.
- Odie also keeps a copy of the lead (a "form" plus a lead). Salesforce pushes these to Odie:
  - lead creation
  - owner changes
  - `Lead_Outcome__c` (sales disposition) changes
- Odie also exposes Twilio call-recording pause/resume (`/twilio/pause_recording`, `/twilio/resume_recording`).
- Odie Lead identity: `Lead.EqLeadUuid__c` (and `OriginalEqLeadUuid__c`). Odie agent identity: `User.Odie_Agent_ID__c`. Lumico agent identity: `User.LumicoID__c`.
- None of the ODA controllers is referenced by an LWC, Aura component or Visualforce page in this repo. The UI callers live outside the repo (profiles only grant class access).

## 2. Architecture

```mermaid
flowchart LR
  UI["LWC/Aura (not in repo)"] -->|@AuraEnabled| C
  subgraph C[Controllers]
    AIG[ODAAigController]
    GER[OdaGerberController]
    LUM[OdaLumicoQuoteController]
    REL[OdaReliashieldController]
    RAT[OdaRatesController]
    LEAD[ODALeadController]
    EAPP[ODAEAppController]
    POL[ODAPolicyController]
    NEW[ODANewLifeLeadController]
  end
  AIG & GER & LUM & REL --> QP[OdaQuoteRequestProvider]
  RAT --> RP[OdaRatesRequestProvider]
  QP --> QB["OdaQuoteRequestBuilder (abstract)<br/>Aig / Gerber / LumicoAd / LumicoWl / Reliashield"]
  RP --> RB["OdaRatesRequestBuilder (abstract)<br/>Aig / Gerber / LumicoAd / LumicoWl / Reliashield"]
  QB & RB -. "DTOs: OdaQuoteRequestData, OdaRateLookupData, Rider, ODAPolicyDto" .- C
  AIG & GER & LUM & REL & RAT & EAPP & POL --> RC[ODARequestCallout]
  LEAD -->|"own processODARequest"| NC
  RC --> NC[("Named Credential<br/>Odie_API_Credential")]
  NEW --> OW[OdieWrapper]
  TRG["LeadTrigger → LeadHandler"] -->|@future| OW
  FLOW["syncLeadOwnerToOdie (Invocable)"] -->|@future| OW
  OW --> NC
  RC -->|non-200| EX["ODAException / ODABusinessRuleException"]
  NC --> ODIE[(Odie REST API)]
```

**Layers**

| Layer | Classes | Role |
|---|---|---|
| Controllers | `ODAAigController`, `OdaGerberController`, `OdaLumicoQuoteController`, `OdaReliashieldController`, `OdaRatesController`, `ODALeadController`, `ODAEAppController`, `ODAPolicyController`, `ODANewLifeLeadController`, `ODALeadOutcomeController`, `OdaUserInfoBlockController` | `@AuraEnabled` entry points |
| Providers (factory) | `OdaQuoteRequestProvider`, `OdaRatesRequestProvider` | Pick the builder from `carrier` (and from `product` for Lumico). Throw `ODAException` for an unknown or blank carrier or product |
| Builders | abstract `OdaQuoteRequestBuilder.baseRequest()` and `OdaRatesRequestBuilder.baseRequest()`, plus carrier subclasses | Build the request maps |
| Callout | `ODARequestCallout` (`post`/`get`), `OdieWrapper.processOdieRequest`, `ODALeadController.processODARequest` | HTTP to `callout:Odie_API_Credential/` |
| DTOs | `OdaQuoteRequestData` (lead, carrier, product, faceAmount, riskClass, termLength, `List<Rider>` riders), `OdaRateLookupData` (lead, carrier, product, riskClass, amounts), `Rider` (product, amount, units), `ODAPolicyDto` (id, policyNumber, carrier, product, coverageAmount, quoteId, recordingWasPaused, cannotGetPolicyNumber, riskClass), `OdaUserInfoBlockController.LeadAndFieldSet` | Data passed between the UI and Apex |
| Exceptions | `ODAException` (+`initialMessage`), `ODABusinessRuleException` (+`code`) | Error mapping |
| Utils | `OdaUtils` | `formatBirthDate` (MM/dd/yyyy), `getCurrentAgentId` (`User.LumicoID__c`), `getCurrentOdieAgentId` (`User.Odie_Agent_ID__c`), `getLink(devName)` (SOQL on `NamedCredential.Endpoint`; throws `ODAException('NameCredentials not found for key: …')`) |
| Odie sync | `OdieWrapper`, `syncLeadOwnerToOdie` | Lead create, owner and disposition push |
| Test mock | `OdieRequestCalloutMock` | `HttpCalloutMock`. Records `urlsRequestBody[path] = body` so tests can assert on the payload |

## 3. Carrier matrix

| Carrier / product | Quote controller (entry point) | Quote request builder | Rates request builder (via `OdaRatesController.getRates`) | Test classes |
|---|---|---|---|---|
| AIG | `ODAAigController.getConfirmedQuotes` → `Map<Integer, Map<String,Object>>` | `OdaAigQuoteRequestBuilder` (base request only) | `OdaAigRateRequestBuilder`. Face amounts 5k/10k/15k/20k/25k | `ODAAigControllerTests`, `OdaRatesControllerTests` |
| Gerber | `OdaGerberController.getConfirmedQuotes` → `List<Map<String,Object>>` | `OdaGerberQuoteRequestBuilder` (base) | `OdaGerberRatesRequestBuilder`. 5k–25k step 5k | `OdaGerberControllerTests`, `OdaRatesControllerTests` |
| Lumico AD (`ad`) | `OdaLumicoQuoteController.getQuotes` | `OdaLumicoAdQuoteRequestBuilder` (base) | `OdaLumicoAdRatesRequestBuilder`. 100k–250k step 25k, plus `tobacco` | `OdaLumicoQuoteControllerTests`, `OdaRatesControllerTests` |
| Lumico WL (`wl`) | `OdaLumicoQuoteController.getQuotes` | `OdaLumicoWlQuoteRequestBuilder`. Adds `height`/`weight` (`Height_new__c`/`Weight_new__c`), `riders`, `risk_class` | `OdaLumicoWlRatesRequestBuilder`. Its own body: state, gender, birth_date, `amount_band`, eq_lead_uuid, tobacco, has_major_condition, height, weight, risk_class | same as AD |
| Lumico `sife` / `siterm` / `term` / `term19` | `ODALeadController.getQuotes`, `getRates`, `getQuoteIncludingRiders`, `getRiderRates` (do not go through the providers) | inline `buildQuotesRequestBody` (carrier hardcoded to `lumico`) | inline `buildRatesRequestBody` / `buildLevelTermRatesRequestBody` | `ODALeadControllerTests` |
| Reliashield | `OdaReliashieldController.getConfirmedQuote`, `getReliashieldComparisonPdfUrl` | `OdaReliashieldQuoteRequestBuilder` (base) | `OdaReliashieldRateRequestBuilder`. Body is `{product}` only | `OdaReliashieldControllerTests`, `OdaRatesControllerTests` |

**Base quote body** (`OdaQuoteRequestBuilder.baseRequest`):

```
{ eq_lead_uuid, client:'salesforce',
  consumer_data:{ eq_lead_uuid, carrier, product_name, state, birth_date, gender(1st char),
                  uses_tobacco, modified, has_major_condition, face_amount } }
```

`has_major_condition` is true when the first character of `Major_Condition_Past_Year__c` is `Y`.

**Base rates body** (`OdaRatesRequestBuilder.baseRequest`): `{ age (Age__c), gender, product, face_amounts }`.

**Face-amount ladder:** AIG and Gerber quote `faceAmount ± 1000`, and only keep amounts between 5,000 and 25,000. That means up to 3 sequential callouts per request.

## 4. Class reference

### ODARequestCallout

- **Entry points:**
  - `post(path, params)` – defaults `client='salesforce'`, `odie_agent_id` (User.Odie_Agent_ID__c) and `agent_email` (UserInfo email).
  - `get(path, params)`.
- **Request:** endpoint `callout:Odie_API_Credential/` + path, header `Content-Type: application/json`, JSON body. No `setTimeout` (platform default applies).
- **Response:** HTTP 200 returns the body as a String. Any other status is mapped to an error:
  - body not parseable → `ODAException('Error processing request. Please try again.')`
  - body has `error` → `ODAException(error)`. "No Quote found for quote_id…" is rewritten to "No previous application was found."
  - body has `business_rule` → `ODABusinessRuleException`
  - anything else → generic `ODAException`.
- **Defect:**
  - `get()` builds a query-string endpoint (line 19) but never uses it.
  - `processRequest` always calls `setMethod('POST')` (line 31) and ignores `requestMethod`.
  - Result: "GET" rate lookups are actually sent as POST with a JSON body.

### ODALeadController (817 lines; Lumico core plus helpers)

`@AuraEnabled` methods:

- `userHasTheRightSkillsAndLicenses(leadId, product)` – checks `User.Product_Skills__c` contains `-product-` and `User.HealthStatesLicensedIn__c` contains `Lead.State`. Also selects `StatesLicensedIn__c`.
- `pauseRecording(leadId)` / `resumeRecording(leadId)` – POST `/twilio/pause_recording` or `/twilio/resume_recording` with `{phone_number, eq_lead_uuid, task_sid (Twilio_Task_Sid__c)}` via `ODARequestCallout`.
- `getFEComparisonToolUrl(age, gender, tobacco, eqLeadUuid)` – builds a URL from the `NamedCredential.Endpoint` of `omni_commerce` plus a query string (`advisor_id` = user email). No callout.
- `findById(leadId)` – reads the Lead fields listed in section 5.
- `saveBirthDate`, `saveAdditionalLevelTermInformation` (`Height_new__c`, `Weight_new__c`), `saveLeadRequiredInformation` (`Gender__c`, `State`, `Date_of_Birth__c`) – Lead updates.
- `getQuotes(lead, product, termLengths, faceAmount, riskClass)`:
  - `sife` loops face amounts, capped by risk class and age (`SIFE_*` constants: 5k min; modified 15k; standard 30k; preferred 50k with age bands).
  - `siterm` and level term (`term`/`term19`) loop term lengths (default 10/15/20/30).
  - Each iteration POSTs to `quotes`.
- `getRates(...)`:
  - sife/siterm send GET `carriers/lumico/products/<p>/rate_lookup?…` and compute `rate_per_thousand × amount`.
  - level term sends POST to the same path.
  - siterm swallows per-term `ODAException` and only rethrows if every term fails.
- `getRiderRates(...)` – POST `riders/<rider.product>/rates`.
- `getQuoteIncludingRiders(...)`.

Callouts use its own private `processODARequest`. Error mapping is the same as `ODARequestCallout`, except there is no "No Quote found" rewrite. That method does honour the GET method and query string.

`processOdieRequest` (`@TestVisible`) is a duplicate of `OdieWrapper.processOdieRequest`. It returns `'{}'` on a non-200 response.

Commented-out debug endpoints:
- line 163: `https://enhihxmqlj8l.x.pipedream.net/`
- line 644: `callout:dvoicu_odie_local/`

### ODAEAppController

- `loadPreviousApplications(lead, carrier, product)`:
  - Reads `ODA_Policy__c` (`Quote_Id__c`) where `Carrier__c`, `Product__c` and `Lead__c` match, ordered by `Created_at__c`.
  - Throws `ODAException` if there are none.
  - POSTs `e_apps/previous_e_apps` with `{carrier, product, eq_lead_uuid, quotes[]}`.
- `openPreviousApplication(lead, carrier, product, quoteId)` – POST `e_apps`.
- `getEApp(lead, quoteId, faceAmount, carrier, product)`:
  - POST `e_apps`, then `updateLeadAfterEApp`.
  - For Lumico, sets `Lumico_Quote_ID__c`. For Lumico `sife`, also sets `Coverage_Amount__c` from `sifeFieldValueMap`.
  - Inserts `ODA_Policy__c` (Name `N/A`, `Lead__c`, `Carrier__c`, `Product__c`, `Quote_Id__c`, `Coverage_Amount__c`) if no policy exists for that `Quote_Id__c`.
- `buildEappRequestBody` (public, reused by ODAPolicyController):
  - Top level: `eq_lead_uuid`, `quote_id`, `carrier`, `product_name`, `agent_id` (LumicoID__c), `odie_agent_id`, `client`.
  - `consumer_data`: name, address, weight/height, gender, `family_status` (Marital_Status__c), email, phone, birth_date.
  - For `term`/`term19`, height and weight come from `Height_new__c`/`Weight_new__c`.

### ODAPolicyController

- `findPolicy(leadId, carrier, product)` / `findPolicies(leadId)` – query `ODA_Policy__c` with `Name='N/A'`.
- `levelterm` is mapped to `term` (states DE, MT, ND, SD, FL, CA) or `term19` (all other states), and mapped back for display.
- `savePolicies(leadId, List<ODAPolicyDto>)`:
  - POSTs `e_apps/save_policies` with `{eq_lead_uuid, policies[]}`. A policy without a quoteId gets an embedded `e_app`.
  - Inserts `ODA_Policy__c` for each entry in `new_policies` in the response.
  - Updates the `Name` / `Coverage_Amount__c` of existing policies that are not in `failing_policies`.
  - Note: `update odaPolicies` is inside the for-loop (line 155).

### ODANewLifeLeadController

- `createNewLifeLead(Lead)`:
  - Calls `OdieWrapper.createRecordsForNewSalesforceLead` synchronously (Odie `forms`, then `forms/<uuid>/leads`).
  - Sets `EqLeadUuid__c` and the `Life_Leads` record type, then inserts the Lead.
- `findById` delegates to `ODALeadController`.

### Other controllers

- **ODALeadOutcomeController** – no callouts. `getById`, `getLeadOutcomeOptions` (picklist describe of `Lead_Outcome__c`), `updateLeadOutcome`. The update path indirectly triggers the Odie disposition sync through `LeadTrigger`.
- **OdaUserInfoBlockController** – no callouts. `getLeadUserInfo(leadId)` runs dynamic SOQL over Lead field set **`ODA_Info_Block`** and returns `LeadAndFieldSet`.

### OdieWrapper (global)

| Method | Odie path | Payload |
|---|---|---|
| `createForm(Lead)` | `forms` | arrival_uuid (generated from `Crypto.GenerateAESKey`), client, us_state, currently_insured, uses_tobacco, lead_source (`Oda_New_Lead_Source__c`), lead_created_by, owner block, phone_number, birth_date, marital_status, residence_type, gender M/F, original_eq_lead_uuid |
| `createLead(formUuid, Lead)` | `forms/<uuid>/leads` | contact, address, coverage, health fields; `vertical:'Life'` |
| `createRecordsForNewSalesforceLead(Lead)` | both of the above | returns `eq_lead_uuid` (or the existing value) |
| `createRecordsForNewSalesforceLeadsFuture(Id[])` @future | both, per lead | then `update leads` with `EqLeadUuid__c` |
| `syncLeadOwnerToOdie(Lead)` / `syncLeadOwnerToOdieFuture(Id[])` @future | `forms/update_owner` | eq_lead_uuid, lead_owner (Owner.Email, else Owner.Name), lead_owner_updated_by, lead_owner_updated_at (`Assigned_Date__c`) |
| `updateFormDisposition(Id)` / `updateFormDispositionFuture(Id[])` @future | `forms/update_sales_disposition` | lead_outcome, phone, eq_lead_uuid, updated_by, updated_at (LastModifiedDate) |

`processOdieRequest` returns `'{}'` on any non-200 response. There is no exception and no logging of the status. One callout is made per lead inside loops.

**Triggering components:**
- `LeadTrigger` → `LeadHandler.afterInsert` (Life_Leads record type) → owner sync if `EqLeadUuid__c` is set, otherwise create.
- `LeadHandler.afterUpdate` → owner change (only when `EqLeadUuid__c` is set) and `Lead_Outcome__c` change.
- `syncLeadOwnerToOdie.sync` – `@InvocableMethod(label='LeadOwnerSync')`. No flow in the repo calls it.
- Legacy triggers `LifeLeadCreated`, `LeadOwnerUpdated` and `LeadOutcomeUpdated` are **Inactive**.

## 5. Objects and fields referenced

- **Lead** (custom fields): `EqLeadUuid__c`, `OriginalEqLeadUuid__c`, `Lead_Outcome__c`, `Policy_Number__c`, `Coverage_Amount__c`, `Coverage_Type__c`, `Currently_Insured__c`, `Date_of_Birth__c`, `DUI_Conviction__c`, `Gender__c`, `Height__c`, `Weight__c`, `Height_new__c`, `Weight_new__c`, `Marital_Status__c`, `Military_Affiliation__c`, `Occupation__c`, `Residency__c`, `Use_Tobacco__c`, `What_is_your_major_condition__c`, `Major_Condition_Past_Year__c`, `Modified__c`, `Age__c`, `Assigned_Date__c`, `Oda_New_Lead_Source__c`, `Lumico_Quote_ID__c`, `Carrier__c` (+`Carrier__r.No__c`), `Twilio_Task_Sid__c`.
  - Field set: `ODA_Info_Block`.
  - Record type: `Life_Leads`.
- **ODA_Policy__c:** `Name`, `Lead__c`, `Carrier__c`, `Product__c`, `Quote_Id__c`, `Coverage_Amount__c`, `Created_at__c`. Read, inserted and updated.
- **User:** `LumicoID__c`, `Odie_Agent_ID__c`, `Product_Skills__c`, `StatesLicensedIn__c`, `HealthStatesLicensedIn__c`.
- **NamedCredential (setup object, queried):** `omni_commerce`, `reliashield_comparison_pdf`.
- The `objects/` folder in this repo is empty, so none of these field definitions are version-controlled here.

## 6. Exceptions

| Exception | Thrown when |
|---|---|
| `ODAException` | Non-200 Odie response; unknown or blank carrier or product (providers); unsupported Lumico product; missing carrier or product for the rates path; no previous e-app; Named Credential not found (`OdaUtils.getLink`) |
| `ODABusinessRuleException` | Odie returns `business_rule` in a non-200 body |
| Unhandled | NullPointerException if `Gender__c`, `Major_Condition_Past_Year__c`, `Date_of_Birth__c`, `Product_Skills__c` or `HealthStatesLicensedIn__c` is null (`substring` / `toLowerCase` calls) |

## 7. Test coverage approach

- Every ODA test uses `OdieRequestCalloutMock` (default 200 with `{"example":"test"}`, or the `(statusCode)` constructor with `{"error":"test error"}`, or `setMockStatusAndBody`).
- Tests assert on the captured request JSON via `mock.urlsRequestBody.get('<path>')`. Examples: `quotes`, `e_apps`, `e_apps/save_policies`, `twilio/pause_recording`, `riders/<p>/rates`, `carriers/<c>/products/<p>/rate_lookup`.
- Negative paths: `ODARequestCalloutTests` (400 with `business_rule`, null body, "No Quote found" rewrite), `ODALeadControllerTests` (error status), provider invalid-carrier tests (`OdaRatesControllerTests`, `OdaReliashieldControllerTests`, `OdaLumicoQuoteControllerTests`).
- `OdieWrapperTest` covers form, lead, disposition, owner sync and non-200 handling. `syncLeadOwnerToOdieTest` covers the invocable method.
- Caveat: `OdaReliashieldControllerTests.getReliashieldComparisonPdfUrlTest` depends on org setup.
  - It asserts that the message equals `'NameCredentials not found for key: dummy_pdf_url'`, but the code queries `reliashield_comparison_pdf`.
  - The test passes only when that Named Credential exists, because no exception is thrown. Without it, the assertion fails.
- Exception classes are covered by `ODAExceptionTests` and `ODABusinessRuleExceptionTests`.
