# REQ-019 — Suite Lease payment schedule and editable license fees

| | |
|---|---|
| **ID** | REQ-019 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-28) |
| **Requested** | 2026-10-27 (with follow-up changes the same day) |
| **Related** | [CR-038](../04-Change-Records/CR-038_Suite-Payment-Plan-Build.md) · [CR-039](../04-Change-Records/CR-039_Suite-Lease-Adobe-Document-Tags.md) · [CR-040](../04-Change-Records/CR-040_Opportunity-Page-Suite-Sections.md) · [CR-041](../04-Change-Records/CR-041_Payment-Schedule-One-Amount-And-Rename.md) · [CR-042](../04-Change-Records/CR-042_Payment-Due-Dates-As-Text.md) · [TECH-011](../07-Technical/TECH-011_Suite-Lease-Payment-Schedule.md) · [CON-019](../05-Conflicts/CON-019_Payment-Due-Dates-Stored-As-Text.md) · [CON-020](../05-Conflicts/CON-020_Opportunity-Page-Visibility-Filter-Limits.md) · [CON-021](../05-Conflicts/CON-021_Payment-Schedule-Open-Items.md) · [ATR-003](../08-QA/01-Automated-Testing/ATR-003_Suite-Lease-Payment-Schedule-And-Person-Account-Type.md) · [MTC-003](../08-QA/02-Manual-Testing/MTC-003_Suite-Lease-Payment-Schedule-And-Person-Account-Type.md) |
| **Changes** | [REQ-014](REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) (locked agreement fields) |

## Business need
1. Sales users must be able to edit **Year 1 to Year 5 License Fee** directly on the Opportunity; the manual-edit lock blocked them.
2. When a Suite Lease agreement is entered, the rep picks how many payments the customer will make and enters a due date for each. Salesforce works out the payment amount and stores the schedule, so it can be used in the agreement document.

## Scope
- **In:** Opportunity fields for the payment schedule; the Suite Lease screen of the Agreement Flow (create and edit); the manual-edit lock on agreement fields; the Opportunity page and layout; the two Suite Lease Adobe document templates (field tags).
- **Out:** Membership, Multi-Product and Flex agreements; the Ticket Office email (unchanged, see CON-021); placing the tags inside the Word documents (done in Adobe by the business, see CON-021).

## Functional behaviour
### License fees
- Year 1 to Year 5 License Fee can be edited manually by every user who has edit access. The Agreement Flow still fills them as before.

### Payment schedule on the Suite Lease screen
- **Number of Payment Schedule** (required dropdown): **Full** or **2 to 12** (number of monthly payments). "1" is not offered: one payment is the same as Full.
- **Full** shows one required field labelled **Due Date**.
- **2 to 12** shows that many required fields, **Payment 1 Due Date** to **Payment N Due Date**. The screen can't be saved until each one is filled in.
- **Payment Amount** is calculated: This Season Total Amount ÷ number of payments, rounded to cents. Every payment has the same amount, so the total can differ from the sum by a cent or two (for example 1,000 ÷ 3 = 333.33).
- On save, the Opportunity stores:
  - Number of Payment Schedule
  - Payment Amount (text, numbers only)
  - Payment 1 to 12 Due Date as text written out as **Month D, YYYY**, for example **November 2, 2026**; the unused ones are cleared
  - **Due Date** = the first payment date (the existing date field)
- The confirmation message shows the number of payments, the payment amount and the first due date.
- **Edit Agreement** opens with the saved schedule and dates filled in.

### Data rules
- Payment Amount accepts numbers only, with up to 2 decimals (for example 1250 or 1250.50). Letters, symbols, commas and negative values are rejected: "Payment Amount can contain numbers only (for example 1250 or 1250.50). Letters, symbols and commas are not allowed."
- Number of Payment Schedule, Payment Amount and the 12 due dates are locked like the other agreement details: only the Agreement Flow can change them.

### Opportunity page and document
- Opportunity page, **Suite Lease Details**: suite fields on the left, amounts, years and Year 1–5 License Fee on the right.
- New section **Suite Payment Plan** (Suite Lease only): Number of Payment Schedule and the due dates in use on the left; Due Date and Payment Amount on the right.
- Adobe document templates "Suite Lease Agreement" (under and over $50k) offer the tags in [CR-039](../04-Change-Records/CR-039_Suite-Lease-Adobe-Document-Tags.md), including `{{Opportunity.Payment_Due_Date_1__c}}` … `{{Opportunity.Payment_Due_Date_12__c}}`, `{{Opportunity.Payment_Amount__c}}`, `{{Opportunity.Number_of_Payment_Plans__c}}` and `{{Opportunity.Account.Type}}`.

## Acceptance criteria
1. Year 1–5 License Fee save when edited manually (sales user and administrator).
2. The dropdown offers Full and 2–12; Full shows one "Due Date"; N shows N due dates; all shown dates are required.
3. Saving a 3-payment schedule on a $1,111 Suite Lease stores 3, 370.33, "November 2, 2026", "December 2, 2026", "January 2, 2027" and Due Date 2026-11-02.
4. Edit Agreement brings the schedule and dates back.
5. Manual changes to the schedule fields are blocked; Payment Amount rejects non-numbers.
6. The Opportunity page shows only the due dates in use.

All verified: see ATR-003 (TC-019-01 to TC-019-17) and MTC-003.

## Assumptions
- API names were kept when labels changed: the schedule field is still `Number_of_Payment_Plans__c` (label "Number of Payment Schedule"), so its Adobe tag did not change.
- The due dates are text so the agreement shows "November 2, 2026". They can't be filtered or sorted as dates in reports (CON-019).

## Change history
| Date | Change | CR |
|---|---|---|
| 2026-10-27 | Payment plan built (Full, 1–12; 12 amount fields); fees unlocked; DEF-002 fixed; on-screen summary line removed; "Due Date" label for Full | CR-038 |
| 2026-10-27 | Adobe document tags added to both Suite Lease templates | CR-039 |
| 2026-10-27 | Opportunity page sections arranged | CR-040 |
| 2026-10-27 | Renamed to Number of Payment Schedule; one Payment Amount instead of 12; option "1" removed | CR-041 |
| 2026-10-27 | Due dates stored as text "Month D, YYYY" | CR-042 |

## Open questions
See [CON-021](../05-Conflicts/CON-021_Payment-Schedule-Open-Items.md): Word templates, the old "1" value on one record, the Ticket Office email, and the classic layout order.
