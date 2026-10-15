# Reports and Dashboards

Retrieved from public folders in UTDEV on 2026-10-15: **223 reports** in [`reports/`](../../force-app/main/default/reports/)
and **15 dashboards** in [`dashboards/`](../../force-app/main/default/dashboards/). The 22 sample reports and 1 sample dashboard
that could not be retrieved are listed in [CF-001](../../05-Conflicts/2026-10-15-CF-001-metadata-api-failed-to-return-sample-reports-dashboard-and-a.md).
32 custom report types are in [`reportTypes/`](../../force-app/main/default/reportTypes/).

## Epicare business folders
| Folder | Kind | Content (from report names) |
|---|---|---|
| `ContractingReports` | Reports | Appointments on hold or in progress; active without a writing number; ACA and Medicare/Life/Supplementary appointments; per-carrier lists |
| `ContractingNPN` | Reports | NPN-related contracting reports |
| `NewReports` | Reports | Commissions, chargebacks and clawbacks, exceptions, payment batches, license expiry (30/60/90 days), onboarding pipeline, NIPR-stale agents, reconciliation, unmatched upline policies, forecasts, top producers |
| `Commissions` | Dashboards | Commission dashboards |
| `Executive`, `Excecutive` | Dashboards | Executive dashboards. Two similarly named folders exist; one is likely a misspelling |
| `Operations` (subfolder `Contracting`) | Dashboards | Contracting operations |
| `ContractingDashboards` | Dashboards | Contracting |
| `UplineReconciliation` | Dashboards | Upline policy reconciliation |

## Standard and sample folders
`ActivityReports`, `Sales_Marketing_Reports`, `Sales_and_Marketing_Reports`, `Service_Dashboards_Reports`, `DashboardReportsAdoption`,
`Getting_Started_*`, `CRM_180925_*`; dashboards `Activities`, `Service_Dashboards`, `Sales_and_Marketing_Dashboards`,
`Getting_Started_Pilot_Dashboards`. INFERENCE: these come from Salesforce or the unmanaged report packs, not from Epicare work.

## Custom report types
32 custom report types. Only `Products_with_Product_States_with_Renewal_Schedules` covers Epicare custom objects. The rest are on
standard objects (Lead, Contact, Opportunity, User, Flow, Sales Engagement).

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-15 | Created from the baseline retrieval | CF-001 |
