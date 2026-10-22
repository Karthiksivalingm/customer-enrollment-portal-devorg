# REQ-038 — Sales Channel V1 and Sector V1 on Contact, Lead and Opportunity, in a BI section

| | |
|---|---|
| **ID** | REQ-038 |
| **Status** | ✅ Done in the sandbox (2026-10-22) |
| **Requested** | 2026-10-22 (project lead) |
| **Related** | [CR-031](../04-Change-Records/CR-031_V1-Fields-And-BI-Section.md) · [REQ-010](REQ-010_V1-Backup-Fields.md) · [TECH-010](../07-Technical/TECH-010_Section-Filters-And-BI-Section.md) · [ATR-003](../08-QA/01-Automated-Testing/ATR-003_Hide-Shopify-Sections-And-BI-V1-Fields.md) · [MTC-004](../08-QA/02-Manual-Testing/MTC-004_Hide-Shopify-Sections-And-BI-V1-Fields.md) |

## Business need
Account already keeps the original Sales Channel and Sector in **Sales Channel V1** and **Sector V1** ([REQ-010](REQ-010_V1-Backup-Fields.md)). The same backup fields are needed on every object that has a Sales Channel field, shown together in a section named **BI** on the record pages.

## Scope
- **In:**
  - new fields `Sales_Channel_V1__c` and `Sector_V1__c` on **Contact, Lead and Opportunity**, an exact copy of the Account fields (Text 50, same label, description and help text);
  - the same field access as on Account: System Administrator read and edit, Account Management read only;
  - a **BI** section with the two fields on every record page in use: Account (Company, Franchise, Store Location), Contact, Lead, Opportunity (Three Column, Updated).
- **Out:** filling the new fields with data, lead conversion mapping, page layouts and the Lead pages that are not assigned to anyone.

## Functional behaviour
- The BI section sits directly after the main information section of each page.
- On Account the two existing V1 fields **move** from Account Information to BI (a field can only appear once on a page).
- The new fields start empty.

## Acceptance criteria
1. Contact, Lead and Opportunity each have Sales Channel V1 and Sector V1, identical to the Account fields.
2. Only System Administrators can edit them; Account Management can read them.
3. Every record page in use has one BI section holding the two fields, each field once.
4. No existing logic changes (Sales Channel, Sector, Cluster).

## Assumptions
- Opportunity was included because it also has a Sales Channel field (confirmed by "Deploy to Sandbox" on 2026-10-22).

## Open questions
- Should the new fields be filled from the current values (data load), and should Lead V1 map to Contact / Opportunity V1 on conversion?
