# Customer Enrollment Portal – Technical Documentation (POC)

| Item | Value |
|---|---|
| Salesforce org | `EnrollmentDev` (Developer Edition, API 68.0) |
| SFDX project | `customer-enrollment-portal` |
| Experience Cloud site | Customer Enrollment Portal (`Customer_Enrollment_Portal1`), Build Your Own (LWR), URL prefix `customerenrollment` |
| Status | POC deployed to EnrollmentDev. Site **not published**, **login-only**, guest access **not enabled** |

This document describes what is implemented in the project source (`force-app/main/default`) and what was deployed to EnrollmentDev. Items that exist in the org but are **not** in the local source (for example the Experience Builder page placement) are called out explicitly.

---

## 1. Project Overview

### 1.1 What the project does
A customer fills in a multi-step enrollment form on an Experience Cloud site: company details plus two or more contacts. The submission is stored in Salesforce as **exactly one Lead**. The contacts are kept on that Lead as structured JSON. No Account and no Contact is created at submission time.

An internal Salesforce user later reviews the Lead. On the Lead record page they see the submitted contacts in a readable table, and they convert the Lead through a custom path and conversion screen. Conversion creates (or uses) **one Account**, creates **one standard Contact per submitted person**, and links every Contact to that Account. It then completes the standard Salesforce Lead conversion without an Opportunity, all in one all-or-nothing transaction.

### 1.2 Why Typeform is being replaced
The business requested replacing the existing Typeform enrollment form with a Salesforce-native solution. The implemented solution delivers:
- Submissions land directly in Salesforce as Leads, with no third-party form or integration step.
- Validation is enforced on the server, against Salesforce field limits and the org's State/Country picklists.
- Multiple contacts per company are captured and later turned into real Contact records on conversion.
- Duplicate submissions and repeated conversions are prevented by the platform (unique keys and record locking).

### 1.3 Business requirements (as implemented)
| # | Requirement | Where it is enforced |
|---|---|---|
| R1 | One submission creates exactly one Lead | `EnrollmentSubmissionService.submit` |
| R2 | Company information is stored in standard Lead fields | `EnrollmentSubmissionService.buildLead` |
| R3 | All contacts are stored on the Lead (JSON) | `Lead.Enrollment_People__c`, `EnrollmentPeopleSerializer` |
| R4 | No Account/Contact at submission | Submission service inserts only a Lead |
| R5 | At least 2 and at most 25 contacts | LWC (`MIN_PEOPLE`/`MAX_PEOPLE`) **and** Apex (`EnrollmentValidator`) |
| R6 | All contacts are equal (no primary contact) | No primary flag anywhere. The Contact passed to `setContactId` is a platform requirement only |
| R7 | Contacts are visible on the Lead page in a readable way | `enrollmentPeoplePanel` ("Contacts (N)") |
| R8 | Authorized users convert with a custom screen | `enrollmentLeadPath` → `enrollmentConvertModal` → `EnrollmentConversionService` |
| R9 | Conversion: 1 Account, 1 Contact per person, same Account, no Opportunity | `EnrollmentConversionService.convert` |
| R10 | No duplicate submissions or repeated conversions | Unique submission key, `FOR UPDATE` lock, unique Contact key |
| R11 | Ordinary (non-enrollment) Leads keep standard behavior | Guard trigger scoped to enrollment Leads. Standard Path/Convert kept for ordinary Leads |

### 1.4 Solution architecture
```
Experience Cloud (LWR) site                         Lightning Experience (internal users)
┌──────────────────────────────┐                  ┌─────────────────────────────────────────────┐
│ enrollmentPortal              │                  │ Enrollment Lead Record Page (FlexiPage)      │
│  ├ enrollmentHeader           │                  │  ├ force:highlightsPanel                     │
│  ├ enrollmentWelcome          │                  │  ├ Standard Path   (ordinary Leads only)      │
│  ├ enrollmentForm ────────────┼── Apex ──┐       │  ├ enrollmentLeadPath (enrollment Leads only) │
│  │  ├ enrollmentStepIndicator │          │       │  │     └ opens enrollmentConvertModal         │
│  │  ├ enrollmentCompanySection│          │       │  ├ enrollmentPeoplePanel ("Contacts (N)")    │
│  │  ├ enrollmentPersonCard    │          │       │  └ detail panel, activity, related lists     │
│  │  ├ enrollmentReview        │          │       └─────────────────┬───────────────────────────┘
│  │  └ enrollmentConfirmation  │          │                         │ Apex
│  └ enrollmentFooter           │          ▼                         ▼
└──────────────────────────────┘  EnrollmentSubmissionController   EnrollmentPeopleController
                                   EnrollmentSubmissionService      EnrollmentConversionController
                                          │                         EnrollmentConversionService
                                          ▼                                  │
                                   1 Lead (+ JSON contacts)    1 Account + N Contacts + Lead conversion
```

