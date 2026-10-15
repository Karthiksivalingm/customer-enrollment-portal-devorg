# Salesforce Org Context

## Org identity (VERIFIED 2026-10-15)

| Item | Value |
|---|---|
| CLI alias | `Arizona` (the only org used by this project) |
| Org name | Azlionhearts |
| Org ID | `00DWH000005wW9V2AU` |
| Instance URL | `https://azlionhearts--arizonalh.sandbox.my.salesforce.com` (sandbox name `arizonalh`) |
| Type | Sandbox (`Organization.IsSandbox = true`), Enterprise Edition, instance USA766S |
| Production | Alias `PROD`. Never used from this project. Not authenticated on the setup machine. |
| Source API version | 68.0 (project); custom components were saved at API 66.0–67.0 |

## Installed managed packages (VERIFIED, `sf package installed list`)

| Area | Packages (namespace) | Relevance to Arizona processes |
|---|---|---|
| Documents and e-signature | PandaDoc (`pandadoc`), TS Documents (`docb`), Adobe Acrobat Sign (`echosign_dev1`) | PandaDoc and TS Documents are called from custom Apex ([Integrations.md](Integrations.md)). No custom reference to Acrobat Sign was found. |
| Messaging | 360 SMS (`tdc_tsw`), RingCentral (`rcsfl`) | 360 SMS objects are used by the SMS flows. No custom reference to RingCentral was found. |
| Marketing | Pardot / Account Engagement (`pi`, `pi3`, `sf_mktg_ae`), Marketing Setup Objects (`sf_mktg`), Calendly (`Calendly`) | Pardot-hosted assets and a Calendly link are used in the reminder email. |
| Data Cloud / Data 360 | `ssot`, `cdp_crm_dk1/2/4`, `datacloudflow`, `cdpactvstrgptnr`, `UnifiedMsgEmail`, `UMsgConsentProd` | Data Cloud is provisioned; about 100 system-generated `__dll`/`__dlm` objects exist (out of scope). |
| Other | Salesforce Mobile Apps, MobileLandingNonEssentials, CRM Dashboards, Sales Insights (`OIQ`), SocialCustomerService | Platform/standard packages |

## Users and licences

- **VERIFIED (code comment):** Portal users have a **High-Volume Customer Portal** licence (`UserType = CspLitePortal`), which cannot run
  DML on Contact. The org works around this with a platform event ([Security-and-Permissions.md](Security-and-Permissions.md)).
- **OPEN QUESTION:** Number of internal users and portal users, and the profiles assigned to them (profiles were not retrieved).

## Scheduled and asynchronous processing

| Job | Type | Evidence |
|---|---|---|
| `Expiration_Alerts_Certificate_and_Document` | Scheduled flow, daily, Active | Flow metadata |
| `Expired_Status_Update` | Scheduled flow, daily, Active | Flow metadata |
| `Expiration_Member_and_Parent_Providers` | Scheduled flow, daily, **Draft** (not running) | Flow metadata |
| `CertificationExpiryReminderBatch` | Batch + Schedulable Apex | **VERIFIED scheduled:** CronTrigger "Daily Certification Expiry Reminder", state WAITING, fires daily at 11:00 UTC (04:00 Arizona time) |
| "Update Delivery Status" | Scheduled Apex (CronTrigger), daily 07:00 UTC | **INFERRED:** a managed-package job (likely 360 SMS); not in unmanaged source |
| `pi_*` jobs | Scheduled Apex | Pardot package jobs |
| Community sitemap jobs | Platform | One pair per Experience site |
| `PandaDocEventProcessor` | Queueable with callouts, enqueued by `PandaDocWebhookTrigger` | Code |

Scheduled-job evidence: read-only query `SELECT CronJobDetail.Name, CronJobDetail.JobType, State, NextFireTime FROM CronTrigger`, run on 2026-10-15.
The scheduled flows appear as `Expiration_Alerts_Certificate_and_Document-2` (next 15:00 UTC) and `Expired_Status_Update-4` (next 12:00 UTC).

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial retrieval and org queries. |
