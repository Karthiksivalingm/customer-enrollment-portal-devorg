# TVM — Salesforce (Team Velocity Marketing, Fullsandbox)

Independent TVM project in the shared `sfdcut/SFDC` repository. `force-app/` mirrors the unmanaged metadata of the TVM Fullsandbox
(alias `Fullsandbox`, Org ID `00DVa000006Eh6TMAS`). Work happens on branch `tvm/develop`.

**Start here:** [CLAUDE.md](CLAUDE.md) → [01-Instructions/TVM-Working-Instructions.md](01-Instructions/TVM-Working-Instructions.md).
Every document: [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

| Folder | Contents |
|---|---|
| [01-Instructions](01-Instructions/) | Permanent rules: working instructions, Salesforce safety, documentation, Git automation |
| [02-Knowledge-Base](02-Knowledge-Base/) | Verified overview: org context, data model, architecture, automation, integrations, security, constraints |
| [03-Requirements](03-Requirements/) | Dated REQ records |
| [04-Change-Records](04-Change-Records/) | Dated CR records of actual record/data changes with verified before/after values |
| [05-Conflicts](05-Conflicts/) | Dated CF records of errors and conflicts |
| [06-Deployment](06-Deployment/) | Procedures, checklists and dated DEP records |
| [07-Technical-Documents](07-Technical-Documents/) | Topic documents, generated inventories, component Change History |
| `force-app/`, `manifest/`, `config/`, `sfdx-project.json` | Salesforce DX project (run commands from `TVM/`) |
| [scripts](scripts/README.md) | Org verification, safe `sf` wrapper, generators, auto-commit, Claude Code hooks |

## Setup on a new machine
1. `git switch tvm/develop`
2. `sf org login web --alias Fullsandbox --instance-url https://test.salesforce.com` (your own sandbox user), then `python scripts/verify_org.py`.
3. Start Claude Code from this `TVM/` folder.
