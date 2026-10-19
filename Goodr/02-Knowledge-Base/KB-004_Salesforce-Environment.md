# KB-004 — Salesforce Environment and Tooling

| | |
|---|---|
| **Document ID** | KB-004 |
| **Last updated** | 2026-10-19 |

## 1. Org used for all work in this project

| Item | Value |
|---|---|
| CLI alias | `GDRSAND` (also `GDRSandbox`) |
| Sandbox | Partial copy sandbox `partial` |
| Username | `sandipp@goodr.com.partial` (shows as "Ruben Smith") |
| Instance URL | https://energy-enterprise-8976--partial.sandbox.my.salesforce.com |

## 2. Sandbox configuration done by hand (not in metadata)
| Setting | State | When | Record |
|---|---|---|---|
| Sector values added, including "Development" | Active | 2026-09-28 | [CR-002](../04-Change-Records/CR-002_New-Sector-Values.md) |
| Field history tracking on Account (Shopify fields on; Vertical, Sport / Category, Website off) | On / off | 2026-09-30 | [CR-004](../04-Change-Records/CR-004_Field-History-Tracking.md) |
| Scheduled job "Shopify At Risk Notices Daily" (05:00, Asia/Kolkata) | Scheduled | 2026-09-30 | [CR-001](../04-Change-Records/CR-001_Shopify-At-Risk-Warm-Off-Offboarding-Sandbox-Build.md) |
| Shopify_At_Risk_Config: Auto Offboard on, test filter `R12 WOT%` | Set | 2026-10-01 | [CR-001](../04-Change-Records/CR-001_Shopify-At-Risk-Warm-Off-Offboarding-Sandbox-Build.md) |
| Key Accounts → Key Account | Renamed | 2026-10-06 | [CR-006](../04-Change-Records/CR-006_Key-Accounts-To-Key-Account-Rename-In-The.md) |
| Old Sector values and Specialty CAN | **Deactivated** | 2026-10-08 | [CR-014](../04-Change-Records/CR-014_Old-Values-Deactivated.md) |
| NetSuite credentials (custom metadata) | Kept in the org only | n/a | [TECH-007](../07-Technical/TECH-007_Secure-Configuration.md) |

## 3. Local tooling (as of 2026-10-19)
| Tool | Version / state |
|---|---|
| Salesforce CLI | 2.138.6 |
| Git | 2.55.0 (Git for Windows) |
| GitHub CLI | 2.102.0, logged in as `yogemani` (write access to `sfdcut/SFDC`) |
| Excel | 2007, driven from PowerShell COM for workbooks. No Python or Node |

## 4. API version
Retrieve manifests use `<version>68.0</version>`. Version 59 drops newer flow and page elements ([CON-018](../05-Conflicts/CON-018_API-Version-Retrieving-With-Manifest-Version-59.md)).
