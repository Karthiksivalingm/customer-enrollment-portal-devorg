# Known and Possible Conflicts (baseline: 2026-10-13)

These were found by reviewing the metadata in commit `f9c91cf`. Read this before changing automation on Lead, Task, Event, Case or Opportunity. Detailed evidence is in [07-Technical-Documents](../07-Technical-Documents/README.md).

Severity: 🔴 High (security issue, data integrity or likely failure) · 🟠 Medium (behaviour clash or deployment risk) · 🟡 Low (cleanup)

## 1. Security (🔴, act first)
| # | Issue | Where | Action |
|---|---|---|---|
| S1 | Basic-auth credentials stored in plain text in Apex | `NotifyCTI.cls:16`, `LeadCheatsheetController.cls:81`, `OpportunityCheatsheetController.cls:98` | Rotate the credential and move it to a Named Credential. The values are in Git history in the private repo. |
| S2 | Delighted webhook URLs with secret tokens in the path | `workflows/Contact.workflow-meta.xml` lines 115, 126, 137 | Rotate the tokens in Delighted if they're still used. Otherwise delete the outbound messages, which look orphaned. |
| S3 | Seven permission sets grant **Modify All Data**, several under misleading names. The EQ Cross-Functional profile is effectively admin (ModifyMetadata, AuthorApex, ManageUsers, AssignPermissionSets). | [Security-and-Access.md](../07-Technical-Documents/Security-and-Access.md) | Review the assignments and remove the "Temp" permission sets. |
| S4 | Personal data (DOB, phone, health answers) written to debug logs | ODA request builders and callouts | Remove the `System.debug` calls on request bodies. |

## 2. Several triggers on one object (🟠)
Salesforce doesn't guarantee the order in which multiple triggers on the same object run. **7 of the 33 triggers are active.**

| Object | Active | Inactive (still in source) |
|---|---|---|
| Task | `TaskTrigger` | 10 legacy triggers (AggregateCall, ChangeOwnerAfterSpokeDM, TaskCaseFirstActivity, TaskLead, …) |
| Lead | `LeadTrigger` | 8 (ConvertLeadWhenIMHeld, LeadOutcomeUpdated, LeadOwnerUpdated, LifeLeadCreated, ResetLeadWhenLost, UpdateLeadMobilePhone, UpdateReferral, etcd8_LeadTrigger) |
| Event | `EventTrigger` **and** `EventNotifyCTI` (empty body) | 6 |
| Opportunity | `CreateNewOppWhenClose` (whole body commented out) | `OpportunityTrigger`, so **OpportunityTriggerHandler never runs** |
| OpportunityLineItem | `OpportunityLineTrigger` | `OpportunityLineItemTrigger`, which has identical rollup logic |

**Rule:** don't reactivate the inactive triggers. Add logic to the active handler instead. `OpportunityTriggerHandlerTest` expects a follow-up opp, so it will probably fail while `OpportunityTrigger` is inactive.

## 3. The same field written by several automations (🟠)
| Field | Competing automation |
|---|---|
| **Lead.OwnerId** | 5 active workflow rules (Duplicate Queue, Recycle Lost Leads, 4 "Unqualified:" rules) · LeadHandler round robin · `TaskHandler.assignLeadOwnerOnFirstCall` · `EventHandler.handleConvertLead`, which resets the owner on **every** Event update · the 2 BDR Task flows |
| **Case.OwnerId** | "Move to Smart Campaign Queue" workflow rule **and** the `Case_Move_to_Smart_Campaign_Queue` flow (same logic) · the `Case_Update_Case_Owner_to_Account_Support_Rep_1` flow runs after every save and can override both, or set the owner to null when there's no Support Rep |
| **Case.Status** | The EmailMessage workflow rule "Reopen Closed Case on New Email" re-fires the Support Rep flow and reassigns the owner |
| **Account.Core_IO_Win_Date__c** | Two active Opportunity workflow rules (Core IO Win, Mark CORE IO Win) |
| **Opportunity.StageName** | "Update stage to Pending" depends on `next_due_date__c`, which only **inactive** triggers maintain, so the value is stale |

