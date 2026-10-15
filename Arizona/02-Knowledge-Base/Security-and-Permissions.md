# Security and Permissions

> Profiles were deliberately not retrieved ([Metadata-Scope.md](../07-Technical-Documents/Metadata-Scope.md)), so this page cannot describe
> profile-level access. Everything below is VERIFIED from retrieved metadata and code unless labelled.

## Organization-wide defaults (in-scope objects)

| Object | Internal | External |
|---|---|---|
| Account | Public Read/Write | Private |
| Contact | Controlled by Parent | Controlled by Parent |
| Lead, Case | Public Read/Write/Transfer | Private |
| Opportunity | Public Read Only | Private |
| Activity | Private | — |
| `Authorization__c`, `Certification__c`, `Form_Request__c` | Public Read/Write | Private |
| `Authorization_Service__c`, `Service_Type_ATC__c` | Public Read/Write | **Public Read/Write** |

**INFERRED:** `Authorization_Service__c` and `Service_Type_ATC__c` are readable and editable by all external (portal) users who have object access.
**OPEN QUESTION:** is that intended?

No sharing rules exist on the in-scope objects (the retrieved `sharingRules` files contain no rules).

## Permission sets

| Permission set | Grants (as retrieved) | Observation |
|---|---|---|
| `Allow_modification_for_case_dates` | User permission *Set Audit Fields upon Record Creation* (`CreateAuditFields`) | Allows setting CreatedDate etc. on insert (data migration use). |
| `cases_Permisssion_Set` | *Give Recognition Badge* only | Name suggests Case access but grants none. **OPEN QUESTION.** |
| `PandaDoc_Webhook_Files` | Full access to **Document** (Read, Create, Edit, Delete, View All, Modify All) | Supports the PandaDoc webhook path. |
| `Disabled_MFA` | **Nothing** (only a label) | **OPEN QUESTION:** the MFA-waiver permission may not be exposed by the Metadata API; check in Setup who has it and why. |

Custom permission: `PandaDoc_Status_Sync`.

## Portal and guest security patterns (VERIFIED from code)

| Pattern | Where | Why |
|---|---|---|
| Portal users cannot DML Contact (High-Volume portal licence). They publish `Document_Status_Update_Event__e`; the trigger updates the Contact as Automated Process, only for allow-listed fields and only for the publisher's own Contact. | `DocumentStatusUpdateEventTrigger` | Licence restriction |
| Webhook runs as site guest user; validates an HMAC signature before doing anything, then hands off via platform event. | `PandaDocWebhook` | Guest user cannot read Contacts |
| "My Personal Information" always resolves the current user's own Contact through `User.ContactId`. | `ExperienceUserProfileController` | Prevents reading another user's record |
| Narrow `without sharing` helper for one status update. | `PhaseDocumentPrivilegedUpdater` | Elevated access kept minimal |
| Public `ContentDistribution` links for emailed forms (view/download without login). | `FormWorkflowService` | Avoids guest-user configuration |

## Classes running `without sharing` (VERIFIED)

`CustomerFormController`, `FormFillController`, `GoogleDriveService`, `GoogleServiceAccountAuth`, `PandaDocApi`, `PandaDocEventProcessor`, `PandaDocService`,
`PandaDocWebhook`, `PhaseDocumentPrivilegedUpdater`, `TSTemplateSelector`. Several are reachable from portal LWCs; review before exposing new methods.

## Risks to review

- Public file links to completed forms that may contain personal and health information (`ContentDistribution`).
- Debug logging is switched on (`DEBUG_ON = true`) in `PandaDocWebhook` and `PandaDocEventProcessor`; the webhook logs up to 3,000 characters of
  the payload, which may contain personal data.
- `Client Portal` network member list includes many profiles, among them integration and read-only profiles.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial retrieval. |
