# REQ-002 — Notify the Ticket Office from Salesforce (replace the Adobe Sign CC)

| | |
|---|---|
| **ID** | REQ-002 |
| **Status** | ✅ Built and deployed to sandbox (utdev); content later refined by REQ-004 |
| **Requested** | 2026-10-05 (client requirement "2 – Use SFDC to notify Ticket Office") |
| **Related** | REQ-003 · REQ-004 · REQ-005 · CR-002 · CR-003 · TECH-002 · TECH-003 |

## Business need
The Ticket Office was copied on Adobe Sign agreements. The client wants Salesforce to notify the Ticket Office instead, with the agreement details they need, and to remove the Ticket Office from the Adobe Sign CC.

## Client process (as given)
1. Sales Rep clicks Send Agreement and chooses the agreement type (Flex, Multi-Product, Membership, Suite Lease).
2. Sales Rep enters the details, including Ticket Office Comments, and finishes the screen flow.
3. Sales Rep clicks Send Agreement; the Sales Manager approves in Adobe Sign.
4. **The Ticket Office receives an email from the Sales Rep, CC the Sales Manager, with the agreement details.**
5. After the customer signs, the Ticket Office receives the executed contract.

## Required content (as given)
- **Membership and Suite Lease:** ProVenue ID, Order #, Name and Address of customer, Section, Row, Seats, Price, Payment Plan, Ticket Office Comments
- **Multi-Product and Flex:** ProVenue ID, Order #, Name and Address of customer, Price, Payment Plan, Ticket Office Comments
- **Subject:** "{Agreement Type} Details || {ProVenue ID}"
- **Body:** "Hello Ticket Office, Please see comments below:" followed by the fields

## Scope
- **In:** a classic email template that changes by agreement type, an email alert, and an automatic trigger.
- **Out:** changing the Adobe Sign templates themselves (removing the CC is done in Adobe by the client).

## Decisions taken with the client
| Topic | Decision |
|---|---|
| Template type | **Visualforce** classic template. Needed for repeating Membership seat rows and per-type sections. |
| Ticket Office address | `meshakm@unitedtechno.com` (test address supplied by user) |
| Sales Manager | `Opportunity.Opportunity_Owner_Manager__c` |
| Sales Rep removed from recipients | Yes (2026-10-06) |
| Fields later **removed** by the client | Order #, Address and Payment Plan from the summary first (2026-10-06). Address added back later (REQ-004). Order # and Payment Plan removed for Suite Lease and Multi-Product; Order # removed for Flex. |
| Price fields | Confirmed: Suite Lease `This_Season_Total_Amount__c`, Multi-Product `Total_Multi_Product__c`, Flex `Total_Flex_Membership__c`, Membership `Total_MembershipPrice__c` |

## Platform limits (agreed workarounds)
- **"Sent from the Sales Rep"**: email alerts can't send as the record owner. They send as the running user, and **reply-to is set to the Sales Rep**.
- **"CC Sales Manager"**: email alerts put every recipient on the **To** line; there's no true CC.

## Acceptance criteria
1. The email goes to the Ticket Office and the Sales Manager, with reply-to the Sales Rep.
2. The subject reads `{Agreement Type} Details || {ProVenue ID}`.
3. Each agreement type shows its agreed fields (final list in [TECH-003](../07-Technical/TECH-003_Ticket-Office-Email-Field-Mapping.md)).
4. Membership lists every seat and parking block.

## Open questions
- The real Ticket Office mailbox for production (currently a test address).
