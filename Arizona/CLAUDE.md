# Arizona Salesforce: instructions for Claude

This folder is the complete, self-contained Arizona project inside the shared `sfdcut/SFDC` repository.
Work only inside `Arizona/`. Never change, stage or commit any other project folder or repository-root file.

The standing instructions are the three files in `01-Instructions/` (same as every project in this repository):
[AI-Workflow.md](01-Instructions/AI-Workflow.md), [Coding-Standards.md](01-Instructions/Coding-Standards.md) and
[Project-Rules.md](01-Instructions/Project-Rules.md). The points below are the Arizona-specific facts those files refer to.

## Arizona specifics
- **Agreed sandbox:** alias **`Arizona`**: org Azlionhearts, Org ID `00DWH000005wW9V2AU`,
  `https://azlionhearts--arizonalh.sandbox.my.salesforce.com`, `IsSandbox = true` (verified 2026-10-15).
  Run `node scripts/verify-org.js` before Salesforce work and pass `--target-org Arizona` on every `sf` command.
- **Production:** alias `PROD`. Never used for retrieval, configuration, data changes or deployments without the project lead's
  approval of that specific change.
- Metadata retrieval never authorizes data changes. A Git push is never a deployment.
- Metadata scope and retrieval: [config/arizona-project.json](config/arizona-project.json),
  [07-Technical-Documents/Metadata-Scope.md](07-Technical-Documents/Metadata-Scope.md), [scripts/README.md](scripts/README.md).
- Never print, copy or commit credential values (PandaDoc keys live in custom labels that are deliberately not retrieved).
  Run `node scripts/secret-scan.js` before every commit.
- Git: branch `main` on `origin`; pull before you push; stage explicit `Arizona/` paths only, never `git add .` / `-A`; no force-push.
- Project background: [02-Knowledge-Base/Project-Overview.md](02-Knowledge-Base/Project-Overview.md). Every document: [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

## Standing instructions (imported)
@01-Instructions/AI-Workflow.md
@01-Instructions/Coding-Standards.md
@01-Instructions/Project-Rules.md
