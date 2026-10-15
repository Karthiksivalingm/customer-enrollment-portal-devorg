# Project Overview: EverquoteFullSandbox

## What this project is
This is a Salesforce DX project holding the metadata of the **Everquote full-copy sandbox** (org alias `EverquotefullSandbox`, API 68.0). It's part of the shared **sfdcut/SFDC** repository, in the `EverquoteFullSandbox/` folder.

**History:** the project was first versioned in `sasikumarm-web/EverquoteFullSandbox` on 2026-10-13 ([CR-001](../04-Change-Records/CR-001_GitHub-Baseline-And-Documentation.md)). It moved into sfdcut/SFDC and was fully retrieved from the org on 2026-10-15 ([CR-002](../04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md)).

## The business, as reflected in the metadata
The org supports several lines of business. This section is inferred from the code and automation, so confirm it with the business owners.

| Business area | What the org does | Main components |
|---|---|---|
| **B2B sales to insurance agents and carriers** | Sells lead and advertising products. Tracks Opportunities, products, upsell and cross-sell, fill rates and closed-won alerts. | Opportunity / OpportunityLineItem triggers, `Upsell__c`, `UpdateFillRateBatch`, `BulkAccountLastOppUpdate`, `OppToCSUpsellRTUpdate`, `OppToStateFarmRTUpdate`, cheat sheet controllers |
| **Lead management and SDR/BDR outreach** | Lead scoring, cadence enrolment, round-robin assignment, first-response timing, call dispositions and lead outcome. | `LeadTrigger` → `LeadHandler`, `AssignLeadToCadencesBatch`, `roundRobin*` / `etcd8_*`, `TaskHandler`, `EventHandler`, BDR flows |
| **Life insurance agency (ODA / Odie)** | Agents quote and sell life products from carriers (AIG, Gerber, Lumico, Reliashield and others). Leads and policies sync with the **Odie** platform. | `ODA*` / `Oda*` controllers, request builders, `OdieWrapper`, `ODA_Policy__c`, `syncLeadOwnerToOdie` |
| **Customer onboarding and success** | Assigns onboarding and Customer Success owners, and runs surveys. | `OnboardingOwnerAssignmentCtrl`, `Customer_Success_Rep__c`, Delighted outbound messages |
| **Customer support** | Email-to-Case matching (including legacy Zendesk Ids), case first-activity timing, Smart Campaign queue routing, and missed-call alerts. | `EmailServiceToFindMatchingCase`, Case flows and workflows, `SendEmailForMissedCallAlertVC` |
| **Telephony (CTI / Voice)** | Links Voice Calls to Contacts and Accounts, refreshes the CTI agent picker, pauses or resumes Twilio recordings, and runs Amazon Connect. | `VoiceCallTrigger`, `AutoPopulateContactOnVoiceCall`, `NotifyCTI` |
| **Communities and unsubscribe** | Portal login and self-registration, a Pro help centre site, and email unsubscribe. | `Communities*`, `Site*`, `jrsl_ul_*`, `unsubscribe` |

## Org inventory (in `force-app/`, retrieved 2026-10-15)
| Metadata | Count | Notes |
|---|---|---|
| Apex classes / triggers | 162 / 33 | Only 7 triggers are active. See [TECH-001](../07-Technical/TECH-001_Apex-Class-Index.md) and [TECH-014](../07-Technical/TECH-014_Trigger-Inventory.md). |
| Flows | 436 | 318 active. 69 are Process Builders (`processType` Workflow). |
| Objects (folders) / custom fields | 353 / 3,685 | 5,804 field files including standard fields; 161 validation rules; 71 record types |
| Layouts / Lightning pages / quick actions | 214 / 59 / 59 | |
| LWC / Aura / Visualforce pages / VF components | 40 / 14 / 34 / 30 | |
| Apps / tabs / report types / sharing rules | 37 / 20 / 190 / 168 | |
| Workflow files / process flow migrations | 18 / 121 | 120 workflow rules, 81 of them inactive |
| Permission sets / profiles / queues | 118 / 2 / 103 | Only 2 of the 56 profiles are kept in source. |
| Custom metadata records / labels / global value sets | 6 / 1 file / 5 | |
| Named credentials / remote site settings | 2 / 13 | |

**Not in source:** managed-package components (Data Cloud `ssot__`, DocuSign `dfsle__`, Amazon Connect, Gong, HubSpot, Slack and 25 other namespaces), reports, dashboards and documents.

## External systems
Odie API · CTI Picker (`adh8.com`) · Cheat Sheet service (`adh8.com`) · Delighted surveys · Twilio (through Odie) · AWS (Named Credential `ExecuteAwsService`) · Zoom · inbound email services. See [TECH-019](../07-Technical/TECH-019_Integrations.md).

## Current state and top priorities
1. **Security:** credentials and keys are in the metadata and in the repo ([CON-001](../05-Conflicts/CON-001_Hardcoded-Credentials-And-Secrets.md)).
2. **Documentation refresh:** TECH-001 to TECH-021 describe the 2026-10-13 snapshot. 27 classes were since refactored in the org ([CR-002](../04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md)).
3. **Automation cleanup:** overlapping Lead and Case owner automation, inactive triggers, failed workflow migrations ([CON-002](../05-Conflicts/CON-002_Multiple-Triggers-Per-Object.md) to [CON-004](../05-Conflicts/CON-004_Old-And-New-Automation-Both-Active.md)).
4. **Hardcoded Ids** in flows and workflow rules ([CON-006](../05-Conflicts/CON-006_Environment-And-Deployment-Dependencies.md)).

## Reference files (local only, not in Git)
- `Reference-Files/Full Sandbox User Report.xlsx` and `… - Updated.xlsx`: sandbox user list. Contains personal data, so don't commit it.
- Apex functional document, test plan and business summary CSV: in `07-Technical/Reference-Files/`.
