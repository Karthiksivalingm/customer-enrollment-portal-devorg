# CON-002 — Requirement vs email alert limits (send as Rep, CC Manager, attachments)

| | |
|---|---|
| **ID** | CON-002 |
| **Status** | ✅ Workarounds agreed |
| **Found** | 2026-10-05 |

| Requirement asked | Platform limit | Agreed workaround |
|---|---|---|
| "Sent from: Sales Rep" | Email alerts send as the running user (here, whoever changes the Adobe status, usually the Adobe integration user) or an org-wide address. None is configured. | **Reply-to = Sales Rep**, set in the Visualforce template (`replyTo="{!relatedTo.Owner.Email}"`); Rep's name and signature in the footer |
| "CC Sales Manager" | Email alerts have no CC; Additional Emails and recipients all go on **To** | Sales Manager on the To line |
| Signed PDF attached | Email alerts can't attach a per-record file | Apex `TicketOfficeSignedEmail` sends the signed email only ([REQ-005](../03-Requirements/REQ-005_Signed-Agreement-Email-With-PDF.md)) |
| Status line in the email | The template is built on the Opportunity, but the status lives on the child Adobe agreement; VF templates can't query | VF component plus Apex controller reads the latest agreement status. Client chose this over a new Opportunity field. |
