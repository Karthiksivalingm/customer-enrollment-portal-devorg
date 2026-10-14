# CR-001 — Shopify At-Risk / Warm-Off offboarding: sandbox build

| | |
|---|---|
| **Change ID** | CR-001 |
| **Date** | 2026-09-25 → 2026-10-01 (25 Sep → 1 Oct) |
| **Requirement** | [REQ-030](../03-Requirements/REQ-030_Document-Shopify-R12-And-At-Risk-Process.md) [REQ-031](../03-Requirements/REQ-031_Shopify-At-Risk-Component-List.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000G3ISECA3` |
| **By** | User (Setup) + VS Code deploys |
| **Status** | Done in sandbox |

## What changed
**Why:** warn Shopify stores that stop ordering (warm-off emails at months 12/15/17/17+15 days) and deactivate them at 18 months.
How it works: [02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding.md](../02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding.md).
Production component list: `06-Deployment/Deployment-Documents/Shopify_AtRisk_Offboarding_Deployment_Document.xlsx`.

| Date / time | Change | How |
|---|---|---|
| 09-25 12:36 | Account field `Last_Shopify_Order_Sync_Date__c` (Date) created | Setup |
| 09-25 14:33 / 14:35 | Account formulas `Months_Since_Last_Order__c` (Number), `Scheduled_Deactivation_Date__c` (Date) created | Setup |
| 09-25 14:38 – 14:40 | `Shopify_At_Risk_Notice__c` fields `Stage__c` (picklist), `Months_Inactive_At_Notice__c`, `Last_Order_Date_At_Notice__c` + layout | Setup |
| 09-28 11:05 | `Shopify_At_Risk_Notice__c.Deactivation_Date__c` created | Setup |
| 09-28 13:08 | Account formula `Inactivity_Stage__c` (Text) created | Setup |
| 09-28 13:12 | Offboard Due Date formula changed to use Stage / Deactivation_Date__c | Setup |
| 09-28 14:17 | Notice `Status__c` value **Send Failed** added | Setup |
| 09-28 14:20 | Notice Key set as unique external ID (prevents duplicate notices) | Setup |
| 09-28 14:34 | `Shopify_At_Risk_Config.Default`: Template Stage 1–5 = Warm Off 1–5; At Risk Mode = Every Stage; Reminder Days = 15; Deactivation Months = 18; Test Store Name Filter = `R12%` | Setup |
| 09-28 15:27 | Flow `Send_Shopify_At_Risk_Notice` v2 activated (v1 deactivated). It now calls Apex `SendWarmOffEmail` | Deploy `0Afdx00000G3ISECA3` (earlier attempts `G3PVJCA3` and `G3RwvCAF` failed) |
| 09-28 16:06 – 16:08 | Email templates `Warm_Off_1_Check_In`, `Warm_Off_2_Early_Notice`, `Warm_Off_3_30_Day_Warning`, `Warm_Off_4_15_Day_Reminder`, `Warm_Off_5_Deactivation_Notice` | Deploys `G3SPxCAN`, `G3SWPCA3`, `G3SbFCAV`, `G3SeTCAV`, `G3Sg5CAF` |
| 09-29 13:13 / 09-30 11:15 | Test Store Name Filter → `R12 WO A%` → `R12 WOT%` (**must be cleared before production**) | Setup |
| 09-28 → 10-01 | `Auto_Offboard__c` switched on and off during testing. **Final value: on** (10-01 10:53) | Setup |
| 09-30 ~14:40 | Scheduled job **"Shopify At Risk Notices Daily"** (`ShopifyAtRiskNoticeBatch`, cron `0 0 5 * * ?`, Asia/Kolkata) created | Setup / Apex (by user) |
| 09-30 12:53 | Notice field **Offboard Due Date deleted** | Setup |
| 09-30 13:41 | `Scheduled_Deactivation_Date__c`: `Last_Shopify_Order_Date__c + 548` → `ADDMONTHS(Last_Shopify_Order_Date__c, 18)` | Setup |
| 09-30 13:42 | `Inactivity_Stage__c`: day-based → `ADDMONTHS` stages (Month 12 / 15 / 17 / 18+) | Setup |

The sandbox work also changed some content that the repo didn't have until the 13 Oct sync (CR-021): the config gained At Risk Mode, Deactivation Months and Exclude Bounced, and the email wording was updated ("Hi {!Contact.FirstName}", Section 22 text).


## Rollback
Reactivate flow version 1 of `Send_Shopify_At_Risk_Notice`; redeploy the previous email templates and config from git history; revert the formulas in Setup. The deleted Offboard Due Date field can no longer be restored (deleted fields are kept for 15 days).
