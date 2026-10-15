# Data Model and Relationships

> All facts VERIFIED from `force-app/main/default/objects/` unless labelled otherwise. Field-level detail: [Metadata-Inventory.md](../07-Technical-Documents/Metadata-Inventory.md).

## Core idea

**INFERRED:** **Contact is the hub.** A provider's (or member's) whole compliance file lives as fields on Contact: one *status* picklist and,
where relevant, *issuance* and *expiration* dates per document, plus the files themselves as `ContentDocument`s linked to the Contact.
Accounts group people (a member household or client account) through **AccountContactRelation** roles.

## Relationships

```
Account ──< AccountContactRelation >── Contact        (roles used by flow: Member, Provider, Parent Provider, Tutor)
Account.Contacts__c ──> Contact                       (Lookup)
Authorization__c.Account__c ──> Account               (Lookup)
Authorization_Service__c.Account__c ──> Account       (Lookup)
Service_Type_ATC__c.Account__c ──> Account            (Lookup)
Service_Type_ATC__c.Contact__c ──> Contact            (Lookup)
Certification__c.Contact__c ──> Contact               (Lookup)
Form_Request__c.Contact__c ──> Contact                (Lookup)
Case.Lead__c ──> Lead                                 (Lookup)
Contact / Account ──< ContentDocumentLink >── ContentDocument   (all uploaded and generated documents)
```
All custom relationships are **Lookups**; there are no master-detail relationships.

## Custom objects

| Object | Purpose (INFERRED from fields) | Key fields | Sharing (internal / external) |
|---|---|---|---|
| `Authorization__c` | A member's service authorization | `Auth_Number__c`, `Start_Date__c`, `End_Date__c` | Public Read/Write / Private |
| `Authorization_Service__c` | Units authorized per service and period | `Service__c` (picklist), `Weekly_Limit__c`, `Actual_Units__c`; formulas `Estimated_Units__c`, `Missing_Units__c`, `Service_Days__c`, `Service_Weeks__c` | Read/Write / Read/Write |
| `Service_Type_ATC__c` | Attendant Care (ATC) service and its monitoring-meeting schedule | `Initial_Service_Date__c`, `Serviced_By__c`, checkboxes and **formula dates** for the first, 30-, 60- and 90-day monitoring meetings | Read/Write / Read/Write |
| `Certification__c` | A certification record per Contact | Only `Contact__c`; no other custom field. **OPEN QUESTION:** is it still used? Certifications are otherwise held on Contact fields. | Read/Write / Private |
| `Form_Request__c` | A form sent to a Contact for completion (token-based portal path) | `Form_API_Name__c`, `Status__c`, `Token__c`, `Sent_Date__c`, `Expiration_Date__c`, `Completed_Date__c` | Read/Write / Private |
| `Knowledge__kav` | Knowledge articles | Record types FAQ (`Question__c`, `Answer__c`) and Procedure (`Procedure_Purpose__c`, `_Audience__c`, `_Steps__c`, `_Warnings__c`) | — |

**VERIFIED (code comment in `FormWorkflowService`):** the token-based `Form_Request__c` path was replaced in "v10" by public file links,
but `CustomerFormController`, `FormFillController` and the `customformpage` LWC that use it still exist.

## Standard objects