### 1.5 Technologies used
| Technology | Usage |
|---|---|
| Salesforce Experience Cloud (LWR, Build Your Own template) | Hosts the enrollment form |
| Lightning Web Components (JavaScript, HTML, CSS) | Public form (native HTML inputs, custom CSS) and internal Lead UI (Lightning base components, SLDS) |
| Apex | Validation, Lead creation, people panel data, status updates, conversion |
| SOQL | Lead/Contact/Account/LeadStatus queries (`WITH USER_MODE`, `FOR UPDATE`) |
| Apex triggers | Conversion guard (new), status-trigger scoping (modified existing) |
| Lightning App Builder (FlexiPage metadata) | Lead record page with component visibility rules |
| Salesforce DX / `sf` CLI | Source format, deployments |
| Jest (`@salesforce/sfdx-lwc-jest`), ESLint, Prettier | Local LWC tests, linting, formatting |

---

## 2. Complete Component Inventory

### 2.A Lightning Web Components (18 bundles)

Status legend: **Active** = used by the site or Lead page. **Unused** = deployed but not placed anywhere.

#### Public form (Experience Cloud)

| Component | Status | Exposed / Target | Purpose & functionality | Parent → children | Apex (class.method) | Files | User interaction |
|---|---|---|---|---|---|---|---|
| `enrollmentPortal` | Active (needs Builder placement, see §9) | Yes: `lightningCommunity__Page`, `lightningCommunity__Default` | Page shell. The only component dragged onto the site page. Builder properties: `brandName`, `supportEmail`, `supportPhone`, `privacyPolicyUrl`, `termsUrl` | → `enrollmentHeader`, `enrollmentWelcome`, `enrollmentForm`, `enrollmentFooter` | None | `.html .js .css .js-meta.xml` | None directly; passes Builder properties to header and footer |
| `enrollmentHeader` | Active | No | Branding placeholder (logo mark, brand name, "Customer Enrollment"). Navigation, skip link and Start enrollment button were removed | Child of `enrollmentPortal` | None | `.html .js .css .js-meta.xml` | None (static) |
| `enrollmentWelcome` | Active | No | Hero section with the page's single `<h1>` "Customer Enrollment" and a short description. "How it works" cards and Start enrollment button were removed | Child of `enrollmentPortal` | None | `.html .js .css .js-meta.xml` | None (static) |
| `enrollmentForm` | Active | No | Form controller. Owns all form state (company, contacts, errors), runs the steps Company → Contacts → Review → confirmation, validates, builds the request and submits. Generates a UUID submission key, records time-on-form, includes a hidden honeypot field | Child of `enrollmentPortal` → `enrollmentStepIndicator`, `enrollmentCompanySection`, `enrollmentPersonCard`, `enrollmentReview`, `enrollmentConfirmation` | `EnrollmentSubmissionController.getCountryOptions` (`@wire`), `EnrollmentSubmissionController.submitEnrollment` (imperative) | `.html .js .css .js-meta.xml`, `__tests__/enrollmentForm.test.js` | **Next**, **Back**, **Review**, **Submit**, **Add contact**, Remove contact (only when more than 2), **Edit** from Review. Shows a validation summary and server messages |
| `enrollmentStepIndicator` | Active | No | Progress indicator: Company / Contacts / Review | Child of `enrollmentForm` | None | `.html .js .css .js-meta.xml` | None (display only) |
| `enrollmentCompanySection` | Active | No | Renders the 9 company fields from `COMPANY_FIELDS`. Supplies Country options and the State options for the selected country | Child of `enrollmentForm` → `enrollmentField` | None | `.html .js .css .js-meta.xml` | Typing and selecting fire `companychange`/`companyblur` |
| `enrollmentPersonCard` | Active | No | One card per contact ("Contact 1", "Contact 2", …): First name, Last name, Email (required), Phone, Job title. Remove button | Child of `enrollmentForm` → `enrollmentField` | None | `.html .js .css .js-meta.xml` | Typing fires `personchange`/`personblur`; Remove fires `remove` |
| `enrollmentField` | Active | No | Reusable accessible field: label, native `<input>` or `<select>`, help text, error message, `aria-*` attributes | Child of `enrollmentCompanySection`, `enrollmentPersonCard` | None | `.html .js .css .js-meta.xml` | Fires `valuechange` (input/change) and `fieldblur` |
| `enrollmentReview` | Active | No | Read-only summary of company data (country/state shown by name) and all contacts ("Contacts (N)") | Child of `enrollmentForm` | None | `.html .js .css .js-meta.xml` | **Edit** buttons fire `edit` with step `company`/`people` |
| `enrollmentConfirmation` | Active | No | Success screen: icon, heading, "…information for N contacts", company email, "What happens next". The Start-new button was removed | Child of `enrollmentForm` | None | `.html .js .css .js-meta.xml` | None (focuses heading for screen readers) |
| `enrollmentFooter` | Active | No | Footer with brand, contact email/phone and Privacy/Terms links (only `https://` or site-relative URLs are rendered). Shows placeholders when not configured | Child of `enrollmentPortal` | None | `.html .js .css .js-meta.xml` | Links only |
| `enrollmentUtils` | Active (service module) | No | Field definitions (`COMPANY_FIELDS`, `PERSON_FIELDS`), `MAX_PEOPLE = 25`, `MIN_PEOPLE = 2`, client validation, duplicate email detection, `toSafeUrl` | Imported by form components | None | `.js .js-meta.xml`, `__tests__/enrollmentUtils.test.js` | — |
| `enrollmentStyles` | Active (CSS-only module) | No | Design tokens (primary `#163A63`, text `#172B4D`, background `#F4F7FB`), buttons, grid, utilities. Imported with `@import "c/enrollmentStyles"` | Imported by 11 bundles | None | `.css .js-meta.xml` | — |

