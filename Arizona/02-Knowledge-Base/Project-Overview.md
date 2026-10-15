# Project Overview

> Built from the Arizona sandbox metadata retrieved on 2026-10-15. Labels: **VERIFIED** (seen in metadata or a query),
> **INFERRED** (a reasonable reading of names or structure, not confirmed), **OPEN QUESTION** (needs the business or an administrator).

## What the org is for

**INFERRED (strong evidence):** The org supports *Arizona Lionhearts* (org name *Azlionhearts*, app `ArizonaLH`), an Arizona home- and
community-based care provider agency. Its main records are **care providers / direct care workers (DCWs)** and the **members**
(clients) they serve. Evidence:
- **VERIFIED:** Apex and Visualforce reproduce Arizona Medicaid forms: `EVVContingencyPlanController` renders the
  "AHCCCS Policy 540 Attachment D — EVV Member Contingency/Back-Up Plan" ([source](../force-app/main/default/classes/EVVContingencyPlanController.cls)).
- **VERIFIED:** Contact carries 377 custom fields for provider compliance documents: Article 9, CPR, First Aid, fingerprint card,
  criminal history, DCW 1/2 certificates, Habilitation certificate, driver's licence, vehicle registration and insurance, EVV attestations,
  ATC (Attendant Care) rates and monitoring, DDD (Division of Developmental Disabilities) forms, in English and Spanish versions.
- **VERIFIED:** `CertificationExpiryReminderBatch` sends an "Arizona Lionhearts" branded reminder with a scheduling link.
- **VERIFIED:** `Account_Contact_Relationships` flow assigns the roles *Member*, *Provider*, *Parent Provider* and *Tutor*.

## Main business capabilities (evidence in [Automation-and-Processes.md](Automation-and-Processes.md))

| # | Capability | Main components |
|---|---|---|
| 1 | **Provider onboarding and compliance documents**, by phase, division, language and service type | `phaseDocumentTracker` LWC, `PhaseDocumentTrackerController`, `Phase_Document__mdt`, Contact status fields |
| 2 | **Certification expiry tracking**: calculate expiry from issuance, mark expired, alert staff and providers | `ContactCertificationExpirationTrigger`, `Certification_Validity_Rule__mdt`, scheduled flows, `CertificationExpiryReminderBatch`, expiration-alert LWCs |
| 3 | **Forms sent to contacts and returned signed** (PDF), through TS Documents and PandaDoc | `FormWorkflowService`, `TSDocumentService`, `PandaDocService`, `PandaDocWebhook`, `dynamicformscontact` LWC |
| 4 | **Member service authorizations and ATC monitoring** | `Authorization__c`, `Authorization_Service__c`, `Service_Type_ATC__c`, `atcmonitoringdates` LWC |
| 5 | **SMS-based case intake and follow-up** (360 SMS package) | `Inbound_SMS_Case_creation`, `SMS_Case_Scheduled_SMS` flows, Case record types |
| 6 | **Experience Cloud portals** for providers/members and clients | 4 Networks, `experienceContactInformation`, `expertionalertsindicator` LWCs |
| 7 | **Lead intake** of prospective members (with parent/guardian details) and conversion to Account | Lead custom fields, `Lead_to_AC_test` screen flow |
| 8 | **Knowledge base** (FAQ and Procedure articles) | `Knowledge__kav` record types FAQ, Procedure |

## Size of the customisation (VERIFIED, [Metadata-Inventory.md](../07-Technical-Documents/Metadata-Inventory.md))

56 Apex classes (13 of them tests, all for standard site controllers), 4 triggers, 10 flows, 14 LWCs, 5 Aura bundles,
28 Visualforce pages, 5 custom objects, 6 custom metadata types, 2 platform events, Knowledge, 4 Experience Cloud sites,
4 permission sets, 113 reports and 6 dashboards. 23 managed packages are installed ([Salesforce-Org-Context.md](Salesforce-Org-Context.md)).

## Development style observed (VERIFIED from code comments)

The custom code is recent (API 66–67, components created 2026) and iterative: classes carry version notes ("v10 — portal/token flow
removed", "v15 — portal-safe PDF opening"), describe set-up steps to perform in Setup, and keep earlier approaches in place
(for example the Google Docs path and the token-based form page). See [Known-Constraints-and-Open-Questions.md](Known-Constraints-and-Open-Questions.md).

## Knowledge Base pages

| Page | Contents |
|---|---|
| [Salesforce-Org-Context.md](Salesforce-Org-Context.md) | Org identity, edition, installed packages, licences, scheduled jobs |
| [Data-Model-and-Relationships.md](Data-Model-and-Relationships.md) | Objects, fields, relationships, custom metadata |
| [Automation-and-Processes.md](Automation-and-Processes.md) | Business processes and the automation per object, execution order |
| [Integrations.md](Integrations.md) | PandaDoc, TS Documents, Google, 360 SMS, Pardot, Calendly |
| [Experience-Cloud-Portals.md](Experience-Cloud-Portals.md) | Sites, portal users, what each portal exposes |
| [Security-and-Permissions.md](Security-and-Permissions.md) | Sharing model, permission sets, guest and portal security patterns |
| [Known-Constraints-and-Open-Questions.md](Known-Constraints-and-Open-Questions.md) | Risks, gaps, inconsistencies and questions for the business |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial retrieval. |
