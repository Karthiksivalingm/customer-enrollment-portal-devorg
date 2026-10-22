# Business Processes and Automation

> VERIFIED facts come from the retrieved flows, triggers and Apex (links below). Business purpose is INFERRED from the components unless stated.
> Detailed component catalogue: [Metadata-Inventory.md](../07-Technical-Documents/Metadata-Inventory.md).

## 1. Provider onboarding and compliance documents

**INFERRED purpose:** each provider must complete a set of documents per onboarding *phase*; staff and the provider track their status.

- **VERIFIED:** [`phaseDocumentTracker`](../force-app/main/default/lwc/phaseDocumentTracker/) (internal record pages and Experience Cloud)
  calls [`PhaseDocumentTrackerController`](../force-app/main/default/classes/PhaseDocumentTrackerController.cls) (1,064 lines). It resolves the
  current user's Contact, division, language, driving status, contract type and service type, and shows phase tabs with each document's status.
- **VERIFIED (since 2026-10-22, [CR-001](../04-Change-Records/CR-001_Phase-Document-Tracker-Eligibility-And-Multi-Service.md)):** what the tracker shows depends
  on the Contact's division — Member and Tutor see only *Based Forms*; Parent Provider sees Pay and Tax for 1099 only and no driver items;
  Provider follows the Contact's contract, driving and service values. A Contact can have several services (ATC, HAH, RSP), each shown in its own section.
- **VERIFIED:** Status values: Completed, Pending, Rejected, Expired, Not Needed. Status is stored on Contact fields; files are
  `ContentDocument`s linked to the Contact. SAM and OIG checks moved from checkboxes to `SAM_Status__c` / `OIG_Status__c`.
- **VERIFIED:** Portal users cannot update Contact (licence restriction), so a portal action publishes
  `Document_Status_Update_Event__e`. [`DocumentStatusUpdateEventTrigger`](../force-app/main/default/triggers/DocumentStatusUpdateEventTrigger.trigger)
  then updates the Contact as the Automated Process user. It only accepts fields from a fixed allow-list, and only for the publishing user's own Contact.
  [`PhaseDocumentPrivilegedUpdater`](../force-app/main/default/classes/PhaseDocumentPrivilegedUpdater.cls) (`without sharing`) sets a status to Pending.
- **VERIFIED:** [`recordCertificateDocuments`](../force-app/main/default/lwc/recordCertificateDocuments/) gives internal staff the same documents on the Contact page;
  [`accountDocuments`](../force-app/main/default/lwc/accountDocuments/) does the same for Account-level documents.

## 2. Certification expiry

