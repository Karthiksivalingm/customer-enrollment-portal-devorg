# KB-004 — Salesforce Environment and Tooling

| | |
|---|---|
| **Document ID** | KB-004 |
| **Last updated** | 2026-10-14 |

## 1. Orgs
| Item | Sandbox | Production |
|---|---|---|
| CLI alias | `GDRSAND` (also `GDRSandbox`) | `GDRPROD` |
| Username | `sandipp@goodr.com.partial` (shows as "Ruben Smith") | `sandipp@goodr.com` |
| Instance URL | https://energy-enterprise-8976--partial.sandbox.my.salesforce.com | https://energy-enterprise-8976.my.salesforce.com |
| Use | All development and testing | **Read-only** except approved deployments ([Project-Rules](../01-Instructions/Project-Rules.md)) |

## 2. Configuration done by hand (not in metadata)
| Setting | Org | State | When | Record |
|---|---|---|---|---|
| Sector values added, incl. "Development" | Sandbox | Active | 2026-09-28 | [CR-002](../04-Change-Records/CR-002_New-Sector-Values.md) |
| Field history tracking on Account (Shopify fields on; Vertical, Sport / Category, Website off) | Sandbox | On / off | 2026-09-30 | [CR-004](../04-Change-Records/CR-004_Field-History-Tracking.md) |
| Scheduled job "Shopify At Risk Notices Daily" (05:00, Asia/Kolkata) | Sandbox | Scheduled | 2026-09-30 | [CR-001](../04-Change-Records/CR-001_Shopify-At-Risk-Warm-Off-Offboarding-Sandbox-Build.md) |
| Shopify_At_Risk_Config: Auto Offboard on, test filter `R12 WOT%` | Sandbox | Set | 2026-10-01 | [CR-001](../04-Change-Records/CR-001_Shopify-At-Risk-Warm-Off-Offboarding-Sandbox-Build.md) |
| Key Accounts → Key Account | Sandbox and **production** | Renamed | 2026-10-06 | [CR-006](../04-Change-Records/CR-006_Key-Accounts-To-Key-Account-Rename-In-The.md), [CR-007](../04-Change-Records/CR-007_Key-Accounts-To-Key-Account-Rename-In-PRODUCTION.md) |
| Old Sector values and Specialty CAN | Sandbox | **Deactivated** | 2026-10-08 | [CR-014](../04-Change-Records/CR-014_Old-Values-Deactivated.md) |
| NetSuite credentials (custom metadata) | Sandbox | Kept in the org only | n/a | [TECH-007](../07-Technical/TECH-007_Secure-Configuration.md) |

## 3. Local tooling (as of 2026-10-14)
| Tool | Version / state |
|---|---|
| Salesforce CLI | 2.138.6 |
| Git | 2.55.0 (Git for Windows, installed 2026-10-12 with winget) |
| GitHub CLI | 2.102.0, logged in as `yogemani` (write access to `sfdcut/SFDC`) |
| Excel | 2007, driven from PowerShell COM for workbooks. No Python or Node |
| Secret-blocking hook | `Goodr/scripts/git-hooks/pre-commit`. Enable it in a clone with `git config core.hooksPath Goodr/scripts/git-hooks` |

## 4. Repositories
| Repository | Role |
|---|---|
| `sfdcut/SFDC`, folder `Goodr/` | **Main home** of the Goodr project from 2026-10-14 ([CR-024](../04-Change-Records/CR-024_Move-Into-Sfdcut-SFDC-Repository.md)) |
| `yogemani/GDRSandbox` | Earlier home, kept active as it was on 2026-10-13. Don't make new changes there |

## 5. API version
Retrieve manifests use `<version>68.0</version>`. Version 59 drops newer flow and page elements ([CON-018](../05-Conflicts/CON-018_API-Version-Retrieving-With-Manifest-Version-59.md)).
