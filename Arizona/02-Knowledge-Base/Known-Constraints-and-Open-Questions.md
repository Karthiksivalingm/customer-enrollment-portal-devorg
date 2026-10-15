# Known Constraints, Risks and Open Questions

> Found during the initial analysis on 2026-10-15. Each item cites its evidence. None of these were changed; they need a decision or a
> requirement (`03-Requirements/`) before anything is modified.

## Constraints

| # | Constraint | Evidence | Impact |
|---|---|---|---|
| K1 | **No test classes for any custom Apex.** The 13 test classes cover only the standard site/community controllers. None of the ~30 custom classes or the 4 triggers have tests. | `classes/*Test.cls` | A Production deployment needs 75% org-wide coverage and coverage of every trigger; custom code cannot be deployed to Production as it stands. |
| K2 | Portal users have a High-Volume Customer Portal licence, so they cannot update Contact directly. | `DocumentStatusUpdateEventTrigger` header | New portal features that write Contact must use the platform-event pattern. |
| K3 | ExperienceBundles for three Aura sites cannot be retrieved until *Enable ExperienceBundle Metadata API* is turned on. | [CF-002](../05-Conflicts/2026-10-15-CF-002-aura-site-experiencebundles-not-retrievable.md) | Portal page changes are not tracked in Git. |
| K4 | ConnectedApp `CPQIntegrationUserApp` cannot be retrieved. | [CF-001](../05-Conflicts/2026-10-15-CF-001-connectedapp-cpqintegrationuserapp-cannot-be-retrieved.md) | Its configuration is undocumented. |
| K5 | Environment-specific values are hardcoded (sandbox webhook URL, Calendly/Pardot URLs, SMS template ID and sender number). | [Integrations.md](Integrations.md) | Must be changed when moving to Production. |

## Inconsistencies found

| # | Finding | Evidence |
|---|---|---|
| I1 | **Two reminder mechanisms for the same certificates** run daily: flow `Expiration_Alerts_Certificate_and_Document` (60 days before) and Apex `CertificationExpiryReminderBatch` (1 month and 2 days before). Providers may receive several emails per certificate. | Flows, CronTrigger "Daily Certification Expiry Reminder" |
| I2 | **Duplicate expiration fields with identical labels** on Contact (`Article_9_Expiration_Date__c` vs `Article_9_Expiration_Date_For__c`; `CPR_Expiration_Date__c` vs `CPR_Expiration_Date_Fpr__c`; `FA_Expiration_Date__c` vs `FA_Expiration_Date_For__c`). Apex calculates one set; `Expired_Status_Update` reads the other. | Contact fields, flow, `ContactCertificationExpirationHandler` |
| I3 | Code says Google Docs components were deleted (v9), but `GoogleDriveService` and `PerContactDocumentService` still exist and reference a Named Credential `Google_Drive_API` that does not exist. | `FormWorkflowService` header, `namedCredentials/` |
| I4 | Superseded form paths remain: `Form_Request__c` + `customformpage`, `formFillPage` ("POC"), `PortalFormFillerService`. | `FormWorkflowService` v10 note |
| I5 | Empty components: trigger `ContentDocumentLinkTrigger` (on **Account**, despite its name, no body) and class `AccountDocumentCleanupHandler` (no body). | Source |
| I6 | Flow `Lead_to_AC_test` is **Active** although named "test"; it deletes the Lead after copying it to an Account. | Flow metadata |
| I7 | `Phase_Document__mdt` has no records, although the Phase Document Tracker is described as configuration-driven. | `customMetadata/` |
| I8 | Contact Spanish users get time zone America/Mexico_City and English users America/Los_Angeles; Arizona uses America/Phoenix (no daylight saving). | Flow `ExperiencecloudUserlanguage` |
| I9 | The reminder email's Calendly link is fixed to July 2026. | `CertificationExpiryReminderBatch` |
| I10 | Permission sets `Disabled_MFA` and `cases_Permisssion_Set` grant nothing matching their names. | `permissionsets/` |
| I11 | Trigger header says the event field is `Contact_Id__c`; the real field is `Contact_Id_c__c` (the code uses the real name). | `DocumentStatusUpdateEventTrigger`, event fields |

## Open questions for the business or an administrator

1. Which reminder mechanism (I1) is the intended one, and who should receive alerts (provider, staff, or both)?
2. Which expiration fields (I2) are authoritative? Can the duplicates be retired?
3. Is `Certification__c` still used, given that certifications live on Contact?
4. Are Authorizations and ATC records maintained manually? Is external Read/Write on them intended?
5. Should the Provider/Member Portal (Under Construction) and MemberDocuments sites go live, and should ExperienceBundle retrieval be enabled?
6. What is `Disabled_MFA` for, and who holds the MFA waiver?
7. Which superseded components (I3–I5) can be removed?
8. What profiles do internal and portal users have? (Not retrieved.)

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial analysis. |
