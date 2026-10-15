# EverquoteFullSandbox: Project Rules

These rules are specific to EverquoteFullSandbox. They add to the shared [AI-Workflow.md](AI-Workflow.md) and [Coding-Standards.md](Coding-Standards.md), which every project in the repo follows and which are never edited here.

## 1. Know the project before acting
- Background: [02-Knowledge-Base/Project-Overview.md](../02-Knowledge-Base/Project-Overview.md). Terms: [KB-002 Glossary](../02-Knowledge-Base/KB-002_Glossary.md).
- Before changing a component, read its TECH document (listed in [DOCUMENT-INDEX.md](../DOCUMENT-INDEX.md)). Before changing automation on any object, read the CON documents in `05-Conflicts/`.
- **Org:** the full-copy sandbox, alias **`EverquotefullSandbox`**, API **68.0**. Run `sf` commands from this `EverquoteFullSandbox/` folder, and retrieve with `--api-version 68.0`, because older versions drop flow and page elements.
- `force-app/` holds the org's own (unmanaged) metadata. Components from installed managed packages, such as `ssot__`, `dfsle__`, `amazonconnect__` and `Gong__`, are deliberately left out. Profiles are limited to the 2 in source.

## 2. Org-specific coding rules
- **Triggers:** one active trigger per object, with its handler: `LeadTrigger` → `LeadHandler`, `TaskTrigger` → `TaskHandler`, `EventTrigger` → `EventHandler`. Many inactive legacy triggers are still in source ([CON-002](../05-Conflicts/CON-002_Multiple-Triggers-Per-Object.md)). Don't reactivate them or add new triggers; extend the active handler.
- **Recursion:** use the existing `checkTriggerRecursion` guard instead of new static flags, and be aware of its reset problem ([CON-005](../05-Conflicts/CON-005_Async-And-Governor-Limit-Risks.md)).
- **No hardcoded Ids or endpoints.** Look up record types, queues and profiles by DeveloperName. Callouts go through Named Credentials ([CON-001](../05-Conflicts/CON-001_Hardcoded-Credentials-And-Secrets.md)).
- **Async context:** Task and Lead DML triggers `@future` callouts (to NotifyCTI and Odie). Don't do Task or Lead DML from batch or future code without handling this.
- **Tests:** create data through `DataFactory`. Don't use `SeeAllData=true`.
- **Declarative:** don't create new Workflow Rules or Process Builders.

## 3. Safety
- Never deploy, delete metadata, or change org data without explicit approval for that specific action. A check-only deploy (`--dry-run`) is fine to propose.
- **Don't add new secrets or personal data to the repo.** That includes tokens, passwords, `.sf/` and `.sfdx/`, the user report spreadsheets, and personal emails or phone numbers. The `Reference-Files/` folders are local only. Existing secrets in the org's metadata are tracked in CON-001.
- **Git:** commit only when asked, and work on a branch named `everquote/feature/REQ-0xx-short-name` (or `everquote/fix/…`, `everquote/docs/…`). Merge to `main` through a pull request.

## 4. Documentation
File everything in the numbered folders as one numbered document per item, taking the next free number from [DOCUMENT-INDEX.md](../DOCUMENT-INDEX.md):

| When you… | Create or update |
|---|---|
| receive a new request | `03-Requirements/REQ-0xx_<Title>.md` |
| change org metadata, configuration or data | `04-Change-Records/CR-0xx_<Title>.md` the same day, with before and after values, deploy Id, verification and rollback |
| hit a conflict or find a risk | `05-Conflicts/CON-0xx_<Title>.md` |
| deploy to another org | `06-Deployment/DEP-0xx_<Title>.md`, using the [pre-deployment](../06-Deployment/Pre-Deployment-Checklist.md) and [post-deployment](../06-Deployment/Post-Deployment-Checklist.md) checklists |
| add or change a class, trigger, flow, field or integration | the matching `07-Technical/TECH-0xx_…` document |
| learn something lasting about the business or org | `02-Knowledge-Base/` |

Then update `DOCUMENT-INDEX.md`.

## 5. Reporting back
Name the files and components you touched, how you tested them, and anything left unverified. Call out deployment impact: dependencies, the test classes to run, and manual pre- or post-deployment steps.