#### Internal Lead UI (Lightning Experience)

| Component | Status | Exposed / Target | Purpose & functionality | Parent → children | Apex (class.method) | Files | User interaction |
|---|---|---|---|---|---|---|---|
| `enrollmentPeoplePanel` | Active on `Enrollment_Lead_Record_Page` | Yes: `lightning__RecordPage` (Lead) | Card **"Contacts (N)"**: read-only `lightning-datatable` (Name, Email, Phone, Job title). After conversion it adds a link to each created Contact and the converted Account. Renders nothing on non-enrollment Leads. Shows a readable message if the JSON is invalid | Placed on the FlexiPage | `EnrollmentPeopleController.getPeople` (`@wire`, cacheable) | `.html .js .css .js-meta.xml` | Links only (no buttons) |
| `enrollmentLeadPath` | Active on `Enrollment_Lead_Record_Page` | Yes: `lightning__RecordPage` (Lead) | Custom Lead status path styled with SLDS Path markup. Stages: Open - Not Contacted, Working - Contacted, Closed - Not Converted, Converted. Shown only when `Enrollment_Submission_Key__c` is set | Placed on the FlexiPage → opens `enrollmentConvertModal` | `EnrollmentPeopleController.updateLeadStatus` | `.html .js .js-meta.xml` | Click a stage to select it. **Mark as Current Status** / **Mark Status as Complete** update the status. Selecting **Converted** shows **Select Converted Status**, which opens the conversion modal. After success it navigates to the Account. Repeated clicks are ignored while the modal is open |
| `enrollmentConvertModal` | Active (opened by `enrollmentLeadPath`) | No (LightningModal) | Conversion screen. Account mode: **Create a new Account** (editable fields, Country/State comboboxes) or **Use an existing Account** (`lightning-record-picker`). Editable contacts "Contact 1…N". Warnings for duplicate names/emails | Opened by `enrollmentLeadPath` (and `enrollmentConvertAction`, unused) | `EnrollmentConversionController.getConversionPreview`, `EnrollmentConversionController.convertEnrollment`, `EnrollmentSubmissionController.getCountryOptions` | `.html .js .css .js-meta.xml` | **Convert** validates the inputs and calls Apex, then closes with `{ accountId }` and shows a toast. **Cancel** closes without changes |
| `enrollmentConvertAction` | **Unused**: deployed, removed from the Lead layout | Yes: `lightning__RecordAction` (headless, `actionType=Action`) | Launcher for the `Lead.Convert_Lead` quick action. Opens `enrollmentConvertModal`, then navigates to the Account | Was used by quick action `Lead.Convert_Lead` | None (the modal calls Apex) | `.js .js-meta.xml` | Not reachable in the UI at present |

