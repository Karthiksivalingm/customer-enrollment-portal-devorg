# CON-006: Environment and deployment dependencies

| Field | Value |
|---|---|
| Status | ⚠ Open |
| Severity | 🟠 Medium |
| Found | 2026-10-13 |
| Related | [TECH-019](../07-Technical/TECH-019_Integrations.md) · [Pre-Deployment-Checklist](../06-Deployment/Pre-Deployment-Checklist.md) |

| Issue | Impact |
|---|---|
| Hardcoded Ids in flows: profile `00e1a000000hyVbAAI` (BDR flows); queues `00GVm000000alG9MAM` and `00GVm000001CG3dMAG` (Case Support Rep flow, sandbox-created) | Flows break in production or a refreshed org. Replace them with lookups by DeveloperName. |
| Hardcoded record type and campaign Ids in workflow rules (6 record types, 1 campaign), and in inactive triggers and tests | Fails in any other org |
| `NotifyCTI` picks staging by checking for a `cs` host prefix | Enhanced-domain sandboxes don't match, so they **call the production CTI** |
| Cheat Sheet controllers always call the **staging** host | Production uses staging data |
| `etcd8_RRLeadAssignment` needs a queue named "Unassigned", which isn't among the 103 queues | That round robin silently does nothing |
| Named Credential secrets, Custom Setting values (`RoundRobin__c`, `Email_to_Case_Error_User__c`, `OnboardingSettings__c`) and email service addresses can't be deployed | Must be configured by hand in each target org |
| `OdaReliashieldControllerTests` only passes when that Named Credential exists, and `OpportunityLineItemTriggerTest` uses `SeeAllData=true` with a hardcoded Opp Id | Test failures in other orgs |
| Managed-package components, reports, dashboards and 54 of the 56 profiles aren't in source | Components that depend on them must already exist in the target org |
