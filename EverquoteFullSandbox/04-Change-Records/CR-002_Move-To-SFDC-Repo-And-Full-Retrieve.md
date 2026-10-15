# CR-002: Move to sfdcut/SFDC and full metadata retrieve

| Field | Value |
|---|---|
| Date | 2026-10-15 |
| Change type | Repository only. The org was read (retrieve), not changed. |
| Requirement | [REQ-002](../03-Requirements/REQ-002_Move-Project-Into-SFDC-Repository.md) |
| Made by | sasikumarm-web |
| Branch / PR | `everquotefullsandbox/import`, merged to `main` |

## Steps
1. Cloned `sfdcut/SFDC` to `C:\Esisting\Existing\LWC\SFDC` and created branch `everquotefullsandbox/import`.
2. Added the project with its history: `git subtree add --prefix=EverquoteFullSandbox <local repo> main`.
3. Built a manifest from the org (`sf project generate manifest --from-org`), removed members of the 31 installed managed-package namespaces, and left out Profile, FlowDefinition, Report and Dashboard.
4. Retrieved about 6,760 components at API 68.0 in two batches (objects with their child types, then everything else). 123 listed items couldn't be retrieved, mostly list views and validation rules on special objects; this is normal.
5. Moved the documentation from `docs/` to the house layout (numbered folders at the project root, numbered file names, `DOCUMENT-INDEX.md`). Added the shared `AI-Workflow.md` and `Coding-Standards.md`.

## Before and after (`force-app/`)
| Metadata | Before | After |
|---|---|---|
| Files | 745 | 10,105 |
| Apex classes / triggers | 160 / 33 | 162 / 33 |
| Flows | 4 | 436 |
| Objects / custom fields | 0 | 353 / 3,685 |
| Layouts / Lightning pages | 0 / 0 | 214 / 59 |
| LWC / Aura / VF pages / VF components | 0 / 0 / 0 / 0 | 40 / 14 / 34 / 30 |
| Permission sets | 111 | 118 (now including object and field permissions) |
| Other new types | — | applications, tabs, quick actions, report types, sharing rules, custom metadata, labels, global value sets, named credentials, remote site settings, approval, assignment, auto-response, escalation, duplicate and matching rules, service channels, routing configs, letterheads, entitlement and milestone setup, notification types |

## Org differs from the 2026-10-13 snapshot
The retrieve replaced the earlier files with the org's current versions:
- **116 files** differ only in formatting or `apiVersion`. The old copy had been formatted with Prettier, and the org's API versions are now 65.0.
- **27 Apex classes have real code changes** in the org. They were refactored after the snapshot, for example `AutoPopulateContactOnVoiceCall` gained null-safety guards. The classes are:
  AutoPopulateContactOnVoiceCall, BulkAccountLastOppUpdateTest, CrossUpsellInfoController, DeleteFaliureCasesBatch, EventHandlerTest, LeadCheatsheetController, LeadTriggerTest, MockHttpResponseGenerator, MyProfilePageControllerTest, NotifyCTI, ODALeadOutcomeController, ODANewLifeLeadControllerTest, ODAPolicyControllerTests, OdieWrapper, OdieWrapperTest, OnboardingOwnerAssignmentCtrl, OnboardingOwnerAssignmentCtrlTest, OpportunityCheatsheetController, OpportunityLegacyRecordTypeBatch, OpportunityLegacyRecordTypeBatchTest, OpportunityTriggerHandlerTest, SendEmailForMissedCallAlertVCTest, TestLeadCheatsheet, TestOpportunityCheatsheet, TestUpdateCase, roundRobinAssigner, roundRobinLeadAssigner.
- **Also changed in the org:** 2 flows (`BDR_Activity_completed_…`, `Case_Move_to_Smart_Campaign_Queue`) and 5 workflow files (Case, EmailMessage, Lead, Opportunity, Task).

The old versions remain in Git history (commit `f9c91cf`). TECH-001 to TECH-021 were written from the old snapshot, so re-check them for these components.

## Secrets
The metadata contains credentials and keys ([CON-001](../05-Conflicts/CON-001_Hardcoded-Credentials-And-Secrets.md)). By the owner's decision they were pushed as-is.

## Rollback
Revert the merge commit on `main`. Nothing in the org changed.
