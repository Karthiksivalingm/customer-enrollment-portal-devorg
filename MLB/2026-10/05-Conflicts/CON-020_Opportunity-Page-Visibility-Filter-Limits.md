# CON-020 — Opportunity page filters for the payment due date rows

| | |
|---|---|
| **ID** | CON-020 |
| **Status** | ✅ Closed with a workaround |
| **Found** | 2026-10-27 |
| **Related** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) · [CR-040](../04-Change-Records/CR-040_Opportunity-Page-Suite-Sections.md) · [CR-041](../04-Change-Records/CR-041_Payment-Schedule-One-Amount-And-Rename.md) |

## Problem
On the Suite Payment Plan section, each Payment N Due Date row should show only when the schedule has N or more payments. Lightning page field filters hit three platform limits (each was a failed deploy):

| Attempt | Error |
|---|---|
| Filter on the due date itself (Date field) | "The 'Record.Payment_Due_Date_1__c' field's type isn't supported." |
| Number of Payment Schedule "is not blank" | "'{!Record.Number_of_Payment_Plans__c}' is a picklist field. 'null' is an invalid field value." |
| "Equals one of" for every value | "You can add a maximum of 10 filters." (Payment 1 needs 12) |
| One-condition rule with a Boolean filter | "Your rule has one filter. Remove the Boolean filter or leave it empty." |

## Workaround (deployed)
| Rows | Rule |
|---|---|
| Payment 1–6 Due Date | Payment Amount is not blank (text field, set whenever a schedule is saved) AND schedule ≠ Full (rows 2–6) AND schedule ≠ each lower number |
| Payment 7–12 Due Date | Schedule equals N, N+1 … 12 (OR, at most 6 conditions) |

Now that the due dates are text fields (CR-042), a simple "Payment N Due Date is not blank" filter would also work. The current rules give the same result and were kept.
