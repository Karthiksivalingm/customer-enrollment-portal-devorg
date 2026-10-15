# Unsubscribe

Two separate unsubscribe mechanisms exist:
1. **`unsubscribe`** – inbound Email Service (reply with "unsubscribe" in subject).
2. **Unsubscribe Link** (Salesforce Labs unmanaged package by Jessie Rymph, 2021) – screen flow + subflows `jrsl_ul_Unsubscribe_Contacts` / `jrsl_ul_Unsubscribe_Leads`, finish page `jrsl_ul_UnsubscribeFinish` with controller `jrsl_ul_UnsubscribeController`. Flows and page are not in this source folder (only referenced from tests / comments).

---

## unsubscribe

- **Purpose:** Opt out Contacts and Leads whose email equals the sender when subject contains "unsubscribe" (case-insensitive). `Global`, implements `Messaging.InboundEmailHandler`. **API version 12.0.**
- **Entry point:** `handleInboundEmail(InboundEmail, InboundEnvelope)`; always returns `success = true`.
- **Reads/writes:** Contact (`Email = env.fromAddress`, `HasOptedOutOfEmail = false`, LIMIT 100) → `HasOptedOutOfEmail = true`; Lead (same + `IsConverted = false`, LIMIT 100) → `HasOptedOutOfEmail = true`.
- **Risks:** `email.subject.toLowerCase()` NPE when subject is null. Only `QueryException` is caught – a `DmlException` (e.g. validation rule) fails the email. Max 100 records per object. Very old API version (12.0).
- **Tests:** inline `static testMethod` methods inside the class (allowed only because of API 12.0; they have no assertions). Not a separate test class.

## jrsl_ul_UnsubscribeController

- **Purpose:** Sets `displayText` for the unsubscribe confirmation VF page. `with sharing`.
- **Entry point:** constructor; public `displayText`, `booly`.
- **Metadata:** `jrsl_ul_Unsubscribe_Link__mdt` (`jrsl_ul_Send_Confirmation_Email__c`, `Test_Case__c`) filtered by `Test_Case__c = jrsl_ul_TestContext.testCase` (null in production). `'Yes'` → "…You will receive a confirmation email shortly."; otherwise short text; missing record → error text.
- **Test:** jrsl_ul_UnsubscribeControllerTest.

## jrsl_ul_TestContext

- Static `testCase` String used to select test mdt records. No business logic.

## Related tests

| Test | What it verifies |
|---|---|
| jrsl_ul_UnsubscribeContactsTest | Flow `jrsl_ul_Unsubscribe_Contacts` opts out all Contacts with an email (incl. bulk) |
| jrsl_ul_UnsubscribeLeadsTest | Flow `jrsl_ul_Unsubscribe_Leads` opts out Leads |
| jrsl_ul_UnsubscribeLinkTest | One `jrsl_ul_Unsubscribe_Link__mdt` record with MasterLabel `Unsubscribe` exists (org-data dependent) |
| jrsl_ul_UnsubscribeControllerTest | Controller text variants |
