# Arizona Working Instructions

These are the permanent rules for all Arizona work, by people or by Claude. They are self-contained: no other project folder is needed.
Read this file, [Salesforce-Safety-Rules.md](Salesforce-Safety-Rules.md), [Documentation-Rules.md](Documentation-Rules.md) and
[Git-Rules.md](Git-Rules.md) at the start of every task, plus the Knowledge Base pages relevant to the task.

## 1. Project boundaries

| Item | Value |
|---|---|
| Project folder | `Arizona/` inside `https://github.com/sfdcut/SFDC.git` |
| Salesforce org | Alias `Arizona`: Azlionhearts sandbox, Org ID `00DWH000005wW9V2AU` (see [Salesforce-Safety-Rules.md](Salesforce-Safety-Rules.md)) |
| Production | Alias `PROD` (Arizona Production) is **never** used from this project: no retrieval, configuration, data change or deployment |
| Configuration | [`config/arizona-project.json`](../config/arizona-project.json): org identity and metadata scope, used by the scripts |
| Tooling | Node.js scripts in [`scripts/`](../scripts/README.md) (Python is not installed on the setup machine) |

- Everything Arizona-specific lives inside `Arizona/`: source, documents, configuration and scripts.
- Other project folders (`FD/`, `Goodr/`, `MLB/`, `TVM/` and any later project) are read-only. They may be used only as structural
  references. Never copy their business documentation or metadata into Arizona.
- Never modify, stage or commit repository-root files or the untracked repository-root `.sf/` folder.
- Run Salesforce CLI commands from `Arizona/` so the CLI uses `Arizona/sfdx-project.json`.

## 2. The seven documentation folders

| Folder | Responsibility |
|---|---|
| `01-Instructions/` | Permanent rules: these instructions, Salesforce safety, documentation and Git rules |
| `02-Knowledge-Base/` | Evidence-based overview: org context, business processes, data model, architecture, automation, integrations, security, constraints |
| `03-Requirements/` | One dated record per requirement, change request, enhancement or defect (`REQ`): acceptance criteria, dependencies, status |
| `04-Change-Records/` | One dated record per actual, explicitly authorized business-record or configuration-data change, with verified before/after values (`CR`) |
| `05-Conflicts/` | One dated record per error, conflicting requirement, metadata difference or failed operation, from evidence to verified resolution (`CF`) |
| `06-Deployment/` | Standing procedures and checklists, plus one dated record per validation or deployment (`DEP`) and the deployment history |
| `07-Technical-Documents/` | Technical reference per component area, metadata inventory, retrieval reports and the component Change History |

Full routing rules: [Documentation-Rules.md](Documentation-Rules.md).

## 3. Standard workflow for a change

1. **Read** these instructions and the relevant Knowledge Base pages.
2. **Record the request:** `node scripts/new-doc.js REQ "<short title>"`. Fill in the original request, objective, acceptance criteria,
   scope and open questions. Never invent ticket IDs or approvals.
3. **Verify the org:** `node scripts/verify-org.js`. Stop if it fails.
4. **Retrieve the current version** of every component you will touch (after checking `git status` for local work):
   `sf project retrieve start --metadata <Type>:<Name> --target-org Arizona`. Never edit a stale local copy.
5. **Analyse impact** with the [Metadata Inventory](../07-Technical-Documents/Metadata-Inventory.md) and the source: what else reads or
   writes the same objects and fields ([Automation-and-Processes.md](../02-Knowledge-Base/Automation-and-Processes.md)).
   Write the approach into the REQ record and get the user's agreement before building.
6. **Make the minimal change** in `force-app/main/default/` (Salesforce DX source format). Do not refactor beyond the request.
7. **Validate** without changing the org:
   `sf project deploy validate --source-dir <paths> --test-level RunSpecifiedTests --tests <TestClass> --target-org Arizona`.
   Record the validation ID and results in the REQ (and DEP). Add a CF record for any failure.
8. **Deploy only after explicit approval** of that exact operation and target, recorded in a DEP record.
9. **Verify** the result in the org and record the actual evidence.
10. **Document** in the same task: the component's technical document, a dated row in
    [Change-History.md](../07-Technical-Documents/Change-History.md), the Knowledge Base if behaviour changed, and CR / CF / DEP records
    where they apply.
11. **Commit and push** Arizona paths only, following [Git-Rules.md](Git-Rules.md).

## 4. Salesforce DX conventions

- Source format only, under `force-app/main/default/<type folder>/`. API version 68.0 (`sfdx-project.json`).
- Never create placeholder or empty components to make the structure look complete.
- `manifest/package.xml` is the baseline scope, rebuilt by `node scripts/list-org-metadata.js` then `node scripts/build-manifest.js`.
  `manifest/batches/*.xml` split it for retrieval. Release manifests go in `manifest/releases/DEP-NNN-package.xml`.
  Scope and exclusions: [Metadata-Scope.md](../07-Technical-Documents/Metadata-Scope.md).
- Managed-package and Data Cloud system components are out of scope and excluded by `.forceignore`.
- Apex: bulk-safe (200 records), no SOQL or DML inside loops, declare a sharing mode, enforce CRUD/FLS where user data is exposed,
  tests that assert specific outcomes.

## 5. Secrets

- Never put passwords, tokens, keys, session IDs, auth URLs or unnecessary personal data in source, documents, commit messages or chat.
- Run `node scripts/secret-scan.js` before every commit. Files from the org that contain hardcoded credentials are listed in
  `.gitignore` and documented in a CF record (without the value). The value must be rotated in the org by an administrator.
- If a secret is ever committed, stop and tell the user: it must be rotated. Do not rewrite shared history to hide it.

## 6. Failure handling

| Situation | What to do |
|---|---|
| Org verification fails (wrong ID, not a sandbox, expired auth) | Stop all Salesforce work and report. The user re-authenticates: `sf org login web --alias Arizona --instance-url https://test.salesforce.com`. |
| Retrieval batch fails or is incomplete | Record a CF, retry only the failed batch, record the outcome in the retrieval report. |
| Validation or test failure | Do not deploy. Record a CF with the sanitized error. Fix, re-validate, record the outcome. |
| Push fails (auth, network, branch protection) | The commit stays local. Report the actual error; never use another person's credentials or bypass protection. |

## 7. Decisions log

| Date | Decision |
|---|---|
| 2026-10-15 | Arizona set up as an independent project in `Arizona/`, using the TVM structure as the reference. Alias `Arizona` (00DWH000005wW9V2AU) is the only org. |
| 2026-10-15 | Baseline scope: unmanaged code, data model, automation, security, integration, reports and Experience sites; excluding profiles, managed packages, Data Cloud system objects and record data. |
| 2026-10-15 | Tooling in Node.js (Python unavailable). No automatic commit hooks yet; commits are made manually per [Git-Rules.md](Git-Rules.md). |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Instructions created with the Arizona setup. |
