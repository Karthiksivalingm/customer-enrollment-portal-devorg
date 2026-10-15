# Scheduled and Asynchronous Jobs

Scheduled state comes from a read-only `CronTrigger` query on UTDEV (2026-10-15). Job names are the names given when the jobs were
scheduled. For the Apex classes behind them, see [Apex-Classes.md](../Metadata-Inventory/Apex-Classes.md): the batch,
schedulable and queueable kinds are marked there.

## Scheduled Apex (CronTrigger job type 7): 17 jobs
| Job name | State | Cron (server time) | Meaning of the schedule |
|---|---|---|---|
| OnboardingChecklistEscalationScheduler | WAITING | `0 0 2 * * ?` | Daily 02:00 |
| Policy Year Increment - Nightly | WAITING | `0 0 2 * * ?` | Daily 02:00 |
| Missing Payment Check - Nightly | WAITING | `0 0 3 * * ?` | Daily 03:00 |
| NIPRStaleCheckScheduler | WAITING | `0 0 0 * * ?` | Daily 00:00 |
| Monthly Agent Scorecard Job | WAITING | `0 0 3 1 * ?` | 1st of month 03:00 |
| System Log Export Monthly | WAITING | `0 0 3 1 * ?` | 1st of month 03:00 |
| Payment Batch Assembly - Day 12 | WAITING | `0 0 11 12 * ?` | 12th of month 11:00 |
| Referral Accrual Batch - Day 12 | WAITING | `0 0 10 12 * ?` | 12th of month 10:00 |
| Daily Commission Exception Follow-Up Job | **PAUSED** | `0 0 0 * * ?` | Daily 00:00 |
| Commission Exception Follow Up Job | **PAUSED** | `0 15 * * * ?` | Hourly at :15 |
| Daily Agent Scorecard Job | **PAUSED** | `0 0 0 * * ?` | Daily 00:00 |
| AppointmentRenewalAlertBatch | **PAUSED** | `0 0 8 * * ?` | Daily 08:00 |
| AppointmentLicenseAlertScheduler | **PAUSED** | `0 0 8 * * ?` | Daily 08:00 |
| Data Retention Monthly | **PAUSED** | `0 0 2 1 * ?` | 1st of month 02:00 |
| AHIP_FFM Certification Expiry Job | **PAUSED** | `0 30 8 * * ?` | Daily 08:30 |
| Certification Expiry Notification Job | **PAUSED** | `0 0 8 * * ?` | Daily 08:00 |
| EO Insurance Expiration Alert Job | **PAUSED** | `0 0 9 * * ?` | Daily 09:00 |

Paused jobs do not run until resumed in Setup → Scheduled Jobs. NOT DETERMINED: whether they were paused on purpose in this sandbox,
and whether production runs them.

## Other platform jobs
Three Salesforce platform jobs (types K, T and X: analytics loaders and semantic graph). They are not Epicare code.

## History
| Date | Change | Record |
|---|---|---|
| 2026-10-15 | Created from the CronTrigger query | — |
