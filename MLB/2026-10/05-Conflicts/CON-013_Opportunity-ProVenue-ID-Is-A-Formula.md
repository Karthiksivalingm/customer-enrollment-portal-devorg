# CON-013 — Opportunity.ProVenue_ID__c is a formula of the Account

| | |
|---|---|
| **ID** | CON-013 |
| **Status** | ℹ Known; relevant when [REQ-011](../03-Requirements/REQ-011_Ticketing-Engagement-Fields-and-Opportunity-Link.md) resumes |

## Finding
- `Opportunity.ProVenue_ID__c` = formula `Account.ProVenue_ID__c`.
- A before-save flow can't use it (deploy error *"Field Account.ProVenue_ID__c does not exist"* through the referenced formula).
- Person Accounts may hold the ID in `Account.ProVenue_ID__pc` instead.

## Guidance
Read `Account.ProVenue_ID__c`, falling back to `Account.ProVenue_ID__pc`, directly in flows. Don't use the Opportunity formula field in before-save logic.
