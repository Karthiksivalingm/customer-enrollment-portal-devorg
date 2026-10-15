# Epicare Working Instructions

These are the permanent rules for all Epicare work, by people or by Claude. They are self-contained: no other project folder is needed.

## 1. Project boundaries

| Item | Value |
|---|---|
| Project folder | `Epicare/` inside `https://github.com/sfdcut/SFDC.git` |
| Working branch | `main` (merged to `main` only through a reviewed pull request) |
| Salesforce org | Alias `UTDEV`: Epicare Insurance, Org ID `00DWB000008ALkv2AG`, sandbox |
| Configuration | [`config/project.json`](../config/project.json), the single source of truth for scripts |

- Everything Epicare-specific lives inside `Epicare/`: source, documents, configuration, scripts and Claude Code hooks.
- Never modify, rename, reformat, stage or commit files outside `Epicare/`, including repository-root files, shared scripts, shared hooks and
  repository-wide Git configuration, without the user's explicit approval.
- Start Claude Code from `Epicare/` so `Epicare/CLAUDE.md` and `Epicare/.claude/settings.json` (the hooks) load.

## 2. The seven documentation folders

| Folder | Responsibility |
|---|---|
| `01-Instructions/` | Permanent rules: these instructions, safety, documentation and Git automation rules |
| `02-Knowledge-Base/` | Verified overview of Epicare: purpose, org context, data model, architecture, automation, integrations, security, constraints |
| `03-Requirements/` | One dated record per requirement, task, enhancement, defect or change request (`REQ`) |
| `04-Change-Records/` | One dated record per actual business-record or configuration-data change, with verified before/after values (`CR`) |
| `05-Conflicts/` | One dated record per error, conflict or unexpected behaviour, from evidence to verified resolution (`CF`) |
| `06-Deployment/` | Standing procedures and checklists, plus one dated record per validation or release (`DEP`) |
| `07-Technical-Documents/` | Topic documents per component area, generated metadata inventories and the component Change History |

Full routing rules: [Documentation-Rules.md](Documentation-Rules.md).

## 3. Standard workflow for a change

1. **Record the request.** `python scripts/new_doc.py REQ "<short title>"`. Fill in the original request, objective, acceptance criteria,
   scope and open questions. Never invent ticket IDs or approvals.
2. **Verify the org.** `python scripts/verify_org.py`. Stop if it fails.
3. **Retrieve the current version** of every component you will touch:
   `python scripts/sf_safe.py project retrieve start --metadata <Type>:<Name>`. Never edit a stale local copy.
4. **Analyse impact** using `07-Technical-Documents/Metadata-Inventory/` and the source: what else reads or writes the same objects and fields,
   and the order of execution ([Automation-and-Execution-Order.md](../02-Knowledge-Base/Automation-and-Execution-Order.md)).
   Write the approach into the REQ record and get the user's agreement before building.
5. **Make the minimal change** in `force-app/main/default/` (Salesforce DX source format). Do not refactor beyond the request.
6. **Validate** without changing the org: `python scripts/sf_safe.py project deploy validate --source-dir <paths> --test-level RunSpecifiedTests --tests <TestClass>`.
   Record the validation ID and results in the REQ (and DEP if one exists). Add a CF record for any failure.
7. **Deploy only after explicit approval** of that exact operation and target, recorded in a DEP record:
   `python scripts/sf_safe.py --approved DEP-NNN project deploy start ...`. See [Salesforce-Safety-Rules.md](Salesforce-Safety-Rules.md).
8. **Verify** the result in the org and record the evidence.
9. **Document**: the component's `07-Technical-Documents/` document, a dated row in `07-Technical-Documents/Change-History.md`, the Knowledge Base if
   behaviour or architecture changed, and CR / CF / DEP records where they apply.
10. **Finish the turn.** The Stop hook validates (no commit). When the user asks to publish, run `python scripts/autocommit.py -m "<subject>"`: Epicare-only commit, normal push to `main`.

## 4. Salesforce DX conventions

- Source format only, under `force-app/main/default/<type folder>/`. API version 68.0 (`sfdx-project.json`); older API versions drop
  elements from Flows and pages.
- One component per file set as the CLI writes it (`.cls` + `.cls-meta.xml`, `.flow-meta.xml`, `objects/<Object>/fields/...`).
- Never create placeholder or empty components to make the structure look complete.
- `manifest/package.xml` is the baseline scope, rebuilt with `python scripts/build_manifest.py`. Release manifests go in
  `manifest/releases/DEP-NNN-package.xml`. See [Metadata-Scope.md](../07-Technical-Documents/Metadata-Scope.md).
- Managed-package components are out of scope and excluded by `.forceignore`.
- Apex: bulk-safe (200 records), no SOQL or DML inside loops, declare a sharing mode, enforce CRUD/FLS where user data is exposed,
  and tests that assert specific outcomes (positive, negative, bulk, restricted user).

## 5. Validation, tests and security

- Run the Apex tests related to every changed class or trigger, plus tests of other automation on the same objects. Record the run ID,
  results and coverage.
- `scripts/autocommit.py` runs the secret scan, JSON/XML well-formedness checks, dated-record checks and the documentation check
  before anything is staged.
- Never put passwords, tokens, keys, session IDs, auth URLs or personal data in source, documents, commit messages or chat.
- Credential-bearing records and files found in org source are listed in `config/project.json` (`secretRecords`) and
  `config/secret-files.json`; they are excluded from Git.

## 6. Failure handling and recovery

| Situation | What to do |
|---|---|
| Org verification fails (wrong ID, not a sandbox, expired auth) | Stop all Salesforce work. Report it. The user re-authenticates: `sf org login web --alias UTDEV --instance-url https://test.salesforce.com`. |
| Validation or test failure | Do not deploy. Record a CF document with the sanitized error. Fix, re-validate, and record the outcome. |
| Auto-commit blocked (secrets, docs, invalid XML) | Fix what the message lists. Nothing was staged. |
| Auto-commit stopped (wrong branch, staged files outside Epicare, merge in progress) | Report to the user. Do not work around it. |
| Push failed (auth, network, branch protection) | The commit stays local. The next run of `scripts/autocommit.py` pushes it. Report the failure; never use another person's credentials. |
| A deployment caused a problem | Follow [Rollback-Procedures.md](../06-Deployment/Rollback-Procedures.md) only with approval; record CF and DEP updates. |

## 7. Decisions log

| Date | Decision |
|---|---|
| 2026-10-15 | Epicare set up as an independent project in `Epicare/`. Org alias `UTDEV` (00DWB000008ALkv2AG, Epicare Insurance sandbox) is the only org. `PROD` is never used. |
| 2026-10-15 | Scope: all unmanaged metadata (code, automation, data model, UI, security, integrations) plus reports, dashboards and email templates in public folders. |
| 2026-10-15 | Project content is pushed to `main` (user decision). Commits and pushes happen on request; the Stop hook only validates. |
