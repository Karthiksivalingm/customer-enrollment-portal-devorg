# Case & Email

## EmailServiceToFindMatchingCase

- **Purpose:** Inbound Email Service that threads emails onto existing Cases or creates new Customer Support Cases. `global with sharing`, implements `Messaging.InboundEmailHandler`. (2016; API 65.0.)
- **Entry point:** `handleInboundEmail(Messaging.InboundEmail, Messaging.InboundEnvelope)`.
- **Flow:**
  1. Subject contains `[ ref:…:ref ]` → `Cases.getCaseIdFromEmailThreadId` → attach email to that Case.
  2. Else, if last word of subject is numeric → match Case on `Zendesk_ID__c` (legacy Zendesk ticket number).
     - Found → attach.
     - Not found → create new Case, attach email, and email the user from custom setting `Email_to_Case_Error_User__c` (instance `'User ID'`, field `User_ID_who_should_get_email__c`) with a link to the new Case.
  3. Else → create new Case and attach.
  4. Subject null → nothing is done.
- **New Case values:** `SuppliedEmail`, `SuppliedName`, `Status='New'`, `Priority='Medium'`, `Origin='Email'`, `Subject`, `Description`, record type **`Customer Support`** (by Name), `ContactId`/`AccountId` from first Contact with matching Email (note added when >1 match); active Case `AssignmentRule` applied via DMLOptions.
- **Records written:** `Case`, `EmailMessage` (Incoming, Subject/HtmlBody/TextBody/To/Cc truncated to field length), `Attachment` (text + binary, ParentId = EmailMessage).
- **Custom fields/settings:** `Case.Zendesk_ID__c`; custom setting `Email_to_Case_Error_User__c.User_ID_who_should_get_email__c`.
- **SOQL/DML:** **One `insert` per attachment inside loops** (DML limit 150 – fine for typical emails). `insertSObject` swallows `DmlException` (failures only debug-logged; a failed Case insert leads to EmailMessage with null ParentId).
- **Risks:** `Integer.valueOf(caseNumber)` overflows for numeric subject tokens > 2,147,483,647 (e.g. phone numbers) → unhandled exception. Error-user lookup throws if the custom setting is missing.
- **Test:** TestEmailServiceToFindMatchingCase.

## SendEmailForMissedCallAlertVC

- **Purpose:** Flow action that sends an HTML email (used for missed-call alerts). (July 2024.)
- **Entry point:** `@InvocableMethod(label='Send Email on missed call', category='Email') getEmailInfoAndSend(List<GettingInputDataForEmail>)`; inputs `emailRecipientAddress`, `emailSubject`, `emailBody`.
- **Uses:** OrgWideEmailAddress with DisplayName `'For missed call'` (optional).
- **Risk:** `Messaging.sendEmail` called **inside loop** – limit of 10 sendEmail calls per transaction; >10 flow interviews batched together will fail.
- **Calling flow:** not present in this source.
- **Test:** SendEmailForMissedCallAlertVCTest.

See also `unsubscribe` (email service) in Unsubscribe.md.
