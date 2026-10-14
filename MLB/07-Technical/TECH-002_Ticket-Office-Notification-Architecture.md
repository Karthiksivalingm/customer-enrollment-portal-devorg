# TECH-002 — Ticket Office notification: architecture

| | |
|---|---|
| **ID** | TECH-002 |
| **Requirements** | [REQ-002](../03-Requirements/REQ-002_Ticket-Office-Notification-Email.md) · [REQ-003](../03-Requirements/REQ-003_Ticket-Office-Email-Triggering-Conditions.md) · [REQ-004](../03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md) · [REQ-005](../03-Requirements/REQ-005_Signed-Agreement-Email-With-PDF.md) |

## 1. Flow of events
```
Adobe Sign updates echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c
        │
        ▼
Flow: Adobe_Agreement_Notify_Ticket_Office  (record-triggered, AFTER save, Update)
  Entry: ISCHANGED(Status) AND Opportunity__c not blank AND Opportunity__r.Agreement_Type__c not blank
  Decision Should_Notify_Ticket_Office (first match wins):
    1. Customer_Signed        Status = Signed               → Apex action TicketOfficeSignedEmail
    2. Manager_Approved_or_Declined  frmManagerApprovedOrDeclined → Email alert
    3. Sent_At_50k_Or_More     frmSentAt50kOrMore            → Email alert
    4. Customer_Signed_or_Declined (label "Customer Declined") frmCustomerSignedOrDeclined → Email alert
        │
        ├── Email alert Opportunity.Ticket_Office_Agreement_Details
        │      To: Additional Email meshakm@unitedtechno.com + userLookup Opportunity_Owner_Manager__c
        │      Sender: CurrentUser · Template: unfiled$public/Ticket_Office_Agreement_Details
        │
        └── TicketOfficeSignedEmail (invocable → Queueable, 1-min delay)
               finds "<name> - signed.pdf" (ContentDocumentLink on the agreement, title LIKE %signed%, pdf)
               retries every 2 min up to 4 attempts, then sends without it
               renders the same template, To: Label.Ticket_Office_Email + manager email, reply-to owner
```

## 2. Flow formulas
| Formula | Expression (summary) |
|---|---|
| `frmAgreementTotal` | CASE(Agreement_Type__c): Membership → `Total_MembershipPrice__c`, Suite Lease → `This_Season_Total_Amount__c`, Multi-Product → `Total_Multi_Product__c`, Flex → `Total_Flex_Membership__c` |
| `frmManagerApprovedOrDeclined` | prior ∈ {Out for Approval, Waiting for Counter-Approval} AND new ∈ {Out for Signature, Approved, Cancelled / Declined} |
| `frmSentAt50kOrMore` | prior ∈ {Draft, Pre-Send, Send in Progress, Created, blank} AND new ∈ {Out for Approval, Out for Signature} AND total ≥ 50000 |
| `frmCustomerSignedOrDeclined` | prior ∈ {Out for Signature, Waiting for Counter-Signature} AND new = Cancelled / Declined (Signed is handled by outcome 1) |

## 3. Email template and components
| Component | Type | Purpose |
|---|---|---|
| `Ticket_Office_Agreement_Details` | Visualforce email template; relatedTo Opportunity, recipientType User, `replyTo={!relatedTo.Owner.Email}`, renders without sharing | Whole email |
| `TicketOfficeAgreementStatus` | VF component (global), attribute `oppId` | "Agreement Update" block: label, note, icon, colours, Adobe status |
| `TicketOfficeAgreementSummary` | VF component (global), attribute `oppId` | Agreement Summary table |
| `TicketOfficeLogo` | VF component (global), attributes `width`, `height` | Marlins logo from the public document URL |
| `TicketOfficeAgreementStatusCtrl` | Apex controller (without sharing) shared by all three | Latest agreement for the Opportunity (ORDER BY LastModifiedDate DESC); summary columns (Membership seat and parking sums from `Membership_Agreement__c`); locale-free money format; logo URL `Url.getOrgDomainUrl() + /servlet/servlet.ImageServer?id=<Document>&oid=<OrgId>` |

**Why Visualforce:** a repeating seat list (`apex:repeat` over `Membership_Agreements__r`), per-type sections (`rendered=`), and currency formatting. Text, HTML and Lightning templates can't do these.

**Why components:** VF email templates can't run queries. Components used in email templates must have **global** access, and an attribute name can't equal its `assignTo` property.

## 4. Status presentation (from `echosign_dev1__Status__c`)
| Adobe status | Label | Colour |
|---|---|---|
| Out for Approval | Sent for Sales Manager approval | Amber #E08600 |
| Out for Signature / Approved | Approved by Sales Manager | Green #0E8A4F |
| Signed | Signed by customer | Blue #0083B8 |
| Cancelled / Declined | Agreement declined | Red #EF3340 |
| other | raw status | Slate #41748D |

## 5. Rejected options
- **Email alert only:** can't attach the PDF and can't read the agreement status.
- **New Opportunity status field:** declined by the client.
- **Lightning email template:** can't loop child records.
- **Callback Site:** see [CON-005](../05-Conflicts/CON-005_Adobe-Sign-Status-Not-Syncing-In-Sandbox.md).

## 6. Tests
- `TicketOfficeAgreementStatusCtrlTest`: 5 tests, 98% coverage.
- `TicketOfficeSignedEmailTest`: 3 tests, 90% coverage.
- Gaps: [CON-011](../05-Conflicts/CON-011_Gaps-Against-Coding-Standards.md).
