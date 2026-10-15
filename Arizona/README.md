# Arizona — Salesforce (Azlionhearts sandbox)

Independent Arizona project in the shared `sfdcut/SFDC` repository. `force-app/` mirrors the in-scope unmanaged metadata of the
Arizona sandbox (alias `Arizona`, org name Azlionhearts, Org ID `00DWH000005wW9V2AU`).

**Start here:** [CLAUDE.md](CLAUDE.md) → [01-Instructions/Arizona-Working-Instructions.md](01-Instructions/Arizona-Working-Instructions.md).
Project overview: [02-Knowledge-Base/Project-Overview.md](02-Knowledge-Base/Project-Overview.md). Every document: [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

| Folder | Contents |
|---|---|
| [01-Instructions](01-Instructions/) | Permanent rules: working instructions, Salesforce safety, documentation, Git |
| [02-Knowledge-Base](02-Knowledge-Base/) | Evidence-based overview: org context, business processes, data model, automation, integrations, security, open questions |
| [03-Requirements](03-Requirements/) | Dated REQ records |
| [04-Change-Records](04-Change-Records/) | Dated CR records of actual, authorized record/data changes with verified before/after values |
| [05-Conflicts](05-Conflicts/) | Dated CF records of errors, conflicts and failed operations |
| [06-Deployment](06-Deployment/) | Procedures, checklists, dated DEP records and deployment history |
| [07-Technical-Documents](07-Technical-Documents/) | Technical reference, metadata inventory, retrieval reports, component Change History |
| `force-app/`, `manifest/`, `config/`, `sfdx-project.json` | Salesforce DX project (run `sf` commands from `Arizona/`) |
| [scripts](scripts/README.md) | Node.js: org verification, metadata listing, manifest and inventory generators, secret scan, record creation |

## Setup on a new machine
1. `sf org login web --alias Arizona --instance-url https://test.salesforce.com` (your own sandbox user).
2. `cd Arizona && node scripts/verify-org.js`. Update `config/arizona-project.json` only if the user confirms a different sandbox user.
3. Start Claude Code from this `Arizona/` folder so `CLAUDE.md` loads.

## Refresh the metadata baseline
```
node scripts/verify-org.js
node scripts/list-org-metadata.js      # writes .arizona-state/org-listing.json (ignored by Git)
node scripts/build-manifest.js         # manifest/package.xml + manifest/batches/*.xml
git status --short -- .                # commit or review local work first
sf project retrieve start --manifest manifest/batches/01-code.xml --target-org Arizona --ignore-conflicts --wait 60   # one batch at a time
node scripts/build-inventory.js
node scripts/secret-scan.js
```
