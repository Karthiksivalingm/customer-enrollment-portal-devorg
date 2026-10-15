# CON-005: Asynchronous jobs and governor limits

| Field | Value |
|---|---|
| Status | ⚠ Open |
| Severity | 🟠 Medium |
| Found | 2026-10-13 |
| Related | [TECH-002](../07-Technical/TECH-002_Apex-Lead-Management.md) · [TECH-005](../07-Technical/TECH-005_Apex-Activities-Task-Event.md) · [TECH-009](../07-Technical/TECH-009_ODA-Quoting-Integration.md) |

- `TaskHandler.notifyCTI` makes a `@future` callout on **every** Task insert or update, and `OdieWrapper` makes futures on Lead changes. Task or Lead DML run from a batch or future context will throw an exception.
- `OdieWrapper` makes one callout per Lead in a loop, so bulk Lead updates can exceed 100 callouts.
- `checkTriggerRecursion` is never reset. The second and later 200-record chunks, and owner changes made by workflow field updates, are **not synced to Odie**, and MobilePhone sync is skipped the same way.
- DML or sendEmail inside loops: `ODAPolicyController.updateODAPolicies`, `SendEmailForMissedCallAlertVC`, `roundRobinAssigner`, `OnboardingOwnerAssignmentCtrl`, and `AssignLeadToCadencesBatch` (`Flow.Interview.start` in a loop).

> Several of these classes were refactored in the org before 2026-10-15 ([CR-002](../04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md)). Re-check each item against the current source before acting.
