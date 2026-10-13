# Instructions for Claude

Rules Claude follows when working in the **EverquoteFullSandbox** Salesforce DX project. The project root `CLAUDE.md` imports this file, so Claude reads it automatically at the start of every session.

## 1. Know the project before acting

- Read [docs/02-Knowledge-Base/Project-Overview.md](../02-Knowledge-Base/Project-Overview.md) for context.
- Before changing a component, read its entry in [docs/07-Technical-Documents](../07-Technical-Documents/README.md). For any automation on an object, also check [docs/05-Conflicts/Known-Conflicts.md](../05-Conflicts/Known-Conflicts.md).
- `force-app/main/default` is the only package directory. The source API version is **64.0**. The default org alias is **`EverquotefullSandbox`**.
- There is no object or field metadata in the repo yet. Before relying on a field, confirm it exists in the org: retrieve it, or ask.

## 2. Salesforce coding standards

- **Triggers:** one active trigger per object, with logic in a handler class (for example `LeadTrigger` → `LeadHandler`, `TaskTrigger` → `TaskHandler`, `EventTrigger` → `EventHandler`). Many inactive legacy triggers are still in source (see Known-Conflicts). Don't reactivate them or add new triggers; extend the active handler.
- **Bulkify everything:** no SOQL or DML inside loops. Use maps and sets keyed by Id.
- **Recursion:** use the existing guard (`checkTriggerRecursion`, `TriggerHandler` bypass) instead of creating new static flags.
- **Hardcoded values:** no hardcoded record Ids, user Ids, queue Ids or endpoints. Use Custom Metadata, Custom Settings, Custom Labels, Named Credentials, or a query by DeveloperName.
- **Callouts:** go through a Named Credential, set a timeout, handle non-200 responses, and have an `HttpCalloutMock` in tests.
- **Tests:** every new or changed class needs a test with meaningful asserts and at least 85% coverage (the org minimum is 75%). Create data through `DataFactory`. Don't use `SeeAllData=true`.
- **Declarative first:** prefer record-triggered flows over Apex where the logic is simple. Never create new Workflow Rules or Process Builders, because Salesforce has retired them.
- **Formatting:** follow the repo's Prettier and ESLint config (`npm run prettier`, `npm run lint`).

## 3. Safety rules

- **Deploying:** never deploy or delete metadata in any org without explicit approval for that specific deployment. A validate-only deploy (`--dry-run`) is fine to propose.
- **Data operations:** never run anonymous Apex or data loads that change data in the org without approval.
- **Secrets and personal data:** never commit them. That includes tokens, passwords, `.sf/` and `.sfdx/` auth files, the user report spreadsheets, and personal emails or phone numbers.
- **Git:** commit only when asked, never force-push to `main`, and work on a feature branch named `feature/<ticket>-<short-name>`.

## 4. Keep the documentation current

These updates are part of every task, not optional extras.

| When you… | Update |
|---|---|
| receive a new task or requirement | add a row to `docs/03-Requirements/Requirements-Log.md` and create `REQ-xxxx.md` from the template |
| change metadata or data | add a change record in `docs/04-Change-Records/` with before and after values |
| hit or fix a conflict | log it in `docs/05-Conflicts/Conflict-Log.md` |
| deploy | fill a deployment log in `docs/06-Deployment/Deployment-Logs/` |
| add or modify a class, trigger, flow, field or integration | update the matching file in `docs/07-Technical-Documents/` |
| learn something lasting about the business or org | update `docs/02-Knowledge-Base/` |

Name files by ID and date, for example `REQ-0007-lead-round-robin-fix.md`, `CR-0012-2026-10-14.md` or `DEP-2026-10-14-01.md`, so they sort and link easily.

## 5. How to report back

- Name the files and components you touched, how you tested them, and anything left unverified.
- Call out deployment impact: dependencies, the test classes to run, and manual pre- or post-deployment steps.
