# Goodr — Salesforce (sandbox GDRSAND)

All work in this folder is done in the Goodr **sandbox** (`GDRSAND`). `force-app/` mirrors that sandbox.

**New to the project? Start with [KB-006 Developer Onboarding](02-Knowledge-Base/KB-006_Developer-Onboarding.md).**
Every document by number: **[DOCUMENT-INDEX.md](DOCUMENT-INDEX.md)**.

## Folders
| Folder | What's in it |
|---|---|
| [01-Instructions](01-Instructions/) | AI-Workflow, Coding Standards, Project Rules, QA Process (read-only) |
| [02-Knowledge-Base](02-Knowledge-Base/) | Project overview, business process, integrations, environment, technical architecture, onboarding |
| [03-Requirements](03-Requirements/) | One REQ document per requirement |
| [04-Change-Records](04-Change-Records/) | One CR document per change made to the sandbox |
| [05-Conflicts](05-Conflicts/) | One CON document per problem or open risk |
| [07-Technical](07-Technical/) | Cluster engine, component inventories, secure configuration, impact analysis |
| [08-QA](08-QA/) | Automated test reports (ATR) and manual test cases (MTC) |
| `force-app/`, `manifest/`, `config/`, `scripts/` | Salesforce DX project. Run `sf` commands from this folder |

## Current status (sandbox)
- **Sales Channel / Sector transition:**
  - Metadata is done: Key Account rename, new Sector values, Specialty CAN retired, V1 backup fields, cluster fix.
  - Data: the V1 backfill is done, and the Account update is applied (159 of 161).
- **Shopify At-Risk / Warm-Off offboarding:** built in the sandbox, with open decisions in [KB-002](02-Knowledge-Base/Business-Process.md).
- **Open items:** the ⚠ entries in [DOCUMENT-INDEX.md](DOCUMENT-INDEX.md).

## Security
Credentials are never committed. NetSuite credential records are excluded by `.gitignore` and `.forceignore`. See [TECH-007](07-Technical/TECH-007_Secure-Configuration.md).
