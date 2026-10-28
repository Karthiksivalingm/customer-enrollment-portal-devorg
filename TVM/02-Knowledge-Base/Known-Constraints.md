# Known Constraints and Open Questions

Verified limitations of the TVM project, the org and the automation, plus questions the evidence cannot yet answer.

## Org and source
| # | Constraint | Evidence / reference |
|---|---|---|
| 1 | Only the Fullsandbox is connected. Production behaviour, data volume and production-only automation are unknown. | [Salesforce-Org-Context.md](Salesforce-Org-Context.md) |
| 2 | Hardcoded credentials in 7 Apex classes and 1 external credential. The files are kept out of Git, so they are not version-controlled. | [CON-002](../2026-10/05-Conflicts/CON-002_Hardcoded-Credentials-In-Org-Apex-And-External-Credential-Source.md) |
| 3 | Components installed by **unmanaged** no-namespace packages ("2 Way Case Automation Solution", GS_Sales_Reports_Dashboards and others) cannot be told apart from TVM-authored metadata. They may be in `force-app`. | [Salesforce-Org-Context.md](Salesforce-Org-Context.md) |
| 4 | Reports (5,834), dashboards (412), most email templates (~1,870), content assets (2,768) and territory models are not retrieved. A folder-level scope decision is needed. | [Metadata-Scope.md](../2026-10/07-Technical/Metadata-Scope.md) |
| 5 | `CustomObject ActionCadence` cannot be retrieved by name (the Metadata API reports it as not found). | [Retrieval-Report.md](../2026-10/07-Technical/Retrieval/Retrieval-Report.md) |
| 6 | Profiles contain permissions only for components retrieved in the same request (`access` batch). | `scripts/retrieve.py` |
| 7 | Some metadata contains user identifiers (usernames in queue members, presence configs, workflow recipients). This is normal for Salesforce metadata, and the repository is private. | — |
| 8 | Flow status in source is the version retrieved. 91 Obsolete and 42 Draft Flows are kept for history. | [Flows inventory](../2026-10/07-Technical/Metadata-Inventory/Flows.md) |

## Code risks seen in source (not reproduced)
These are listed in [Automation-and-Execution-Order.md](Automation-and-Execution-Order.md#6-risks-seen-in-code-not-reproduced-in-the-org):

- Bulk bug in `create_OppProduct_History`.
- SOQL inside loops and hard-coded RecordType Ids in `OpportunityContractFileTrigger`, `ContentVersionTrigger` and `AutoQACaseScheduler`.
- Several objects have multiple triggers with no defined order.
- Overlapping TouchPoint sync paths.

## Automation limits
| # | Limit |
|---|---|
| A1 | Claude Code hooks run only in sessions **started from `TVM/`**. Edits made elsewhere are committed by the next Stop hook or a manual `python scripts/autocommit.py`. |
| A2 | Changes made directly in Salesforce (UI, other users, integrations) are **not detected**. That would need an approved Salesforce-side mechanism: Setup Audit Trail queries for metadata, Field History Tracking or Change Data Capture for records. None is configured by this project. A read-only option is a scheduled `SetupAuditTrail` query compared with `force-app`; it needs approval. |
| A3 | Apex tests and check-only validations run only on request (they use the org). The auto-commit runs local checks only: secrets, XML/JSON, records, documentation. |
| A4 | Business-record changes are documented only when made through the supported workflow with before/after queries. |
| A5 | No repository-wide Git hook is installed. Enabling one affects the other projects and needs approval. |

## Open questions for the TVM owner
1. Which report, dashboard and email-template folders belong to TVM development scope?
2. Approve the permanent fix and credential rotation for CON-002?
3. Are the Inactive TouchPoint triggers intentionally replaced by the `TP_SYNCv2` / `SendAccountToTouchpoint` Flows?
4. Only `ScheduleCaseAssignmentBatch` is scheduled in Fullsandbox (queried 2026-10-14). Should the other schedulable classes (SLA emails, case status, OOO updates, opportunity lost) also run, and do they run in production?
5. What is the business relationship between "TVM" and "Foundation / FNDN" records? This affects routing, record types and the Salesforce-to-Salesforce flows.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created during project setup. |
