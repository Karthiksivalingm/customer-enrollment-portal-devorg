# CON-012 — Open data, user and tooling items

| | |
|---|---|
| **ID** | CON-012 |
| **Status** | ⚠ **Open** |

| # | Item | Impact | Proposed action | Waiting on |
|---|---|---|---|---|
| 1 | `Opportunity_Owner_Manager__c` blank on test Opportunities | Sales Manager gets no Ticket Office email | Fill it in on test records; confirm how it's populated in production | User |
| 2 | 1 Non-Profit Vendor Contact with blank Agreement Status | Send Agreement button shows; status never set | One-time update of existing vendor contacts | User approval |
| 3 | Jason Liss, Sonja Colon, Ruben Smith emails end in `.invalid` ([KB-005](../02-Knowledge-Base/KB-005_Sandbox-User-Status.md)) | They get no sandbox email | Fix emails, verify, reset passwords | User approval (sends real emails) |
| 4 | Logo on Adobe agreement PDFs? | Unclear scope ([REQ-004](../03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md)) | Clarify | Client |
| 5 | ~~GitHub not connected~~ | ✅ Resolved 2026-10-14: project kept in GitHub `sfdcut/SFDC`, folder `MLB/` ([KB-004](../02-Knowledge-Base/KB-004_Salesforce-Environment.md)) | — | — |
| 6 | Real Ticket Office mailbox ([CON-010](CON-010_Ticket-Office-Address-Stored-In-Two-Places.md)) | Test address in use | Update the alert and the label | Client |
| 7 | Agreement files deleted before CR-018 | Possibly recoverable for 15 days | Check the Recycle Bin | User |
| 8 | Sonja Colon has **no Manager** on her user record | Approvals and manager lookups have no target | Set her Manager | User (who?) |
| 9 | Ruben Smith (manager of Billy Marlin) email ends in `.invalid` | Manager emails don't reach him | Fix and verify his email (same as #3) | User approval |
| 10 | Stray Membership row MA-414 on Opportunity 006iV000000ZBBtQAO, which has no Agreement Type (created 2026-10-14, all fields blank) | When that Opportunity later gets a Membership agreement, Edit Agreement will treat MA-414 as row 1 | Delete MA-414 | User approval |
| 11 | Hidden Membership fields on Opportunity 006iV000000ZBBtQAO hold sample values from a screenshot run on 2026-10-15 (Term Length 2, Season 2026-2027, Paid to Date 100) | Not visible and not prefilled while there is no agreement; overwritten by the next Create Agreement | None needed, or clear them | — |
| 12 | Production steps that are data, not metadata: Adobe template row 0000031 → Attachments; certificate backfill; Sales Manager ticks on users ([CR-035](../04-Change-Records/CR-035_Certificate-Only-Agreement-Attachments.md), [CR-034](../04-Change-Records/CR-034_User-Sales-Manager-Checkbox.md)) | Missed steps break certificate attachments or empty the Sales Manager list | Put them in the deployment document | Deployment |
| 13 | "1 year New Business" term not wired ([CON-017](CON-017_One-Year-New-Business-Term-Not-Wired.md)) | Wrong term values if chosen | Get the business rules | Client |
| 14 | 18 existing Vendor Contacts no longer get the certificate and agreement features (CR-036) | No banner or buttons; Agreement Status no longer follows Adobe | Move them to the Sales Vendor record type, or leave as is | User |
| 15 | Billy Marlin and Ruben Smith still ticked as Sales Manager | Shown in the Sales Manager list with the five managers | Untick, or keep | User |
| 16 | Four Sales Reps hold MLB_Sales_Manager_Access, which also shows the Internal Contact record type; the set's name says Sales Manager | Reps can create Internal contacts | Keep, give reps a separate set without Internal, or rename the set | User |
