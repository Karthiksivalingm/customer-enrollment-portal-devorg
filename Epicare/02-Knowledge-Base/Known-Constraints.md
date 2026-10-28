# Known Constraints and Open Questions

## Org and source
| # | Constraint | Reference |
|---|---|---|
| 1 | Only the UTDEV sandbox is connected. `PROD` is never used, so production state is unknown. | [Salesforce-Org-Context.md](Salesforce-Org-Context.md) |
| 2 | The NIPR credential is stored in custom labels. The labels file is kept out of Git, so the 6 custom labels are not version-controlled. | [CON-002](../2026-10/05-Conflicts/CON-002_NIPR-Credential-Stored-In-Custom-Labels.md) |
| 3 | 27 of 909 named components were not returned: 24 Metadata API "load failed" errors (sample reports and dashboard, `CPQIntegrationUserApp`) and pseudo-folders. | [CON-001](../2026-10/05-Conflicts/CON-001_Metadata-API-Failed-To-Return-Sample-Reports-Dashboard-And-A-Connected.md), [Retrieval-Report.md](../2026-10/07-Technical/Retrieval/Retrieval-Report.md) |
| 4 | Reports and dashboards in private folders cannot be retrieved. Reports from the two unmanaged report packs cannot be told apart from Epicare ones. | [Metadata-Scope.md](../2026-10/07-Technical/Metadata-Scope.md) |
| 5 | Omni-Channel, entitlements, territories and sharing sets are not enabled in this org. | [Salesforce-Org-Context.md](Salesforce-Org-Context.md) |
| 6 | Metadata contains user identifiers in places such as role and group membership and permission set labels. The repository is private. | — |

## Code risks seen in source (not reproduced)
- `AppointmentStatusChangedTrigger` reads a parent field from `Trigger.new`, which will be null.
- `AppointmentTrigger` is active but its body is entirely commented out.
- Contact creation may register NIPR targets twice: once from the trigger, once from the NAIC record created by a Flow.
- Commission_Record has 5 triggers with no defined order, and the payment-approval Flow re-fires them.
- NIPR callouts swallow errors (`System.debug` only).
- 7 classes have no test referencing them: `CommissionSettings`, `ContactInsuranceHandler`, `ContactTriggerHandler`, `NiprNPNFutureCallout`,
  `ReconciliationScheduler`, `RenewalScheduleTriggerHandler`, `TriggerHandler`.
- Remote site `prodpdp1` points to a NIPR beta host.

## Automation limits (this repository)
| # | Limit |
|---|---|
| A1 | Claude Code hooks run only in sessions started from `Epicare/`. The end-of-turn hook validates. Commits and pushes happen on request. |
| A2 | Changes made directly in Salesforce are not detected. A Salesforce-side mechanism, such as Setup Audit Trail or Field History, needs approval. |
| A3 | Apex tests and validations run only on request. |

## Open questions for the Epicare owner
1. Approve moving the NIPR credential to a Named Credential, and rotating it (CON-002)?
2. Are the 8 paused scheduled jobs intentionally paused, and do they run in production?
3. `Data_Retention_Rule__mdt` is in Test_Mode and the retention job is paused. When is deletion meant to go live?
4. Are the external credentials `AMS` and `Go_AMS` still needed? Code uses only `SF_Event_OAuth`.
5. Should the standard sample report and dashboard folders stay in scope?

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created during setup. |
