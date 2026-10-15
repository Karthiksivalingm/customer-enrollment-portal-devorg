# Salesforce Org Context

## Verified identity (2026-10-15)

| Property | Value | Evidence |
|---|---|---|
| CLI alias | `UTDEV` | `sf org list` |
| Organization name | Epicare Insurance | `SELECT Name FROM Organization` |
| Org ID | `00DWB000008ALkv2AG` | `sf org display --target-org UTDEV` (JSON parsed; no tokens printed) |
| Username used | `sandipp@epicareinsurance.com.utdev` | `sf org display` |
| Instance URL | `https://epicareinsurance--utdev.sandbox.my.salesforce.com` (instance USA754S) | `sf org display`, Organization query |
| Sandbox | Yes (`IsSandbox = true`), sandbox name `utdev` | Organization query |
| Edition | Enterprise Edition | `Organization.OrganizationType` |
| API version | 68.0 | `sf org display` |
| Production | Alias `PROD` (`00DKc00000BEveDMAT`) is Epicare production. **Not used by this project** | `sf org list` |

Authentication data is never recorded. On 2026-10-15, before this setup ran, the user confirmed that the UTDEV session exposed in earlier
terminal output had already been secured.

## Installed packages (2026-10-15, `sf package installed list`)
| Package | Namespace | Note |
|---|---|---|
| Sales Insights | `OIQ` | Managed. Excluded from source |
| Salesforce Connected Apps | `sf_com_apps` | Managed. Excluded from source |
| GS_Sales_Reports_Dashboards | — | **Unmanaged** report/dashboard pack. Its reports cannot be told apart from Epicare-authored ones |
| Salesforce.com CRM Dashboards | — | **Unmanaged** dashboard pack. Same caveat |

Salesforce-owned namespaces seen in metadata listings: `standard`, `force`, `sfdcInternalInt`.

## Features not enabled
The Metadata API reports these types as "Cannot use … in this organization":
- Omni-Channel: ServiceChannel, QueueRoutingConfig, PresenceUserConfig.
- Entitlements: EntitlementProcess, MilestoneType.
- Territory Management: Territory2Model.
- Sharing sets.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from verified org identity and the package list. |
