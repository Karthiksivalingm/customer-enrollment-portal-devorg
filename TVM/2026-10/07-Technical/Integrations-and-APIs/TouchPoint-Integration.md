# TouchPoint (Quickbase) Integration

| Field | Value |
|---|---|
| **Type** | Outbound REST callouts (Apex @future and Flow invocable actions) |
| **Direction** | Salesforce → TouchPoint CRM, hosted on Quickbase (`api.quickbase.com`) |
| **Status** | Mixed. See the table below |
| **Open issue** | [CON-002](../../05-Conflicts/CON-002_Hardcoded-Credentials-In-Org-Apex-And-External-Credential-Source.md): hardcoded credentials. The callout classes are kept out of Git |

## Components
| Component | Kind | Invoked by | Status |
|---|---|---|---|
| `TouchPointMakeAccountPOSTCallout`, `TouchPointMakeCPPOSTCallout` | Apex @future(callout) | `TouchPointAccountUpdateTrigger` (Account after update) | Trigger **Inactive**. CP class body is commented out |
| `TouchPointMakeContactPOSTCallout` | Apex @future | `TouchPointContactUpdateTrigger` | Trigger **Inactive** |
| `TouchPointMakeAutoGroupPOSTCallout` | Apex @future | `TouchPointAutoGroupUpdateTrigger` | Trigger **Inactive** |
| `TouchPointMakeBudgetPOSTCallout` | Apex @future | `TouchPointBudgetUpdateTrigger` (Monthly_Budget__c after insert/update, only when `Sent_to_TP__c` is null) | **Active** |
| `TouchpointAPI` / `TouchpointAPIInvocable` | Apex + invocable action | Flow `SendAccountToTouchpoint` (Active) | Active |
| `TouchpointAGAPI` / `TouchpointAGAPIInvocable` | Apex + invocable action | Flows (see the Flows inventory) | Active |
| `TouchpointCallOut` / `TouchpointCallOutInvocable` | Legacy Quickbase XML API; URL built from `TouchPoint_Callout__mdt` | Flow `TP_SYNCv2` (Active, Account after-save) | Active |
| External Service `SFtoTPAccount` | External service registration | Flow `Account_TP_Staging_Push` | Flow is **Draft** |
| Named credential `TP` + external credential `TPAuth` | Quickbase endpoint with header auth | **Not used by Apex** | Defined |

## Payload and logging
- **Payloads:** JSON built in Apex from Account (including `Client_Team__c`, user fields), Contact, `Auto_Group__c` and `Monthly_Budget__c` fields.
  The external record key is `Account.Touchpoint_Master_ID__c`.
- **Logging:** each callout class inserts an `Event_Log__c` record:
  - Request: `Message_Type__c`, `Request_Object__c`, `Request_Body__c`.
  - Response: `Response_Status_Code__c`, `Response_Message__c`, `Response_Body__c`.
  - `TouchpointCallOut` only writes `System.debug`.
- **Error handling:** no try/catch in the callout classes. A failure in an @future method is lost except for the platform's async job log.

## Authentication (no values recorded)
- Apex classes use a literal Quickbase user token in the `Authorization` header (CON-002).
- `TouchpointCallOut` passes `apptoken` and `usertoken` from `TouchPoint_Callout__mdt` in the URL query string. Those records are org-only and excluded from source.
- Recommended target design (pending approval): `callout:TP` with `TPAuth`. No tokens in code or custom metadata.

## Monitoring
`Event_Log__c` records; Apex Jobs (Setup) for @future failures.

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-14 | Created from the baseline retrieval | CON-002 |