| Object | Customisation |
|---|---|
| **Contact** | 377 custom fields: 138 picklists (mostly document *status* values, e.g. Completed / Pending / Rejected / Expired / Not Needed), 74 dates (issuance and expiration), 59 text, 46 checkboxes, 38 currency (ATC rates and income), 14 numbers. Groups: certifications (Article 9, CPR, First Aid, DCW 1/2, Habilitation), background checks (fingerprint card, criminal history, centralized background check, SAM, OIG), driving (licence, vehicle registration and insurance, "Does the Provider Need to Drive?"), EVV forms and attestations, ATC services and rates, DDD forms, training (Pre-Service Orientation, CEU log, client orientation), English and Spanish versions of forms, `Preferred_Language__c`, `Division`, `Hire_Date__c`. Sharing: Controlled by Parent. |
| **Account** | 65 custom fields; `Contacts__c` lookup to Contact. Internal Read/Write, external Private. |
| **Lead** | 26 custom fields for prospective members: date of birth, age, gender, interests, parent and legal-guardian names/phones/emails, preferred language and contact method, `Lead_Origin__c`, `Provider_Status__c`, `Onboarding_Date__c`, `Account_Created__c`. |
| **Case** | Record types **Admin, Advocacy, Onboarding, Support**; fields `Phone__c`, `SMS_OPT_OUT__c`, `Last_SMS_received_date__c`, `Case_Reason_Custom__c`, `Lead__c`. Validation rule `Prevent_Subject_Description_Edit`. |
| **Opportunity** | 4 sales-qualification fields (`Budget_Confirmed__c`, `Discovery_Completed__c`, `ROI_Analysis_Completed__c`, `Loss_Reason__c`). **INFERRED:** generic sales set-up, not core to the care process. |
| **Activity** | `Description__c` (text). |
| `pandadoc__PandaDocDocument__c` (managed) | 3 unmanaged fields linking a PandaDoc document to the form: `Document_Id__c`, `Form_API_Name__c`, `Form_Label__c`. |

**VERIFIED:** Contact has duplicate-looking fields with identical labels, e.g. two fields labelled "Article 9 Expiration Date"
(`Article_9_Expiration_Date__c` used by Apex and the alert flow, `Article_9_Expiration_Date_For__c` used by `Expired_Status_Update`),
and the same pattern for CPR and First Aid (`CPR_Expiration_Date_Fpr__c`, `FA_Expiration_Date_For__c`). See [Known-Constraints-and-Open-Questions.md](Known-Constraints-and-Open-Questions.md).

## Custom metadata (configuration)

| Type | Records | Used by | What it configures |
|---|---|---|---|
| `Certification_Validity_Rule__mdt` | Article_9, CPR, FA, Criminal_History, Fingerprint_Card, CBC, PCSP, Client_Orientation, Attendant_Care_Services_Work_Agreement | `ContactCertificationExpirationHandler` | Validity years / months per certification |
| `Phase_Document__mdt` | **none** in the org | `PhaseDocumentTrackerController` | Intended: which document appears in which onboarding phase, by division and language, with sort order and a template file. **OPEN QUESTION:** without records, where does the tracker get its phase list? |
| `Form__mdt` (label *Form_Field_Mapping*) | EVV_Member_Signature, EVV_Attestation_Date, EVV_Member_Name, … | `CustomerFormController`, `DynamicFormsController`, `FormFillController` | PDF field positions (page, x, y, font) mapped to Salesforce fields |
| `PandaDoc_Template__mdt` | Criminal_History_English, HIPPA_Confidentiality_English, Worker_Comp_Waiver_1099_Sole_Proprieto | `PandaDocService` | PandaDoc template ID per form and the Contact status field it updates |
| `PandaDoc_Settings__mdt` | none | **No code references it** | Field `Webhook_Shared_Key__c`. The webhook reads its key from a custom label instead. **OPEN QUESTION:** can the type be retired? |
| `Google_Service_Account_Config__mdt` | Default | `GoogleServiceAccountAuth` | Service-account and impersonated Workspace user (values not documented) |

Global value set: `Forms_Status`.

## Platform events

| Event | Fields | Published by | Subscriber |
|---|---|---|---|
| `PandaDoc_Webhook__e` | Document, status, contact, form API name and label | `PandaDocWebhook` (site guest user) | `PandaDocWebhookTrigger` → `PandaDocEventProcessor` |
| `Document_Status_Update_Event__e` | `Contact_Id_c__c`, `Field_API_Name__c` | Portal user actions (Phase Document Tracker) | `DocumentStatusUpdateEventTrigger` |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial retrieval. |