## 4. Old and new versions of the same automation both active (🟠)
- The legacy Process Builder `BDR_Activity_completed_change_lead_owner_to_activity_owner` and its replacement `Task_BDR_Activity_Completed_Change_Lead_Owner` are both active. Both filter on `WhatId` starting with `00Q`, a Lead, which can't be a Task's WhatId, so neither appears to fire.
- The 121 process-flow migration records map 47 processes to 56 flows. Only one of those flows is in source. Eight sources were migrated to two or three flows each, which risks **duplicate active flows** in the org.
- 34 workflow rules carry a `failedMigrationToolVersion` marker, meaning the Migrate to Flow tool failed on them.

## 5. Asynchronous jobs and governor limits (🟠)
- `TaskHandler.notifyCTI` makes a `@future` callout on **every** Task insert or update, and `OdieWrapper` makes futures on Lead changes. Task or Lead DML run from a batch or future context will throw an exception.
- `OdieWrapper` makes one callout per Lead in a loop, so bulk Lead updates can exceed 100 callouts.
- `checkTriggerRecursion` is never reset. The second and later 200-record chunks, and owner changes made by workflow field updates, are **not synced to Odie**, and MobilePhone sync is skipped the same way.
- DML or sendEmail inside loops: `ODAPolicyController.updateODAPolicies`, `SendEmailForMissedCallAlertVC`, `roundRobinAssigner`, `OnboardingOwnerAssignmentCtrl`, and `AssignLeadToCadencesBatch` (`Flow.Interview.start` in a loop).

## 6. Environment and deployment (🟠)
| Issue | Impact |
|---|---|
| Hardcoded Ids in flows: profile `00e1a000000hyVbAAI` (BDR flows); queues `00GVm000000alG9MAM` and `00GVm000001CG3dMAG` (Case Support Rep flow, sandbox-created) | Flows break in production or a refreshed org. Replace them with lookups by DeveloperName. |
| Hardcoded record type and campaign Ids in workflow rules (6 record types, 1 campaign), and in inactive triggers and tests | Fails in any other org |
| `NotifyCTI` picks staging by checking for a `cs` host prefix | Enhanced-domain sandboxes don't match, so they **call the production CTI** |
| Cheat Sheet controllers always call the **staging** host | Production uses staging data |
| `etcd8_RRLeadAssignment` needs a queue named "Unassigned", which isn't among the 103 queues | That round robin silently does nothing |
| Named Credentials (`Odie_API_Credential`, `omni_commerce`, `reliashield_comparison_pdf`), Remote Site Settings for 3 `adh8.com` hosts, Custom Settings (`RoundRobin__c`, `Email_to_Case_Error_User__c`, `OnboardingSettings__c`) and email services aren't in the repo | Must be configured by hand in each target org |
| `OdaReliashieldControllerTests` only passes when that Named Credential exists, and `OpportunityLineItemTriggerTest` uses `SeeAllData=true` with a hardcoded Opp Id | Test failures in other orgs |
| `manifest/package.xml` covers only code (classes, triggers, pages, LWC, Aura, static resources) | Flows, workflows, permission sets and queues need explicit manifests |
| 55 migrated flows, Visualforce pages, LWC, Aura and object/field metadata exist only in the org | The repo isn't a complete backup of the org |

## 7. Code defects likely to cause runtime errors (🟡/🟠)
- `AutoPopulateContactOnVoiceCall`: `FromPhoneNumber.substring(2)` has no null check.
- `AssignLeadToCadencesBatch` L26 reads `carrierList[0]` before checking the list is non-empty.
- `EmailServiceToFindMatchingCase`: `Integer.valueOf` overflows on long numbers in the subject. `unsubscribe` throws a null error on an empty subject.
- `OpportunityCheatsheetController:154` has a null-check that never works.
- `ODARequestCallout.get()` discards its query string and always sends POST.
- ODA builders throw a null error when `Gender__c`, `Major_Condition_Past_Year__c` or `Date_of_Birth__c` is blank.
- `IMHeld__c` is still set, but its auto-convert trigger is inactive, so leads are no longer auto-converted.

## 8. Cleanup backlog (🟡)
- 26 inactive triggers, 81 inactive workflow rules, several active rules with no actions, `LeadTriggerHandler` (unused, untested), `Rider`, and duplicate cheat-sheet callout code.
- There are four separate round-robin mechanisms. Consolidate them.
- Classes with no test: `CrossUpsellInfoController`, `LeadTriggerHandler`, `Rider`. Seven test classes have no asserts.
