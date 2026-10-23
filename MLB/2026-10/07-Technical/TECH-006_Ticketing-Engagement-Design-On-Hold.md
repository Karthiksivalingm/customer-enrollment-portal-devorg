# TECH-006 — Ticketing Engagement fields and Opportunity link (design kept for rebuild; ON HOLD)

| | |
|---|---|
| **ID** | TECH-006 |
| **Requirement** | [REQ-011](../03-Requirements/REQ-011_Ticketing-Engagement-Fields-and-Opportunity-Link.md) |
| **State** | Built and verified, then **reverted** 2026-10-09 |

## 1. Fields on `Ticketing_Engagement__c`
| API name | Label | Type |
|---|---|---|
| `Member_Since__c` | Member Since | Text(4), help "Enter a 4-digit year, e.g. 2015." |
| `Traditional_Group_Since__c` | Traditional Group Since | Text(4) |
| `Nightly_Suite_Since__c` | Nightly Suite Since | Text(4) |

Validation rule per field (`<Field>_Year_Only`):
```
AND(NOT(ISBLANK(f)), OR(NOT(REGEX(f, "[0-9]{4}")), VALUE(f) < 1900, VALUE(f) > YEAR(TODAY())))
```
- Layout section "Since (Year)".
- FLS: same profiles and permission sets as object access (edit where the object is editable).
- **Tested:** 2015 and blank save. 1,234 / 2,015 / 20 15 are too long. abcd / 15 / 1899 / 2099 are blocked.

## 2. Opportunity link
| Item | Design |
|---|---|
| Field | `Opportunity.Ticketing_Engagement__c`, lookup, delete constraint SetNull, read-only FLS for profiles with Opportunity read |
| Opportunity side | Before-save flow: on create, AccountId change, or blank link, find the Ticketing Engagement where `ProVenue_ID__c` = TRIM(BLANKVALUE(`Account.ProVenue_ID__c`, `Account.ProVenue_ID__pc`)); clear the link if there's no ID or no match |
| Ticketing Engagement side | After-save flow: on create or ProVenue change, update Opportunities where `ProVenue_ID__c` = the record's and the lookup is null |
| Page | `Ticketing_Opportunity_LRP`: field after Account Name (Dynamic Forms, readonly), plus a `console:relatedRecord` card in the sidebar (`lookupFieldName` = Ticketing_Engagement__c, `updateQuickActionName` = Ticketing_Engagement__c.Engagement_Summary) |
| Card fields | ProVenue, Member Since, Traditional Group Since, Nightly Suite Since, Number of Seasons, Status, Current Season Tickets, Current Season Spend, All-Time Spend, Buyer Classification |

**Tested:** link on Opportunity create, link when the engagement arrives later, link cleared on an Account without a ProVenue ID.

## 3. Gotchas found
- The Related Record component's metadata name is **`console:relatedRecord`**, not `force:relatedRecord`.
- Deploy the lookup field **before** the page that uses it.
- Don't use `Opportunity.ProVenue_ID__c` (a formula) in before-save logic ([CON-013](../05-Conflicts/CON-013_Opportunity-ProVenue-ID-Is-A-Formula.md)).
- Flows are deleted through the Tooling API `Flow` records. A destructive deploy fails with "insufficient access rights".
