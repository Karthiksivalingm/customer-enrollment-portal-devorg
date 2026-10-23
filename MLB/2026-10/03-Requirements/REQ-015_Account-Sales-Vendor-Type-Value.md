# REQ-015 — Remove "Sales Vendor" from Account Type on the Sales Vendor record type

| | |
|---|---|
| **ID** | REQ-015 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-21) |
| **Requested** | 2026-10-21 (client call) |
| **Related** | CR-032 · ATR-002 · MTC-002 |

## Business need
On Accounts with the **Sales Vendor** record type, the Account Type value "Sales Vendor" should not be offered.

## Scope
- **In:** Account record type `Sales_Vendor`, Account `Type` picklist.
- **Out:** other Account record types (they keep "Sales Vendor" where they had it); the picklist value itself is not deleted.

## Functional behaviour
- Creating or editing a Sales Vendor Account offers every Type value except "Sales Vendor": Analyst, Competitor, Customer, Integrator, Investor, Partner, Press, Prospect, Reseller, Other, Food and Beverage, Non-Profit, Sales Activation.

## Acceptance criteria
1. "Sales Vendor" is not available in Type on a Sales Vendor Account.
2. The Vendor Account record type still offers it.

## Assumptions
- No existing Sales Vendor Account used Type = "Sales Vendor" (checked: 0 records), so no data change was needed.

## Open questions
None.
