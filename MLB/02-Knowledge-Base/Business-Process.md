# Business Process

| | |
|---|---|
| **Document ID** | KB-002 |
| **Last updated** | 2026-10-09 |

## 1. Ticket sales agreement process (Opportunity)

1. The Sales Rep opens the Opportunity and runs the **Agreement Flow** (screen flow `Agreement_Flow`).
2. The rep picks the agreement type (**Membership, Multi-Product, Flex or Suite Lease**) and enters its details, including **Ticket Office Comments**. The flow saves the values on the Opportunity. For Membership it also creates `Membership_Agreement__c` seat and parking rows.
3. The rep clicks **Send Agreement**, and Adobe Sign creates the agreement (`echosign_dev1__SIGN_Agreement__c`) linked to the Opportunity.
4. Adobe Sign routes the agreement: **approvers first** (Sales Manager and others, per template), then the **customer signer**.
5. Salesforce emails the **Ticket Office** (To) and the **Sales Manager** (`Opportunity_Owner_Manager__c`), with reply-to the Sales Rep, when:
   - the agreement is **first sent** and its total is **$50,000 or more**
   - the **Sales Manager approves or declines** it
   - the **customer signs** (the email carries the signed PDF) **or declines** it
6. After the customer signs, Adobe Sign stores **"<agreement> - signed.pdf"** on the agreement and emails the executed copy to the signers.

Email rules: [REQ-003](../2026-10/03-Requirements/REQ-003_Ticket-Office-Email-Triggering-Conditions.md). Content per type: [TECH-003](../2026-10/07-Technical/TECH-003_Ticket-Office-Email-Field-Mapping.md).

### Agreement value per type

| Agreement type | Value field on Opportunity |
|---|---|
| Membership | `Total_MembershipPrice__c` |
| Suite Lease | `This_Season_Total_Amount__c` |
| Multi-Product | `Total_Multi_Product__c` (allocations: `Amount_allocated_to_Flex__c`, `Amount_allocated_to_Suites__c`, `Amount_allocated_to_Groups__c`) |
| Flex | `Total_Flex_Membership__c` |

## 2. Vendor certificate and agreement process (Contact)

Applies only to Contacts of record type **Vendor Contact** whose Account **Type** is Food and Beverage, Non-Profit or Sales Activation.

1. The vendor contact page shows the **Certificate Reminder** banner and a popup listing which certificates are still needed.
2. The user clicks **Upload Certificate**, and the existing Upload Certificate flow runs. Uploading a certificate ticks its checkbox automatically. **Nobody can tick these boxes by hand.**
3. **Agreement Status** moves automatically:
   - **Document Pending** until every required certificate is uploaded, then **Document Uploaded**
   - **Ready to Send** once the user completes **Create Agreement** (Vendor Activation flow)
   - after **Send Agreement**, it follows the **latest Adobe agreement**: Draft → Pre-Send → … → Out for Approval → Out for Signature → Signed (or Cancelled / Declined, Expired)

### Required certificates by Account Type (current rule)

| Account Type | Required | Optional |
|---|---|---|
| Food and Beverage | Food Service Certificate, W-9 | — |
| Non-Profit | COI | W-9 |
| Sales Activation | COI | W-9 |

### Buttons on the vendor Contact page

| Button | Shown when (all also require record type = Vendor Contact) |
|---|---|
| Upload Certificate | A required or optional certificate for the Account Type is still missing |
| Create Agreement | All required certificates uploaded **and** status is Document Uploaded, Cancelled / Declined or Expired |
| Send Agreement | Vendor Account Type **and** status is anything except Document Pending or Document Uploaded (from Ready to Send onward) |

Design detail: [TECH-004](../2026-10/07-Technical/TECH-004_Vendor-Certificate-and-Agreement-Status-Automation.md).

## 3. People and roles

| Role | Part in the process |
|---|---|
| Sales Rep (Opportunity owner) | Runs the Agreement Flow and sends the agreement; reply-to on Ticket Office emails |
| Sales Manager (`Opportunity_Owner_Manager__c`) | Approves in Adobe Sign; receives the Ticket Office email |
| Ticket Office | Receives the agreement emails; address in [KB-004](KB-004_Salesforce-Environment.md) |
| Vendor user | Uploads vendor certificates and creates and sends vendor agreements |