### 2.B Apex Classes (16)

#### Production classes

| Class | Type | Sharing | Purpose | Key methods | Called by |
|---|---|---|---|---|---|
| `EnrollmentSubmissionController` | Controller | `with sharing` | Entry point for the public form | `@AuraEnabled submitEnrollment(String requestJson)` returns `EnrollmentSubmissionService.Result` (unexpected errors become a generic failure). `@AuraEnabled(cacheable=true) getCountryOptions()` | `enrollmentForm`, `enrollmentConvertModal` |
| `EnrollmentSubmissionService` | Service | `with sharing` (+ one private `without sharing` inner class) | Turns a submission into one Lead | `submit(String)`: size limit (64,000 chars), JSON parse, honeypot/time check (under 3 s = silent success, nothing saved), UUID key check, validation, key lookup, `Database.insert(lead, options, AccessLevel.USER_MODE)` with `DuplicateRuleHeader.allowSave = true`. `buildLead`, `normalizePeople` (assigns ids P01…P25), `handleInsertErrors` (maps duplicate-key → success, LeadHandler duplicate email → friendly message, picklist errors → country/state message). Inner `SubmissionKeyLookup.exists(key)` | `EnrollmentSubmissionController` |
| `EnrollmentRequest` | Model (DTO) | `with sharing` | Shape of the form request: `submissionKey`, `elapsedMs`, `faxNumber` (honeypot), `company` (`Company` inner class), `people` | — | Submission service, validator |
| `EnrollmentPerson` | Model (DTO) | `with sharing` | One contact: `id`, `firstName`, `lastName`, `email`, `phone`, `jobTitle`, `contactId` (display only, never stored) | — | All services and controllers |
| `EnrollmentPeopleSerializer` | Utility | `with sharing` | Writes and reads the `Enrollment_People__c` JSON (schema version 1). Parsing never throws | `serialize(List<EnrollmentPerson>)` (max 131,072 chars). `parse(String)` returns `ParseResult {valid, message, people}` | Submission service, people controller, conversion service |
| `EnrollmentValidator` | Utility | `with sharing` | Server-side rules shared by submission and conversion | `validateSubmission(EnrollmentRequest)` (adds the 2-contact minimum, `MIN_SUBMISSION_CONTACTS = 2`). `validateConversion(AccountInput, List<EnrollmentPerson>)`. `validatePeople` (1–25, required fields, lengths, email/phone formats, duplicate emails; messages "Contact N: …"). `clean(String)` | Submission and conversion services |
| `EnrollmentAddressOptions` | Utility | `with sharing` | Country and State options from the State/Country Picklists, including the state-to-country dependency (decoded from `validFor`) | `getCountries()`, `isValidCountry(code)`, `isValidState(country, state)` | Submission controller, validator |
| `EnrollmentPeopleController` | Controller | `with sharing` | Lead page data and status updates | `@AuraEnabled(cacheable=true) getPeople(Id leadId)` returns `PanelData` (isEnrollment, valid, message, people with contactId after conversion, isConverted, convertedAccountId, canConvert). `@AuraEnabled updateLeadStatus(Id leadId, String status)` sets **non-converted** statuses only (validated against `LeadStatus`), USER_MODE update | `enrollmentPeoplePanel`, `enrollmentLeadPath` |
| `EnrollmentConversionController` | Controller | `with sharing` | Entry point for the conversion modal. Converts exceptions to `AuraHandledException` with readable messages | `@AuraEnabled getConversionPreview(Id leadId)`, `@AuraEnabled convertEnrollment(Id leadId, String requestJson)` | `enrollmentConvertModal` |
| `EnrollmentConversionService` | Service | `with sharing` | All-or-nothing multi-Contact conversion | `getPreview(Id)` (account from Lead, contacts, warnings, permission check). `convert(Id, String)` (see §4.2). `personKey(leadId, personId)`. `isConversionInProgress()` (read by the guard). Inner classes `AccountInput`, `ConversionRequest` (`account`, `people`, `existingAccountId`), `Preview`, `Result` (`success`, `alreadyConverted`, `accountId`, `contactCount`, `message`). Constant `PERMISSION = 'Convert_Enrollment_Leads'` | Conversion controller, people controller, guard handler |
| `EnrollmentLeadTriggerHandler` | Trigger handler | `with sharing` | Blocks standard conversion of enrollment Leads | `beforeUpdate(List<Lead>, Map<Id, Lead>)`: adds an error when `IsConverted` changes to true, the Lead has an enrollment key, and the custom service is not running | `EnrollmentLeadTrigger` |
| `EnrollmentException` | Exception | `with sharing` | Expected, user-safe errors | — | Services |

