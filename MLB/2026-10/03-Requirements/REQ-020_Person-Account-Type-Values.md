# REQ-020 — Food and Beverage and Non-Profit in Account Type for Person Accounts

| | |
|---|---|
| **ID** | REQ-020 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-28) |
| **Requested** | 2026-10-27 |
| **Related** | [CR-043](../04-Change-Records/CR-043_Person-Account-Type-Values.md) · [TECH-011](../07-Technical/TECH-011_Suite-Lease-Payment-Schedule.md) · [CON-021](../05-Conflicts/CON-021_Payment-Schedule-Open-Items.md) · [ATR-003](../08-QA/01-Automated-Testing/ATR-003_Suite-Lease-Payment-Schedule-And-Person-Account-Type.md) · [MTC-003](../08-QA/02-Manual-Testing/MTC-003_Suite-Lease-Payment-Schedule-And-Person-Account-Type.md) |

## Business need
The Account Type values **Food and Beverage** and **Non-Profit** were not offered on Person Accounts, so Person Accounts could not be classified like vendor accounts. The agreement document reads the account's type through `{{Opportunity.Account.Type}}`.

## Scope
- **In:** Account record type **Person Account**, standard field **Account Type** (`Type`; shown as "Type" next to Industry on the Person Account page).
- **Out:** the other Account record types; the custom picklist also labelled "Type" (`Type__c`, values External, Group …), which is a different field (CON-021).

## Functional behaviour
- Editing or creating a Person Account offers Account Type: Analyst, Competitor, Customer, Integrator, Investor, Partner, Press, Prospect, Reseller, Other, **Food and Beverage**, **Non-Profit**, Sales Activation.
- "Sales Vendor" was not added (not requested).

## Acceptance criteria
1. Food and Beverage and Non-Profit are offered on Person Accounts and can be saved.
2. Other record types are unchanged (Business Account still doesn't offer them).

All verified: see ATR-003 (TC-020-01 to TC-020-03) and MTC-003.

## Assumptions
None.

## Open questions
None.
