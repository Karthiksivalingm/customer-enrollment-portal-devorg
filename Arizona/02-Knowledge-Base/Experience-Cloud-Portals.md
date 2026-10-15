# Experience Cloud Portals

> Network and CustomSite metadata VERIFIED. Page-level content of the three Aura sites was **not retrieved**
> ([CF-002](../05-Conflicts/2026-10-15-CF-002-aura-site-experiencebundles-not-retrievable.md)).

## Sites

| Network (portal) | Status | URL prefix | Site / template | Self-registration | Notes |
|---|---|---|---|---|---|
| **Provider Portal / Member Portal** | Under Construction | `MemberPortal` | `Provider_Portal_Member_Portal` (Aura, ExperienceBundle not retrieved) | **Enabled** | **INFERRED:** the main portal for providers and members, where they track documents and alerts |
| **Client Portal** | **Live** | `ClientPortal` | `Client_Portal` (Aura, not retrieved) | Disabled | Member profiles include many internal and portal profiles (customer community, partner, integration, read-only…) — see [Security-and-Permissions.md](Security-and-Permissions.md) |
| **Marketing Landing Pages** | **Live** | `lpvforcesite` | LWR, `DigitalExperienceBundle site/Marketing_Landing_Pages1` (retrieved) | Disabled | Public marketing pages |
| **MemberDocuments** | Under Construction | — | `MemberDocuments` (Aura, not retrieved) | Disabled | **INFERRED:** document exchange with members |

Two plain Salesforce Sites (Visualforce) also exist:

| Site | Prefix | Index page | Purpose (VERIFIED/INFERRED) |
|---|---|---|---|
| `PandaDocWebhook` | `pandadocwebhook` | `pandadoc__PandaDoc` | **VERIFIED:** hosts the Apex REST webhook `PandaDocWebhook`; runs as its guest user |
| `Incoming_SMS` | `IncomingSMS` | `SiteLogin` | **INFERRED:** endpoint for the 360 SMS package's inbound messages |

## Portal components (VERIFIED targets `lightningCommunity__Page`)

| LWC | What the portal user sees | Apex |
|---|---|---|
| `phaseDocumentTracker` | Onboarding documents by phase, upload and status | `PhaseDocumentTrackerController` |
| `dynamicformscontact` | Forms list: open, review, upload signed copy | `DynamicFormsController`, `FormWorkflowService`, `TSDocumentService` |
| `experienceContactInformation` | "My Personal Information" — always the logged-in user's own Contact | `ExperienceUserProfileController` |
| `expertionalertsindicator` | Expiration alerts for the logged-in user | `ExpirationAlertController` |
| `newcaseadvocacyform` | "Case New Status Banner" | — |
| `customformpage`, `formFillPage` | Earlier form-completion pages (token / POC) | `CustomerFormController`, `FormFillController` (`without sharing`) |

Standard Aura login components (`loginForm`, `selfRegister`, `forgotPassword`, `setStartUrl`, `setExpId`) and the standard Visualforce site pages
(`SiteLogin`, `CommunitiesLanding`, …) with their standard controllers and tests are present.

## Portal user language

Flow `ExperiencecloudUserlanguage` sets the portal user's language, locale and time zone from `Contact.Preferred_Language__c` (English/Spanish).

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial retrieval. |
