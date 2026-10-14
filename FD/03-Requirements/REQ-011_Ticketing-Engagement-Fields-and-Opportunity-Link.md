# REQ-011 — Ticketing Engagement year fields and link on Opportunity

| | |
|---|---|
| **ID** | REQ-011 |
| **Status** | ⏸ **ON HOLD**: built 2026-10-08, **fully reverted 2026-10-09** at the client's request |
| **Related** | CR-022 · TECH-006 |

## Business need (as requested)
1. On `Ticketing_Engagement__c`, create **Member Since**, **Traditional Group Since** and **Nightly Suite Since** (year, YYYY) as **text** fields that accept only numbers, so the year shows as 1234 and not 1,234.
2. Update the Opportunity page to include the Ticketing Engagement record.

## Decisions taken (kept for when the hold is lifted)
| Topic | Decision |
|---|---|
| Field type | Text(4); validation: 4 digits, between 1900 and the current year, blank allowed |
| How the Opportunity finds the record | **Match by ProVenue ID** (the Account's ProVenue ID; `Opportunity.ProVenue_ID__c` is a formula of it) |
| Page | Ticketing Opportunity page (`Ticketing_Opportunity_LRP`) and the Opportunity Layout |

## Current state
Everything was removed from the sandbox: fields, validation rules, lookup, flows, card and page changes. No data was lost. The design for a rebuild is kept in [TECH-006](../07-Technical/TECH-006_Ticketing-Engagement-Design-On-Hold.md).
