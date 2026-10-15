# REQ-002: Move the project into the shared sfdcut/SFDC repository

| Field | Value |
|---|---|
| Date received | 2026-10-15 |
| Status | ✅ Done |
| Related | [CR-002](../04-Change-Records/CR-002_Move-To-SFDC-Repo-And-Full-Retrieve.md) · [CON-001](../05-Conflicts/CON-001_Hardcoded-Credentials-And-Secrets.md) |

## Business need
Every client project lives in one shared repository, `sfdcut/SFDC`, with one folder per project (FD, Goodr, MLB, TVM). EverquoteFullSandbox was in a separate personal repository and has to move into that structure.

## Scope
- Move the project, with its Git history, into `sfdcut/SFDC/EverquoteFullSandbox/` through an import branch and pull request, as was done for Goodr (`goodr/import`, PR #1).
- Restructure the documentation to the house standard: numbered folders at the project root, `KB-`, `REQ-`, `CR-`, `CON-`, `DEP-` and `TECH-` documents, a `DOCUMENT-INDEX.md`, and the shared `AI-Workflow.md` and `Coding-Standards.md`.
- Compare the metadata types with the other projects, and retrieve the ones missing from EverquoteFullSandbox out of the org.

## Decisions
- Secrets in the metadata are pushed as-is (owner's decision, 2026-10-15). See CON-001.
- The pull request is merged straight away by the person doing the import.
- Managed-package components, reports and dashboards are excluded from the retrieve. Only the 2 existing profiles are kept.

## Acceptance criteria
- [x] `EverquoteFullSandbox/` is on `main` of sfdcut/SFDC alongside FD, Goodr, MLB and TVM.
- [x] The documentation follows the house layout and naming.
- [x] Objects, fields, layouts, flows, Lightning pages, LWC, Aura, Visualforce and the other missing types are in `force-app/`.
