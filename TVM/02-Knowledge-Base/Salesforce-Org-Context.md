# Salesforce Org Context

## Verified identity (2026-10-14)

| Property | Value | Evidence |
|---|---|---|
| CLI alias | `Fullsandbox` | `sf org list` |
| Organization name | Team Velocity Marketing | `SELECT Name FROM Organization` |
| Org ID | `00DVa000006Eh6TMAS` | `sf org display --target-org Fullsandbox` |
| Username used | `sandipp@unitedtechno.com.tvmprod.fullsando` | `sf org display` |
| Instance URL | `https://teamvelocity--fullsando.sandbox.my.salesforce.com` (instance USA712S) | `sf org display`, Organization query |
| Sandbox | Yes (`IsSandbox = true`), sandbox name `fullsando`. ASSUMPTION: a Full Copy sandbox, from the alias and name; the copy type was not queried. | Organization query |
| Edition | Unlimited Edition | `Organization.OrganizationType` |
| API version | 68.0 (CLI default for this org and `sourceApiVersion`) | `sf org display` |
| Production org | Not connected from this project. Production is out of scope. | — |

Other orgs are authenticated on the developer machine (other clients' production orgs and sandboxes). TVM tooling refuses every alias
except `Fullsandbox` ([Project-Rules.md](../01-Instructions/Project-Rules.md)).

## Installed packages (2026-10-14, `sf package installed list`)

Components of these packages are **not** TVM source. TVM automation, pages and flows depend on several of them.

| Package | Namespace | Version |
|---|---|---|
| Docusign Apps Launcher | `dfsle` | 8.6.2.2 |
| Pardot (Account Engagement), b2bmaIntegration, Marketing Setup Objects, Account Engagement CRM Data, Zoom for Pardot | `pi`, `pi3`, `sf_mktg`, `sf_mktg_ae`, `zoom_for_pardot` | 5.12.0.1 … |
| Salesforce Maps | `maps` | 262.11.0.1 |
| Sales Planning | `sfsp` | 262.3.0.0 |
| Salesforce Contact Center with Amazon Connect | `awsac` | 2.4.0.0 |
| rc_sf_package (RingCentral) | `rcsfl` | 6.43.0.1 |
| Slack | `slackv2` | 1.88.0.1 |
| Gong for Salesforce | `Gong` | 3.0.0.1 |
| Jira Cloud for Salesforce | `JCFS` | 4.79.0.1 |
| monday.com - automations | `mondayapp` | 1.18.0.1 |
| Highspot Connector | `highspot` | 2.124.0.1 |
| Einstein Case Classification Value | `ailabs` | 0.1.0.1 |
| Data Cloud / CDP packages (Sales Cloud, Service Cloud, Loyalty, Advertising, Flow Integration, Standard Data Model) | `cdp_crm_dk1/2/4`, `cdpactvstrgptnr`, `datacloudflow`, `ssot` | — |
| Flow helpers: Flow Email Composer, Dynamic Flow Progress, Flow Launcher, FlowActionsBasePack, Launch Flow Modal, LWCC, Contextual Time and Location | `Email_Composer`, `dflowp`, `joshdaymentlabs`, `usf3`, `sf_flowmodal`, `lwcc`, `contextual` | — |
| Others: Profile2PermSet, Trail Tracker, SalesforceIQ Inbox, Sales Insights, DynamicHeaderFooter, Unified Messaging packages, Salesforce Mobile/Connected Apps | `Profile2PermSet`, `trailheadapp`, `relateiq`, `OIQ`, `dhfpi`, `UMsgConsentProd`, `UnifiedMsgEmail`, `sf_chttr_apps`, `sf_com_apps` | — |
| **Without namespace:** 2 Way Case Automation Solution, Centric Tickets 2.0, CollectionActionsL, FlowScreenComponentsBasePack, Flow Multi Select Value Parser, ReloadPage, updateScreen, richTextAreaFSC, SendBetterEmail, GS_Sales_Reports_Dashboards, Salesforce.com CRM Dashboards | — | — |

Packages without a namespace are an ownership risk. Components of *unlocked* no-namespace packages are flagged `installedEditable` by the
Metadata API and excluded from TVM source. Components installed by *unmanaged* packages, such as "2 Way Case Automation Solution" or
GS_Sales_Reports_Dashboards, become ordinary org metadata and **cannot be told apart** from TVM-authored metadata. They may be present
in `force-app`. See [Known-Constraints.md](Known-Constraints.md).

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from verified org identity and the installed-package list. |