#### Test classes

| Class | Type | Test methods |
|---|---|---|
| `EnrollmentTestFactory` | Test utility (`@IsTest public`) | `createUser(Boolean withConverterPermission)`, `createUserWithoutEnrollmentAccess()`, `person(...)`, `request(Integer)`, `newUuid()`, `submit(EnrollmentRequest)`, `conversionRequestJson(Preview)` |
| `EnrollmentSubmissionServiceTest` | Test | `validSubmissionCreatesExactlyOneLeadWithPeople`, `repeatedSubmissionKeyCreatesOnlyOneLead`, `invalidSubmissionReturnsErrorsAndCreatesNothing`, `fewerThanTwoContactsIsRejected`, `moreThanMaximumPeopleIsRejected`, `botSignalsAreAcceptedSilentlyWithoutSaving`, `malformedOrMissingKeyIsRejected`, `countryOptionsIncludeStates`, `serializerRejectsInvalidData` |
| `EnrollmentConversionServiceTest` | Test | `conversionCreatesOneAccountAndAllContacts`, `secondConversionDoesNotCreateRecords`, `invalidEditsRollBackEverything`, `conversionRequiresCustomPermission`, `standardConversionIsBlockedForEnrollmentLeads`, `guardDoesNotAffectNormalLeads` |
| `EnrollmentPeopleControllerTest` | Test | `returnsPeopleForEnrollmentLead`, `ignoresNormalLeadsAndReportsBadData` |

### 2.C Triggers

| Trigger | Object / Events | Status | Purpose |
|---|---|---|---|
| `EnrollmentLeadTrigger` | Lead, `before update` | **New** | Calls `EnrollmentLeadTriggerHandler.beforeUpdate`, which blocks standard (and API) conversion of enrollment Leads |
| `LeadStatusChange` | Lead, `before update` | **Existing, modified** | It already set `Status = 'Working-Contacted'` on every Lead update. A guard was added so it **skips Leads with `Enrollment_Submission_Key__c`**. Ordinary Leads keep the original behavior |

### 2.D Custom Fields

| Object | API name | Type | Notes |
|---|---|---|---|
| Lead | `Enrollment_People__c` | Long Text Area (131,072) | Contacts as JSON. Written only by Apex. Not on page layouts |
| Lead | `Enrollment_Person_Count__c` | Number (3,0) | Integrity check and reporting |
| Lead | `Enrollment_Submission_Key__c` | Text (36), **External ID, Unique** | Form-generated UUID (lower-case). Identifies enrollment Leads and prevents duplicate submissions |
| Lead | `Enrollment_Submitted_At__c` | Date/Time | Server timestamp |
| Contact | `Enrollment_Person_Key__c` | Text (40), **External ID, Unique** | `LeadId:PersonId` (for example `00Q…:P01`). At most one Contact per submitted person |
| Contact | `Enrollment_Source_Lead__c` | Lookup (Lead), SetNull | Links each Contact to its enrollment Lead |

### 2.E Security metadata

| Component | Type | Contents | Assignment |
|---|---|---|---|
| `Convert_Enrollment_Leads` | Custom Permission | Required to convert enrollment Leads | Via `Enrollment_Converter` |
| `Enrollment_Converter` | Permission Set | Custom permission. Apex access: `EnrollmentConversionController`, `EnrollmentPeopleController`, `EnrollmentSubmissionController`. Read-only Lead enrollment fields. Read/edit Contact enrollment fields | Assigned to Sivalingam Karthik (admin) |
| `Enrollment_Submission` | Permission Set | Lead **Create + Read** (Read is required by the platform for Create). Edit on Lead enrollment fields, `Website`, `Email`, `Phone`, `LeadSource`. Apex access: `EnrollmentSubmissionController` | Assigned to Sivalingam Karthik. **Not assigned to the guest user** |

