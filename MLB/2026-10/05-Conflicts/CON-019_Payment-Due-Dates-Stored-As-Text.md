# CON-019 — Payment due dates are stored as text

| | |
|---|---|
| **ID** | CON-019 |
| **Status** | ℹ Known limitation (accepted by the user, 2026-10-27) |
| **Found** | 2026-10-27 |
| **Related** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) · [CR-042](../04-Change-Records/CR-042_Payment-Due-Dates-As-Text.md) · [TECH-011](../07-Technical/TECH-011_Suite-Lease-Payment-Schedule.md) |

## Problem
The agreement had to show payment dates as "November 2, 2026". Date fields always display in each user's locale format (for example 11/2/2026), and the user did not want extra helper fields. So `Payment_Due_Date_1__c` … `_12__c` were made text fields.

Salesforce can't change a field from Date to Text by deployment ("Cannot change type due to existing data"). The fields had to be deleted, purged and recreated with the same API names. The two date values on Opportunity 006iV000000PlTgQAK were lost; the user agreed.

## Consequences
- Reports and list views can't filter, sort or group these fields as dates. Use **Due Date** (`Due_Date__c`, a real date = payment 1) where a date is needed.
- The text must stay exactly "Month D, YYYY": Edit Agreement turns it back into a date. Only the Agreement Flow can write it (lock rule), so manual typing is blocked.
- Data loads or integrations that write these fields must use the same format.

## Option if real dates are needed later
Keep the 12 text fields for the document and add date fields (or a related object) for reporting, filled by the same flow.