| Step | Component | Behaviour (VERIFIED) |
|---|---|---|
| Calculate expiry | [`ContactCertificationExpirationTrigger`](../force-app/main/default/triggers/ContactCertificationExpirationTrigger.trigger) (Contact before insert/update) → [`ContactCertificationExpirationHandler`](../force-app/main/default/classes/ContactCertificationExpirationHandler.cls) | When an issuance date for Article 9, CPR, First Aid, Criminal History or Fingerprint Card is set or changed, sets Expiration = Issuance + validity from `Certification_Validity_Rule__mdt`. Driver's licence, vehicle registration and vehicle insurance stay manual. Replaces an earlier flow design. |
| Mark expired | Flow [`Expired_Status_Update`](../force-app/main/default/flows/Expired_Status_Update.flow-meta.xml) (scheduled daily, Active) | Loops over Contacts and sets status fields (Article 9, CPR, First Aid, Driver's Licence, Vehicle Registration, Liability Insurance) by comparing `*_For__c` / expiration date fields with today. |
| Alert (60 days) | Flow [`Expiration_Alerts_Certificate_and_Document`](../force-app/main/default/flows/Expiration_Alerts_Certificate_and_Document.flow-meta.xml) (scheduled daily on Contact, Active) | Sends up to 4 simple emails (Article 9, CPR, First Aid, Driver's Licence) when an expiration date is 60 days from today. |
| Reminder (2 days / 1 month) | Apex [`CertificationExpiryReminderBatch`](../force-app/main/default/classes/CertificationExpiryReminderBatch.cls), scheduled daily as "Daily Certification Expiry Reminder" | For Contacts with an email, sends an Arizona Lionhearts branded email when Article 9, CPR or First Aid expires in exactly 2 days or exactly 1 month, with a Calendly booking link. |
| Show alerts | LWCs `expirationalerts`, `expirationalertsmodal`, `accountexpiration` (internal) and `expertionalertsindicator` (portal) → `ExpirationAlertController`, `AccountExpirationAlertController` | Lists upcoming and expired items for a Contact, an Account, or the logged-in portal user. |
| Not running | Flow `Expiration_Member_and_Parent_Providers` (**Draft**) | Would email based on `Hire_Date__c` thresholds for CEU Log, DDD-EVV contingency plan and HCBS service contract. |

**VERIFIED:** Two separate reminder mechanisms (flow at 60 days, Apex at 1 month and 2 days) are both active. See
[Known-Constraints-and-Open-Questions.md](Known-Constraints-and-Open-Questions.md).

## 3. Forms sent to contacts and returned signed

**VERIFIED** from [`FormWorkflowService`](../force-app/main/default/classes/FormWorkflowService.cls) header (workflow "v10–v15"):

```
None ──"Send the Form" (staff)──> Sent ──signed copy returned / uploaded──> Pending ──promoteSignedToFinal──> Completed
```
- On *Send*, TS Documents ([`TSDocumentService`](../force-app/main/default/classes/TSDocumentService.cls), [`TSTemplateSelector`](../force-app/main/default/classes/TSTemplateSelector.cls))
  generates a PDF, which is emailed to the Contact as an attachment with a public `ContentDistribution` link (view/download, no login).
- Status is the Contact field named after the form; files are linked to the Contact. Uploads for the signed and final stages must be PDF.
- The UI is [`dynamicformscontact`](../force-app/main/default/lwc/dynamicformscontact/) (internal and portal), with `DynamicFormsController`.
- **PandaDoc path (parallel):** for forms in `PandaDoc_Template__mdt` (Criminal History, HIPAA Confidentiality, Worker Comp Waiver 1099),
  [`PandaDocService`](../force-app/main/default/classes/PandaDocService.cls) creates a PandaDoc document. Signing events come back through the
  webhook and update the Contact status and files ([Integrations.md](Integrations.md)).
- **Earlier paths still present:** token-based `Form_Request__c` + `customformpage` (`CustomerFormController`), `formFillPage` (`FormFillController`,
  marked "POC"), in-portal PDF filling (`PortalFormFillerService`), Google Docs copies (`PerContactDocumentService`, `GoogleDriveService`).
  Code comments say these were removed from the active workflow.
- **EVV forms:** `EVVContingencyPlanController` + Visualforce render the AHCCCS EVV Member Contingency/Back-Up Plan as a PDF; `EVVPdfService` saves PDFs as files.

## 4. Member authorizations and ATC monitoring

- **VERIFIED:** `Authorization__c` and `Authorization_Service__c` (on Account) hold authorization numbers, dates, weekly limits and units; formulas
  compute estimated and missing units and service days/weeks.
- **VERIFIED:** `Service_Type_ATC__c` computes the first, 30-, 60- and 90-day ATC monitoring meeting dates from the initial service date;
  [`atcmonitoringdates`](../force-app/main/default/lwc/atcmonitoringdates/) (`ATCMonitoringDatesController`) shows them for a Contact's related Accounts.
- **OPEN QUESTION:** No automation creates or updates these records; they appear to be maintained manually.

## 5. SMS case intake (360 SMS package)

| Flow | Trigger | Behaviour (VERIFIED) |
|---|---|---|
| [`Inbound_SMS_Case_creation`](../force-app/main/default/flows/Inbound_SMS_Case_creation.flow-meta.xml) (Active) | After create of `tdc_tsw__Message__c` named "Incoming", related to a Contact (`003…`) or Lead (`00Q…`) | Looks for an open Case for the contact; if found adds a CaseComment with the message and updates `Last_SMS_received_date__c`, otherwise creates a new Case (origin, subject, phone, priority) and links the message to it. |
| [`SMS_Case_Scheduled_SMS`](../force-app/main/default/flows/SMS_Case_Scheduled_SMS.flow-meta.xml) (Active) | Case after create/update when `Phone__c` is set | Creates a `tdc_tsw__Scheduled_Sms__c` with a **hardcoded** SMS template record ID and sender number. |
| `SMS_Lead_Creation` (**Obsolete**) | Lead with mobile phone | Formerly scheduled an SMS for Leads. |

Case also has a workflow (`workflows/Case`), assignment, auto-response and escalation rules, and record types Admin, Advocacy, Onboarding and Support.
The portal LWC `newcaseadvocacyform` ("Case New Status Banner") is used in Experience Cloud.

## 6. Accounts, contacts and leads

- **VERIFIED:** Screen flow [`Account_Contact_Relationships`](../force-app/main/default/flows/Account_Contact_Relationships.flow-meta.xml) adds Contacts to an Account
  with roles Member / Provider / Parent Provider / Tutor and manages the primary relation.
- **VERIFIED:** Screen flow [`Lead_to_AC_test`](../force-app/main/default/flows/Lead_to_AC_test.flow-meta.xml) ("Lead Conversion to account", **Active**
  despite the "test" name) copies Lead fields (including parent and guardian details) into a new Account and **deletes the Lead**.
- **VERIFIED:** Record-triggered flow [`ExperiencecloudUserlanguage`](../force-app/main/default/flows/ExperiencecloudUserlanguage.flow-meta.xml) sets the portal User's
  language, locale and time zone from `Contact.Preferred_Language__c` (English → en_US, America/Los_Angeles; Spanish → es / es_MX, America/Mexico_City).
- Screen flow `Contact_Page_Community_page_creation` has a single screen (purpose unclear).

## 7. Execution order per object (VERIFIED components)

| Object | Before save | After save | Async / scheduled |
|---|---|---|---|
| Contact | `ContactCertificationExpirationTrigger` | `ExperiencecloudUserlanguage` flow | `Expired_Status_Update`, `Expiration_Alerts_…` flows; `CertificationExpiryReminderBatch` |
| Case | Validation rule `Prevent_Subject_Description_Edit`; assignment / auto-response / escalation rules; Case workflow | `SMS_Case_Scheduled_SMS` flow | — |
| `tdc_tsw__Message__c` (managed) | — | `Inbound_SMS_Case_creation` flow (creates/updates Case → Case automation runs) | — |
| Account | `ContentDocumentLinkTrigger` (**empty**) | — | — |
| `PandaDoc_Webhook__e` | — | `PandaDocWebhookTrigger` | `PandaDocEventProcessor` (Queueable, callouts) |
| `Document_Status_Update_Event__e` | — | `DocumentStatusUpdateEventTrigger` (updates Contact → Contact automation runs) | — |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial retrieval and the CronTrigger query. |
| 2026-10-22 | §1 updated for the Phase Document Tracker eligibility and multi-service change (CR-001). |
