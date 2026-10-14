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
| 5 | GitHub not connected; project not a Git repo ([KB-004](../02-Knowledge-Base/KB-004_Salesforce-Environment.md)) | No version control | `gh auth login`, choose a repo | User (paused) |
| 6 | Real Ticket Office mailbox ([CON-010](CON-010_Ticket-Office-Address-Stored-In-Two-Places.md)) | Test address in use | Update the alert and the label | Client |
| 7 | Agreement files deleted before CR-018 | Possibly recoverable for 15 days | Check the Recycle Bin | User |
| 8 | Sonja Colon has **no Manager** on her user record | Approvals and manager lookups have no target | Set her Manager | User (who?) |
| 9 | Ruben Smith (manager of Billy Marlin) email ends in `.invalid` | Manager emails don't reach him | Fix and verify his email (same as #3) | User approval |
