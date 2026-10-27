# CON-038 — Qualify rule: Leads already Qualified, and other limits

| | |
|---|---|
| **ID** | CON-038 |
| **Status** | ⚠ Open: client decision needed (item 1) |
| **Found** | 2026-10-27 during REQ-039 |
| **Area** | Lead, Create Shopify |

## Conflicts
| # | Conflict | Effect | Proposed handling |
|---|---|---|---|
| 1 | **Leads already Qualified** before the rule existed are not checked (the rule fires only when Status changes) | **153** open Qualified Leads in the sandbox have Sales Channel or Sector blank and can still use Create Shopify | Client to choose: fill the values (data update), move them back to Working, or accept |
| 2 | A Lead **created** directly with Status Qualified (data load or API) is not checked | Rare; the Typeform and web flows create Leads as New | Accept; checking new Leads too would break existing tests that create Qualified Leads |
| 3 | Standard Salesforce **Convert** sets Status to Qualified, so the rule had to exclude it (`NOT(IsConverted)`) | Standard Convert with blank values still works | Accept: Goodr uses Create Shopify, not standard Convert |
| 4 | The rule's error and the existing trigger check (Terms of Service, Has Physical Store, Resale Certificate) can both apply | The user may see both messages at once | Accept; both are valid reasons |
| 5 | Two sandbox classes don't compile (`CaseTeamAssignmentQueueable`, `WinbackStatusScheduler`) | RunLocalTests fails in the sandbox for every change | Fix separately, not part of this change |

## Query for item 1
```sql
SELECT Id, Name, Status, Sales_Channel__c, Sector__c, Owner.Name
FROM Lead
WHERE IsConverted = false AND Shopify_Created__c = false AND Status = 'Qualified'
  AND (Sales_Channel__c = null OR Sector__c = null)
```
