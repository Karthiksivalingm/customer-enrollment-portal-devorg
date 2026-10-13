# Project Overview: EverquoteFullSandbox

## What this project is
This is a Salesforce DX project holding metadata retrieved from the **Everquote full-copy sandbox** (org alias `EverquotefullSandbox`, API 64.0). The source is kept in the private GitHub repository `sasikumarm-web/EverquoteFullSandbox` on the `main` branch, starting from commit `f9c91cf` on 2026-10-13.

## The business, as reflected in the metadata
The org supports several lines of business. This section is inferred from the code and automation, so confirm it with the business owners.

| Business area | What the org does | Main components |
|---|---|---|
| **B2B sales to insurance agents and carriers** | Sells lead and advertising products. Tracks Opportunities, products, upsell and cross-sell, fill rates and closed-won alerts. | Opportunity / OpportunityLineItem triggers, `Upsell__c`, `UpdateFillRateBatch`, `BulkAccountLastOppUpdate`, `OppToCSUpsellRTUpdate`, `OppToStateFarmRTUpdate`, cheat sheet controllers |
| **Lead management and SDR/BDR outreach** | Lead scoring, cadence enrolment, round-robin assignment, first-response timing, call dispositions and lead outcome. | `LeadTrigger` → `LeadHandler`, `AssignLeadToCadencesBatch`, `roundRobin*` / `etcd8_*`, `TaskHandler`, `EventHandler`, BDR flows |
| **Life insurance agency (ODA / Odie)** | Agents quote and sell life products from carriers (AIG, Gerber, Lumico, Reliashield and others). Leads and policies sync with the **Odie** platform. | `ODA*` / `Oda*` controllers, request builders, `OdieWrapper`, `ODA_Policy__c`, `syncLeadOwnerToOdie` |
| **Customer onboarding and success** | Assigns onboarding and Customer Success owners, and runs surveys. | `OnboardingOwnerAssignmentCtrl`, `Customer_Success_Rep__c`, Delighted outbound messages |
| **Customer support** | Email-to-Case matching (including legacy Zendesk Ids), case first-activity timing, Smart Campaign queue routing, and missed-call alerts. | `EmailServiceToFindMatchingCase`, Case flows and workflows, `SendEmailForMissedCallAlertVC` |
| **Telephony (CTI / Voice)** | Links Voice Calls to Contacts and Accounts, refreshes the CTI agent picker, and pauses or resumes Twilio recordings. | `VoiceCallTrigger`, `AutoPopulateContactOnVoiceCall`, `NotifyCTI` |
| **Communities and unsubscribe** | Portal login and self-registration, and email unsubscribe. | `Communities*`, `Site*`, `jrsl_ul_*`, `unsubscribe` |

## Org inventory (in source)
| Metadata | Count | Notes |
|---|---|---|
| Apex classes | 160 | About half are test classes. See [Apex-Classes](../07-Technical-Documents/Apex-Classes/README.md). |
| Apex triggers | 33 | Only 7 are active. See [Triggers](../07-Technical-Documents/Triggers/README.md). |
| Flows | 4 | 55 more migrated flows exist only in the org. |
| Workflow files | 18 objects | 120 rules, 81 of them inactive |
| Process flow migrations | 121 | Records from the Migrate to Flow tool |
| Permission sets / profiles | 111 / 2 | |
| Queues | 103 | |
| Objects / fields / layouts / LWC / Aura / VF | 0 | **Not retrieved yet.** Fields are inferred in [Fields-Reference](../07-Technical-Documents/Fields-Reference.md). |

## External systems
Odie API · CTI Picker (`adh8.com`) · Cheat Sheet service (`adh8.com`) · Delighted surveys · Twilio (through Odie) · inbound email services. See [Integrations](../07-Technical-Documents/Integrations/README.md).

## Current state and top priorities
1. **Security:** rotate the credentials hardcoded in Apex and in the workflow URLs, and move them to Named Credentials. See [Known-Conflicts §1](../05-Conflicts/Known-Conflicts.md).
2. **Completeness:** retrieve objects, fields, layouts, flows, Visualforce, LWC and Aura so the repo becomes a full backup of the org.
3. **Automation cleanup:** remove the overlap of Lead and Case owner automation, inactive triggers and failed workflow migrations.
4. **Hardcoded Ids** in flows and workflow rules.

## Reference files (local only, not in Git)
- `Reference-Files/Full Sandbox User Report.xlsx` and `… - Updated.xlsx`: sandbox user list. Contains personal data, so don't commit it.
- Apex functional document, test plan and business summary CSV: in [07-Technical-Documents/Reference-Files](../07-Technical-Documents/Reference-Files/).
