# GO AMS / Supabase and NIPR integrations

Component-level summary. The narrative is in [Integrations-and-External-Systems.md](../../../02-Knowledge-Base/Integrations-and-External-Systems.md).

| Integration | Components | Credentials (no values) | Status |
|---|---|---|---|
| GO AMS / Supabase (outbound events) | Named credential `EventAPI`; external credential `SF_Event_OAuth`; Queueable helpers `AgentCreatedHelper`, `AgentDeactivatedHelper`, `AppointmentStatusChangedHelper`, `CommissionPaidHelper`, `UplineImportCompleteHelper`, `LicenseAlertHelper`; `CommissionReconciliationEngine`; `GoAMSRetryUtil` | Client id and secret via `$Credential.SF_Event_OAuth` merge fields (org store) | Active |
| GO AMS (inbound events) | Platform events `Enrollment_Approved__e`, `Appointment_Requested__e`, `EPA_Signed__e`, `Onboarding_Step__e`; integration profiles and permission sets | Integration user | Active (subscribers) |
| NIPR PDB | `NiprNPNsearch`, `NiprSSNsearch`, `NiprNPNFutureCallout`, `NIPRforFlow`, `NiprSSNFlowAction`, `NiprSSNsearchFlowInvoker`, `NIPRAddTargets*`, `NIPRRemoveTargets*`, `NiprpDbalertsQueueable`, `ScheduledAccountNpnUpdate`, `ScheduledContactNpnUpdate`; Aura `NPN`, `SearchAccountNPN`; LWC `ssnSearchButtona`; 8 remote sites | Basic auth from custom labels ([CON-002](../../05-Conflicts/CON-002_NIPR-Credential-Stored-In-Custom-Labels.md)) | Active |
| Unused | External credentials `AMS` (OAuth) and `Go_AMS` (JWT) | — | Configured, not referenced by code |

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-15 | Created from the baseline retrieval | CON-002 |
