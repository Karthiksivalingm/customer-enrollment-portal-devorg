# Epicare — Salesforce (Epicare Insurance, UTDEV sandbox)

Epicare project in the shared `sfdcut/SFDC` repository. `force-app/` mirrors the unmanaged metadata of the Epicare Insurance sandbox
(alias `UTDEV`, Org ID `00DWB000008ALkv2AG`).

**Start here:** [CLAUDE.md](CLAUDE.md) → [01-Instructions/Epicare-Working-Instructions.md](01-Instructions/Epicare-Working-Instructions.md).
Every document: [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

| Folder | Contents |
|---|---|
| [01-Instructions](01-Instructions/) | Permanent rules: working instructions, Salesforce safety, documentation, Git automation |
| [02-Knowledge-Base](02-Knowledge-Base/) | Verified overview of the Epicare org: data model, automation, security, integrations, constraints |
| [03-Requirements](03-Requirements/) | Dated REQ records |
| [04-Change-Records](04-Change-Records/) | Dated CR records of actual, authorized record changes |
| [05-Conflicts](05-Conflicts/) | Dated CF records of errors and conflicts |
| [06-Deployment](06-Deployment/) | Procedures, checklists, dated DEP records |
| [07-Technical-Documents](07-Technical-Documents/) | Technical documents, generated inventories, component change history |
| `force-app/`, `manifest/`, `config/`, `sfdx-project.json` | Salesforce DX project (run commands from `Epicare/`) |
| [scripts](scripts/README.md) | Org verification, safe `sf` wrapper, manifest and retrieval, generators, validation and commit, Claude Code hooks |

## Setup on a new machine
1. `sf org login web --alias UTDEV --instance-url https://test.salesforce.com` (your own sandbox user), then `python scripts/verify_org.py`.
2. Start Claude Code from this `Epicare/` folder.
