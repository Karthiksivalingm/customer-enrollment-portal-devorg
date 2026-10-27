# CR-034 — Scheduled Apex jobs moved to Pacific Time

| | |
|---|---|
| **Change ID** | CR-034 |
| **Date** | 2026-10-27 |
| **Requirement** | Client decision on the at-risk / offboarding go-live questions: all jobs in Pacific Time, adjusting for daylight saving; the notices job runs after the order sync ([CON-020](../05-Conflicts/CON-020_Shopify-At-Risk-Sandbox-Only-Settings.md)) |
| **Org** | GDRSAND |
| **Deploy ID** | — (anonymous Apex: jobs aborted and rescheduled) |
| **By** | Assistant, running as the CLI user, whose time zone was set to America/Los_Angeles by the project lead |
| **Status** | Done in sandbox |

## Why
A scheduled job runs in the time zone of the user who scheduled it, and keeps that time zone when the user's own time zone changes later. All custom jobs had been scheduled in Asia/Kolkata. The client asked for Pacific Time that follows daylight saving, so the jobs use **America/Los_Angeles** rather than a fixed PST offset.

## What changed
Each job was aborted and scheduled again with the **same name and the same clock time**; only the time zone changed.

| Job | Class | Cron | Time (Pacific) | Before |
|---|---|---|---|---|
| API Error Log Cleanup | `APILogCleanupBatch` | `0 0 2 * * ?` | Daily 2:00 AM | Asia/Kolkata |
| Shopify Order Sync Night | `ShopifyOrderSyncBatch` | `0 0 3 * * ?` | Daily 3:00 AM | Asia/Kolkata |
| Shopify At Risk Notices Daily | `ShopifyAtRiskNoticeBatch` | `0 0 5 * * ?` | Daily 5:00 AM (2 h after the night order sync) | Asia/Kolkata |
| Shopify Order Sync Day | `ShopifyOrderSyncBatch` | `0 0 10 * * ?` | Daily 10:00 AM | Asia/Kolkata |
| Shopify Last Order Date Refresh | `BackfillLastShopifyOrderDate` | `0 0 21 ? * SUN` | Sunday 9:00 PM | Asia/Kolkata |
| Shopify R12 Sales Weekly | `ShopifyR12SalesBatch` | `0 0 23 ? * SUN` | Sunday 11:00 PM | Asia/Kolkata |
| NetSuite Product Sync - Nightly | `NetSuiteSyncScheduler` | `0 0 23 * * ?` | Daily 11:00 PM | **Recreated.** It had been deleted; it was scheduled at `0 0 23 * * ?` on 2026-10-21 |

**Not changed:**
- `Remaining Hours` (`CaseSLAScheduler`): already America/Los_Angeles.
- Salesforce system jobs: dashboard refresh, sitemap, analytics loaders.

## Verification
`CronTrigger` after the change: all 8 scheduled Apex jobs show America/Los_Angeles and state `WAITING`. The next run times follow daylight saving. For example, Shopify R12 Sales Weekly runs on Sunday 1 Nov at 11:00 PM PST, which is 07:00 GMT on 2 Nov, after the clocks change.

The script is kept outside the repository and can be re-run in another org. It stops unless the running user's time zone is America/Los_Angeles.

## Rollback
Abort the jobs and schedule them again as a user in the previous time zone.
