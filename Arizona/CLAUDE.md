# Arizona Salesforce: instructions for Claude

This folder is the complete, self-contained Arizona project inside the shared `sfdcut/SFDC` repository.
Work only inside `Arizona/`. Never change, stage or commit any other project folder (`FD/`, `Goodr/`, `MLB/`, `TVM/` …) or repository-root file.

## Key points
- The only Salesforce org is alias **`Arizona`**: Azlionhearts sandbox, Org ID `00DWH000005wW9V2AU`, `IsSandbox = true`.
  Run `node scripts/verify-org.js` before Salesforce work and pass `--target-org Arizona` on every `sf` command.
- **`PROD` (Arizona Production) is never used** for retrieval, configuration, data changes or deployments.
- Never deploy, change records, activate Flows or delete anything without the user's explicit approval of that exact operation and target.
  A Git push is never a deployment. Metadata retrieval never authorizes data changes.
- The real Salesforce source lives in `force-app/main/default/`. Documentation supplements it and never replaces it.
- **Read the instructions and relevant documentation at the start of every task, and update documentation in the same task**
  (routing table in Documentation-Rules.md): REQ for every task, CR / CF / DEP where they apply, `07-Technical-Documents/` plus a dated
  row in `Change-History.md` for metadata changes, `02-Knowledge-Base/` when confirmed behaviour or architecture changes.
- Record actual results only. Never invent requirement IDs, approvals, record values, dates or test results: write **TO BE CONFIRMED**.
- Never print, copy or commit credential values. Run `node scripts/secret-scan.js` before every commit.
- Git: stage explicit `Arizona/` paths only, never `git add .` / `-A`; no force-push. See Git-Rules.md.
- Project background: [02-Knowledge-Base/README.md](02-Knowledge-Base/README.md) (Knowledge Base pages pending). Every document: [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

## Standing instructions (imported)
@01-Instructions/Arizona-Working-Instructions.md
@01-Instructions/Salesforce-Safety-Rules.md
@01-Instructions/Documentation-Rules.md
@01-Instructions/Git-Rules.md
