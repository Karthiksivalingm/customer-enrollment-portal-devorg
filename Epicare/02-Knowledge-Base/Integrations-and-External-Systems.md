# Integrations and External Systems

Built from the retrieved source (2026-10-15). No credential values are recorded. INFERENCE marks interpretation.

## 1. GO AMS / Supabase: event-driven, outbound
| Item | Detail |
|---|---|
| Endpoint | Named credential `EventAPI` (Secured Endpoint) → a Supabase project host. External credential `SF_Event_OAuth` (custom protocol) |
| Other credentials | External credentials `AMS` (OAuth, same host) and `Go_AMS` (JWT with a signing certificate). **Not referenced by code** |
| Remote site | `GOAMS` (same host) |
| Calls | `callout:EventAPI` paths `/sf-event-agent-created`, `/sf-event-*` (agent deactivated, appointment status, commission paid, upline import completed, license alert), `/sf-read-commissions` |
| Auth flow | Each call first POSTs to `/oauth-token`, with client id and secret from `{!$Credential.SF_Event_OAuth.*}` merge fields. The call itself then uses Bearer auth. Secrets stay in the org's credential store |
| Classes | `AgentCreatedHelper`, `AgentDeactivatedHelper`, `AppointmentStatusChangedHelper`, `CommissionPaidHelper`, `UplineImportCompleteHelper`, `LicenseAlertHelper` (Queueable with callouts). `CommissionReconciliationEngine` reads commissions; it updates `Commission_Record__c` and inserts `Security_Incident__c` |
| Invocation | Record trigger → platform event → subscriber → Queueable ([Automation](Automation-and-Execution-Order.md#3-event-driven-integration-chain)) |
| Errors | `GoAMSRetryUtil`: up to 3 retries on 5xx or timeout, delayed re-enqueue, capped at 10 minutes. 4xx responses are dead-lettered to `Error_Log__c` |
| Inbound | Events such as `Enrollment_Approved__e`, `Appointment_Requested__e`, `EPA_Signed__e` and `Onboarding_Step__e` are subscribed in Salesforce. INFERENCE: GO AMS / the agent portal publishes them through the API, using the integration profiles and `GoAMS_Event_Integration` / `Event_Subscriber_Run_As` |
| External IDs | `GO_AMS_Account_Id`, `Go_Epic_*`, `Supabase_User_Id` on Contact; `Supabase_Account_Id` on Account |

## 2. NIPR (National Insurance Producer Registry): licensing data
| Item | Detail |
|---|---|
| Endpoints | Custom labels `NPN_uRL`, `SSN_URL`, `Targetsurl`, `pdb_alerts_Url`. Remote sites: production `pdb-xml-reports.api.nipr.com`, `pdb-alerts-industry-services.api.nipr.com`; beta hosts as well. **`prodpdp1` points to the beta host despite its name** |
| Auth | Basic auth built from custom labels `Nipr_username` / `Nipr_password`. **Credential stored in labels**: [CON-002](../2026-10/05-Conflicts/CON-002_NIPR-Credential-Stored-In-Custom-Labels.md) |
| Functions | NPN lookup and SSN lookup: Aura `NPN`, `SearchAccountNPN`; LWC `ssnSearchButtona`; invocable `NIPRforFlow` used by the Flow `Account_Agent_Onboarding`. Adding and removing PDB alert "targets": Account, Contact and `NAICProducerCode__c` triggers. Scheduled PDB alerts and NPN refresh: `NiprpDbalertsQueueable`, `ScheduledAccountNpnUpdate`, `ScheduledContactNpnUpdate`, `NIPRStaleCheckScheduler` |
| Objects written | Contact, Account, `DOI__c`, `LOA__c` |
| Errors | try/catch with `System.debug` only. No `Error_Log__c`. INFERENCE: failures are silent |

## 3. Other
- **No inbound Apex endpoints:** no `@RestResource`, SOAP web service or email-service handler.
- **Connected apps:** `CPQIntegrationUserApp` could not be retrieved ([CON-001](../2026-10/05-Conflicts/CON-001_Metadata-API-Failed-To-Return-Sample-Reports-Dashboard-And-A-Connected.md)).
- **Packages:** Sales Insights (`OIQ`) and Salesforce Connected Apps. No third-party integration packages.

## Risks (INFERENCE)
- NIPR credentials in custom labels (CON-002). NIPR failures are not logged.
- `prodpdp1` remote site naming vs host.
- Possible double NIPR target registration on Contact create ([Automation](Automation-and-Execution-Order.md)).
- `AMS` and `Go_AMS` external credentials are configured but unused.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from analysis of the baseline retrieval. |
