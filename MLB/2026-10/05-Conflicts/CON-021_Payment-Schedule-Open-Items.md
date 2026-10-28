# CON-021 — Payment schedule and Person Account: open items

| | |
|---|---|
| **ID** | CON-021 |
| **Status** | ⚠ Open (items 1–4 and 7 need a decision or action) |
| **Found** | 2026-10-27 / 28 |
| **Related** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) · [REQ-020](../03-Requirements/REQ-020_Person-Account-Type-Values.md) · [CR-039](../04-Change-Records/CR-039_Suite-Lease-Adobe-Document-Tags.md) |

| # | Item | State | Owner / next step |
|---|---|---|---|
| 1 | The new tags are available in both Suite Lease document templates, but they are **not yet placed in the Word documents**. No agreement has been generated with them yet. Document Builder still marks the templates' tags as not up to date. | ⚠ Open | Business: place the tags (CR-039 list) in both Word files, then generate one test agreement without sending it. |
| 2 | Opportunity 006iV000000PlTgQAK still holds Number of Payment Schedule = **"1"** (now an inactive value), and its two due dates were cleared by the CR-042 rebuild. | ⚠ Open | Decide: change it to Full and re-enter the dates through Edit Agreement, or leave it (test record). |
| 3 | The **Ticket Office email** doesn't show the payment schedule. | ⚠ Open question | Decide whether the email should list the number of payments, amount and due dates. |
| 4 | The Person Account page has **two fields labelled "Type"**: the standard Account Type (`Type`, where the new values are) and a custom `Type__c` (External, Group …). There is also a text field labelled "Account Type" (`Account_Type__pc`). Users can pick the wrong one. | ⚠ Open | Decide whether to relabel `Type__c` (for example "Lead Type") or remove one from the page. |
| 5 | Equal payments: the amount is rounded to cents, so the payments can add up to a cent or two less or more than the total (1,000 ÷ 3 = 333.33 × 3 = 999.99). | ℹ Known, accepted ("amount should be same") | — |
| 6 | Org automation stamps `Opportunity.Prevent_Validations__c` with the time of every save, so a test restore can't put back its old value. | ℹ Known | Expected in every Opportunity restore. |
| 7 | KB-006 Agreement Testing Guide: the text was updated for the payment schedule on 2026-10-28, but its Suite Lease screenshots still show the old screen (read-only Due Date). The online copy of the guide was not republished. | ⚠ Open | Retake the Suite Lease screenshots, and republish the online copy, when the guide is next shared. |
| 8 | The classic page layout has the schedule fields in one block after Due Date; it was not rearranged (the Lightning page is what users see). | ℹ Known | Rearrange only if asked. |
