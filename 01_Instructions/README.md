# How this repository is organised

| Folder | What goes in it |
|---|---|
| `01_Instructions/` | Rules for how work is done: process, approvals, data, security, git. Claude reads these through `CLAUDE.md` |
| `02_Knowledge_Base/` | Project background: business context, orgs, objects, the mapping, cluster model, client decisions, glossary |
| `03_Requirements/` | Every task or request received, with ID, date, status and where the output is |
| `04_Change_Records/` | What changed, before and after: change log with deploy IDs, metadata snapshots taken before each change, data before/after files |
| `05_Conflicts/` | Conflicts faced (and how they were fixed) and possible conflicts to check |
| `06_Deployment/` | Pre- and post-deployment checklists, deployment documents, production packages + rollbacks, QA testing, verification evidence |
| `07_Technical_Documents/` | Apex classes, triggers, flows, fields, custom metadata, UI components, integrations, impact analysis |
| `force-app/` | Salesforce source (sandbox). Deployed with the `sf` CLI |
| `scripts/` | Verification Apex, SOQL, document-generator scripts |
| `manifest/` | `package.xml` and retrieve manifests |

## Daily routine
1. New request → add a row in `03_Requirements/Requirements_Log.md`.
2. Follow [Working_Instructions.md](Working_Instructions.md).
3. After the deploy → `04_Change_Records/Change_Log.md`, the evidence in `06_Deployment/Post_Deployment_Verification/`, any new conflict in `05_Conflicts/`.
4. Commit and push.