### 2.F Page, layout and action metadata

| Component | Type | Status | Details |
|---|---|---|---|
| `Enrollment_Lead_Record_Page` | FlexiPage (`flexipage:recordHomeTemplateDesktop`) | Active, **org default for Lead (desktop)** | Header: `force:highlightsPanel`, standard `runtime_sales_pathassistant:pathAssistant` (visibility rule: shown only when `Enrollment_Submission_Key__c` is blank), `enrollmentLeadPath`. Main: `enrollmentPeoplePanel`, `force:detailPanel`. Sidebar: `runtime_sales_activities:activityPanel`, `force:relatedListContainer` |
| `Lead.object-meta.xml` | CustomObject (object-level settings only) | Modified | Only the `View` action override for `formFactor=Large` was changed, to `Flexipage` → `Enrollment_Lead_Record_Page`. All other settings were copied unchanged from the org |
| `Lead-Lead Layout` | Page Layout | Modified | `Lead.Convert_Lead` was added and later **removed** from the Lightning action list. Standard **Convert** is kept (for ordinary Leads) |
| `Lead.Convert_Lead` | Quick Action (LWC) | **Unused** | Label "Convert Lead", component `enrollmentConvertAction`. Not on any layout |

### 2.G Experience Cloud metadata (existing, not modified by code)
- `digitalExperiences/site/Customer_Enrollment_Portal1/**` and `digitalExperienceConfigs/Customer_Enrollment_Portal1…xml` were retrieved before development and are unchanged in source.
- `sfdc_cms__site` `authenticationType = "AUTHENTICATED"`: the site requires login, and public access is off.
- The `enrollmentPortal` component was placed on the Home page **in Experience Builder**. That change is **not in local source**; retrieve `DigitalExperience:site/Customer_Enrollment_Portal1.sfdc_cms__view/home` to bring it into the project.

### 2.H Removed during development
`EnrollmentConversionSpikeTest`, a verification spike, was validated only with check-only deployments. It was never saved to the org and was deleted from the project.

---

## 3. Data Model

### 3.1 Lead mapping at submission
| Form field | Lead field |
|---|---|
| Company name | `Company`, and `LastName` (company name cut to 80 characters, because no contact is "the Lead") |
| Website | `Website` |
| Company email | `Email` |
| Company phone | `Phone` |
| Address / City / Postal code | `Street` / `City` / `PostalCode` |
| Country / State | `CountryCode` / `StateCode` (State and Country Picklists are enabled) |
| — | `LeadSource = 'Web'`, `Status` = org default (`Open - Not Contacted`) |
| Contacts | `Enrollment_People__c` (JSON), `Enrollment_Person_Count__c` |
| Submission key / time | `Enrollment_Submission_Key__c`, `Enrollment_Submitted_At__c` |

### 3.2 `Enrollment_People__c` JSON (schema version 1)
```json
{"schemaVersion":1,"people":[
  {"id":"P01","firstName":"…","lastName":"…","email":"…","phone":"…","jobTitle":"…"},
  {"id":"P02", "...": "..."}
]}
```
- `id` is assigned by the server (P01…P25) and never changes. It is used for edits on the conversion screen and for `Contact.Enrollment_Person_Key__c`.
- Null values are omitted. Maximum: 25 contacts. Worst case is about 21,000 characters, against a field limit of 131,072.
- Invalid or unsupported JSON is never shown raw. The panel shows a message, and conversion is blocked.

### 3.3 Conversion mapping (per contact)
| Contact field | Value |
|---|---|
| `AccountId` | The single new Account or the selected existing Account |
| `FirstName`, `LastName`, `Email`, `Phone`, `Title` | Submitted (or edited) values |
| `LeadSource` | `Web` |
| `MailingStreet/City/StateCode/CountryCode/PostalCode` | Company address from the conversion screen |
| `MobilePhone`, `Description` | `null` (re-applied after conversion) |
| `Enrollment_Person_Key__c`, `Enrollment_Source_Lead__c` | `LeadId:Pxx`, Lead Id |

New Account: `Name`, `Website`, `Phone`, `Billing*` from the screen, and `Industry = null` (re-applied after conversion).

---

## 4. Process Flows

