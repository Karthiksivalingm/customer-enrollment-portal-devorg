# Integrations

| | |
|---|---|
| **Document ID** | KB-003 |
| **Last updated** | 2026-10-09 |

## 1. Adobe Acrobat Sign for Salesforce (managed package `echosign_dev1`)

| Item | Detail |
|---|---|
| Agreement object | `echosign_dev1__SIGN_Agreement__c`; status field `echosign_dev1__Status__c` |
| Links used | `echosign_dev1__Opportunity__c` (Opportunity agreements), `echosign_dev1__Recipient__c` (first recipient Contact, used for vendor agreements) |
| Agreement templates | Multi Product Template >50k / <50k, Suite Lease Agreement >50k / <50k, Vendor Activation Agreement. Approver recipients sign first, then the Signer. |
| Signed document | Saved as a Salesforce **File** named `<agreement name> - signed.pdf`, linked to the agreement, a few seconds around the status change to *Signed* |
| Data mappings | `Agreement File Upload - Opportunity` (signed PDF to the Opportunity) and `Agreement File Upload - Contact` (signed PDF to the agreement's **Recipient** Contact) |
| Status updates into Salesforce | Adobe pushes status changes through **Enable Automatic Status Updates** in the *Adobe Acrobat Sign Admin* tab (OAuth). **This must be re-enabled after every sandbox refresh.** See [CON-005](../2026-10/05-Conflicts/CON-005_Adobe-Sign-Status-Not-Syncing-In-Sandbox.md). |
| Status values used by our automation | Draft, Pre-Send, Send in Progress, Created, Out for Approval, Waiting for Counter-Approval, Approved, Out for Signature, Waiting for Counter-Signature, Signed, Cancelled / Declined, Expired |

**What reacts to Adobe status changes:**
- `Adobe_Agreement_Notify_Ticket_Office` flow, which sends the Ticket Office emails ([TECH-002](../2026-10/07-Technical/TECH-002_Ticket-Office-Notification-Architecture.md))
- `Adobe_Agreement_Update_Contact_Status` flow, which sets the vendor Contact's Agreement Status ([TECH-004](../2026-10/07-Technical/TECH-004_Vendor-Certificate-and-Agreement-Status-Automation.md))

## 2. GCP sync (Ticketing Engagement)

- `Ticketing_Engagement__c` is populated by a GCP integration (field `Last_GCP_Sync__c`, permission set `GCP_Integration`).
- The sandbox currently holds **0** Ticketing Engagement records.
- A planned Opportunity link was built and then reverted; see [REQ-011](../2026-10/03-Requirements/REQ-011_Ticketing-Engagement-Fields-and-Opportunity-Link.md).

## 3. Outbound email

| Item | Detail |
|---|---|
| Sandbox deliverability | Set to **All email** by the user on 2026-10-07. Sandboxes default to *System email only* after a refresh. |
| Org-wide email address | None configured. Alert emails send as the running user (usually the Adobe integration user). |
| Ticket Office address | `meshakm@unitedtechno.com` (test value). Stored in **two** places; see [CON-010](../2026-10/05-Conflicts/CON-010_Ticket-Office-Address-Stored-In-Two-Places.md). |
| Logo hosting | Externally available Document `Marlins_Logo`, served through `/servlet/servlet.ImageServer` (public, no login) |
