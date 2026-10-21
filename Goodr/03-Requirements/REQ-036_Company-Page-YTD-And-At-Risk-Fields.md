# REQ-036 — Show YTD and At-Risk details on the Company page

| | |
|---|---|
| **ID** | REQ-036 |
| **Status** | ✅ Done in the sandbox (2026-10-21) |
| **Requested** | 2026-10-21 (project lead, after a page review during REQ-035) |
| **Related** | [CR-028](../04-Change-Records/CR-028_Company-Page-YTD-And-At-Risk-Fields.md) · [REQ-035](REQ-035_Auto-Offboarding-Exclusion.md) · [KB-002](../02-Knowledge-Base/Business-Process.md) · [CON-031](../05-Conflicts/CON-031_Shopify-Company-Rollup-Is-Calculated-Per-200-Record.md) |

## Business need
The Company record page showed the At Risk flag and R12 figures, but not the YTD figures that decide the flag (YTD % below 50) or when the Company went at risk. The Store Location page already shows them.

## Review of the two pages
| Field | Store page | Company page before | Decision |
|---|---|---|---|
| Current YTD Sales, Prior YTD Sales, YTD Performance Percent | Yes | No | **Add.** Filled on 3,851 Companies by the weekly R12 job; the Company's At Risk flag is based on them |
| At Risk Since, At Risk Episode Count | Episode count only | No | **Add.** 89 Companies are at risk and get the at-risk task |
| Last Shopify Order Date, Months Since Last Order, Inactivity Stage, Scheduled Deactivation Date | Yes | No | **Not added.** Orders are synced per store; the date is blank on every Company and the others are calculated from it. Companies are not deactivated directly by the automation |
| Total Notices Sent, Open Notices | Yes | No | **Not added.** Notices are created per store only |

## Scope
- **In:** the Shopify Sales Performance section of `Account_Company_Record_Page`.
- **Out:** fields, automation, field access and the Store Location page.

## Acceptance criteria
1. The five fields show in the Shopify Sales Performance section of the Company page.
2. They are read-only on the page: they are set by the weekly R12 job and the at-risk flows, and editing At Risk Since by hand would start the at-risk task flow.
3. No other part of the page or any process changes.

## Notes
Company totals are rolled up per batch chunk, so a Company split across two chunks can show partial totals ([CON-031](../05-Conflicts/CON-031_Shopify-Company-Rollup-Is-Calculated-Per-200-Record.md)). The YTD figures are now visible on the page, so users may notice this.

## Open questions
None.