### 4.1 Form submission
1. The visitor completes Company (9 fields) → Contacts (2 by default, up to 25) → Review, then clicks **Submit**.
2. `enrollmentForm` sends `{submissionKey, elapsedMs, faxNumber, company, people}`. The client-side `key` of each contact is not sent.
3. `EnrollmentSubmissionService.submit`:
   1. Rejects requests that are too large or unreadable.
   2. Bot signals (honeypot filled or under 3 s) get **success with nothing saved**.
   3. Checks that the submission key is a UUID.
   4. Runs `EnrollmentValidator.validateSubmission`. On failure it returns `errors[]`, which the form shows.
   5. If the key already exists (`SubmissionKeyLookup`), it returns success: a retry or double click.
   6. Inserts **one Lead** in USER_MODE with duplicate-rule `allowSave`.
4. The response is `{success, message, errors}` only. Record Ids and data are never returned.

### 4.2 Lead conversion (enrollment Leads)
1. On the Lead page, the user clicks the **Converted** stage in `enrollmentLeadPath`, then **Select Converted Status**.
2. `enrollmentConvertModal` loads `getConversionPreview` (account data from the Lead, contacts, warnings, permission check) and the country options.
3. The user chooses a new or existing Account, edits contacts if needed, and clicks **Convert**.
4. `EnrollmentConversionService.convert`, in **one transaction with a Savepoint**:
   1. Checks the custom permission, the Convert Leads permission and Create on Account/Contact.
   2. `SELECT … FOR UPDATE` on the Lead. If it is already converted, returns `alreadyConverted` (no changes).
   3. Parses the JSON. Merges the screen edits; every stored contact must be present exactly once.
   4. Validates the Account and contacts.
   5. Inserts the Account, or loads the selected existing Account (USER_MODE).
   6. Inserts N Contacts (USER_MODE, `allowSave`, unique person key).
   7. Runs `Database.convertLead` with `setAccountId`, `setContactId(contacts[0])` (a platform merge target, not a "primary" contact), the converted status from `LeadStatus` and `setDoNotCreateOpportunity(true)`. A static flag lets the guard trigger allow it.
   8. Re-applies the intended values to all Contacts and to a newly created Account. This undoes org automation effects and values that conversion merges into the target Contact.
   9. Any exception rolls back to the Savepoint and is rethrown. **No partial records remain, and the Lead stays unconverted.**
5. On success the modal closes with `{accountId}`, and the path navigates to that **Account**.

### 4.3 Status changes (first three stages)
Choosing Open - Not Contacted, Working - Contacted or Closed - Not Converted calls `EnrollmentPeopleController.updateLeadStatus`. It only accepts non-converted `LeadStatus` values and refuses converted Leads. The UI then refreshes through `notifyRecordUpdateAvailable`.

---

## 5. Interaction with Existing Org Automation

| Existing automation | Effect on enrollment records | Handling |
|---|---|---|
| `LeadTrigger` → `LeadHandler.LeadDuplicate` (before insert) | Blocks a new Lead whose Email matches any existing Lead (including blank emails) | Mapped to the message "An enrollment has already been received for this company email…". The trigger is unchanged |
| `LeadTrigger` → `LeadHandler.AfterInsertHandler` | Creates a "Follow up this task" Task per new Lead | Unchanged |
| `LeadStatusChange` | Overwrote Status on every update | Modified to skip enrollment Leads (§2.C) |
| Flow `Update_contact_phone_when_empty` | Sets `Phone = 999999999` on new Contacts without a phone | Conversion re-applies the submitted phone (blank stays blank) |
| Flow `Update_Account_Industry` | Sets `Industry = Technology` on new Accounts | Reset to `null` for Accounts the conversion creates |
| Flow `Contact_Industry_Flow` | Sets Contact `Description = 'IT Customer'` | Reset to `null` |
| Duplicate rules (Lead/Contact/Account, Allow + Alert) | Would fail Apex inserts | `DuplicateRuleHeader.allowSave = true` on enrollment DML |
| `ContacttriggerAcc` (`ContactAcc`) | Requires `AccountId`; updates the Account contact count | `AccountId` is always set |

Ordinary Leads, Contacts and Accounts are not affected by any of the handling above.

---

