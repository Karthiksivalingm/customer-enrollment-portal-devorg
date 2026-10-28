# Epicare — Salesforce (Epicare Insurance, UTDEV sandbox)

Epicare project in the shared `sfdcut/SFDC` repository. `force-app/` mirrors the unmanaged metadata of the Epicare Insurance sandbox
(alias `UTDEV`, Org ID `00DWB000008ALkv2AG`).

**Start here:** [CLAUDE.md](CLAUDE.md) → [01-Instructions/Project-Rules.md](01-Instructions/Project-Rules.md).
Every document, the requirement lookup and the next free numbers: [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

```
Epicare/
├── 01-Instructions/          common: AI-Workflow, Coding Standards, Project Rules, QA Process (read-only)
├── 02-Knowledge-Base/        common: project overview, org context, data model, automation, integrations, security
├── DOCUMENT-INDEX.md         master index
├── YYYY-MM/                  one folder per month (MONTH-INDEX.md, YYYY-MM_Tracker.xlsx,
│                             03-Requirements … 08-QA)
├── force-app/, manifest/, config/, sfdx-project.json   Salesforce DX project
└── scripts/                  sf_safe, retrieval, inventories, new_doc, build_index, tracker/Build-MonthTracker.ps1
```

## Setup on a new machine
1. `sf org login web --alias UTDEV --instance-url https://test.salesforce.com` (your own sandbox user), then `python scripts/verify_org.py`.
2. Start Claude Code from this `Epicare/` folder.