## 6. Security Design (current state)
- **All classes are `with sharing`.** Record and field access uses `WITH USER_MODE` queries and `AccessLevel.USER_MODE` DML.
- **One narrow `without sharing` exception:** `EnrollmentSubmissionService.SubmissionKeyLookup` runs an exact-match `COUNT()` on an unguessable UUID and returns a Boolean only. It exists because guest users cannot see Leads, and the existing LeadHandler trigger runs before the unique index.
- **Conversion permissions:** requires the custom permission `Convert_Enrollment_Leads` and the standard Convert Leads permission (via `UserPermissionAccess`).
- **No data leaks from submission:** the response contains no record data or Ids, and unexpected errors return a generic message.
- **Spam and duplicate protection:** honeypot, minimum fill time, request size cap, server-side validation, unique submission key.
- **Not implemented:** CAPTCHA and rate limiting.
- **Guest user:** unchanged. There are no object permissions and no Apex access, so the public form is **not** usable anonymously yet (§9).

---

## 7. Deployment History (EnrollmentDev)

| Deploy Id | Scope |
|---|---|
| `0Affj00000YkL2fCAF` | Initial 13 UI LWCs |
| `0Affj00000Yl2nZCAR` | Backend POC: fields, Apex, trigger, permission sets, custom permission, Lead page, LWCs (43 components) |
| `0Affj00000YlcawCAB` | Panel rename to Contacts, Convert Lead action, layout, status path on page |
| `0Affj00000YlmFLCAZ` | `enrollmentLeadPath`, existing-Account conversion, `updateLeadStatus`, `LeadStatusChange` scoping, page visibility rule |
| `0Affj00000Ym0F3CAJ` | Removed Convert Lead from the Lead layout |
| `0Affj00000YlpRiCAJ` | Contacts wording, 2 default contacts, simplified header/welcome, button labels |
| `0Affj00000Ym9dJCAR` | Apex 2-contact minimum and Contact wording (17/17 Apex tests passed) |
| `0Affj00000YmChdCAF` | Removed Start-new button from the confirmation screen |
| `0Affj00000YmF61CAF`, `0Affj00000YlUv8CAF`, `0Affj00000YmNYDCA3` | Path Converted-stage behavior and post-conversion navigation to the Account |
| `0Affj00000YmPOjCAN` | Conversion modal "Contact N" labels |

Typical deployment command (Developer Edition):
```
sf project deploy start --source-dir <paths> --target-org EnrollmentDev --test-level NoTestRun
```

---

## 8. Testing
| Suite | Result (last run) | Notes |
|---|---|---|
| Apex: 3 test classes, 17 methods | 17/17 passed (deploy `0Affj00000Ym9dJCAR`) | Covers submission, validation, idempotency, bot handling, conversion, rollback, permissions, guard, panel |
| Jest: `enrollmentForm` (7) + `enrollmentUtils` (8) | 15/15 passed locally | Run with `npm run test:unit` |
| ESLint / Prettier | Clean on changed files | `npm run lint`, `npm run prettier:verify` |

**Coverage gaps:**
- No Apex test covers `updateLeadStatus` or the existing-Account conversion path (`existingAccountId`).
- There are no Jest tests for `enrollmentLeadPath`, `enrollmentConvertModal` or `enrollmentPeoplePanel`.
- Later deployments used `NoTestRun`, which is allowed in a Developer Edition org.

---

## 9. Known Limitations and Remaining Work
1. **Public access is not configured.** To go live:
   - make the site public
   - assign `Enrollment_Submission` to the site guest user
   - grant guest edit access to the Lead **Address** fields (permission sets reject individual address parts such as `Lead.PostalCode`)
   - activate and publish the site
2. **Duplicate company emails:** the existing `LeadHandler` trigger rejects any new Lead whose email already exists, so a company cannot submit twice with the same email.
3. **Standard Convert button:** still on the Lead layout for ordinary Leads. On enrollment Leads it is blocked by the guard with an error message.
4. **Unused components:** `enrollmentConvertAction` and `Lead.Convert_Lead` remain deployed but unused.
5. **Developer Edition storage (5 MB):** storage ran out during testing (`STORAGE_LIMIT_EXCEEDED`). 2,078 Event records were deleted to free space.
6. **Lead `00Qfj00000wjY8zEAE`** was converted before the `LeadStatusChange` scoping fix and shows Status `Working-Contacted`. Its Account and Contact no longer exist.
7. **Builder page placement is not in source control** (§2.G). The whole project folder is not yet committed to Git.
8. **Not implemented:** CAPTCHA, rate limiting, and a data-retention policy for the JSON after conversion.
