# TECH-005 — Fields and Custom Metadata

_Generated 2026-10-14._ This project only tracks the objects and fields that were changed or used during the Sales Channel / Sector work. Retrieve more objects from the org to extend this list.

## Account

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Active__c` | Shopify Ordering Enabled | Checkbox |  | The Account should be marked Inactive when the shop is closed. |
| `Cluster__c` | Cluster | Picklist |  |  |
| `Current_Rolling_12_Month_Sales__c` | Rolling 12 Month Sales | Currency |  | Total Shopify orders over the last 365 days. If today is 11 Sep 2026, this covers 11 Sep 2025 to 11 Sep 2026. Used for account sizing only â€” it does not decide the At Risk flag. / Sales team can see on the account page how much the customer spent THIS year without running a report |
| `Inactivity_Stage__c` | Inactivity Stage | Text |  |  |
| `Last_Shopify_Order_Date__c` | Last Shopify Order Date | Date |  |  |
| `Last_Shopify_Order_Sync_Date__c` | Last Shopify Order Sync Date | Date |  | The date this account's orders were last pulled from Shopify. This is a system field about the sync, not about customer activity. |
| `Months_Since_Last_Order__c` | Months Since Last Order | Number |  |  |
| `Order_Channel__c` | Order Channel | Picklist |  |  |
| `Sales_Channel_V1__c` | Sales Channel V1 | Text | 50 | Backup of the original Sales Channel value (before the 2026 transition). Do not edit. / Original Sales Channel value before the Oct 2026 Sales Channel / Sector transition. Backup only - populated by data migration. Do not edit. Edit access: System Administrator only. |
| `Sales_Channel__c` | Sales Channel | Picklist |  |  |
| `Scheduled_Deactivation_Date__c` | Scheduled Deactivation Date | Date |  |  |
| `Sector_V1__c` | Sector V1 | Text | 50 | Backup of the original Sector value (before the 2026 transition). Do not edit. / Original Sector value before the Oct 2026 Sales Channel / Sector transition. Backup only - populated by data migration. Do not edit. Edit access: System Administrator only. |
| `Sector__c` | Sector | Picklist |  |  |
| `Shopify_Sales_At_Risk__c` | Shopify Sales At Risk | Checkbox |  | TRUE  = account is at risk (spending 50% less than last year) FALSE = account is healthy (spending within normal range) / This checkbox it is hard to quickly identify which accounts need attention A ratio number alone is harder to filter on |
| `Sport_Category__c` | Sport / Category | Picklist |  |  |
| `Vertical__c` | Vertical | Picklist |  |  |
| `Website` |  |  |  |  |
| `YTD_Performance_Percent__c` | YTD Performance Percent | Percent |  | This year's sales as a percentage of last year's for the same period. Below 50% flags the store as at risk. |

## Account_Cluster_Team__mdt

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Access_Level__c` | Access Level | Picklist |  |  |
| `Cluster_Value__c` | Cluster Value | Text | 20 |  |
| `ObjectAPIName__c` | ObjectAPIName | Picklist |  |  |
| `Sales_Channel__c` | Sales Channel | Picklist |  |  |
| `Team_Role__c` | Team Role | Text | 200 |  |
| `User_Identifier__c` | User Identifier | Text | 200 |  |

## Contact

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Sales_Channel__c` | Sales Channel | Picklist |  |  |
| `Sector__c` | Sector | Picklist |  |  |

## Lead

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Sales_Channel__c` | Sales Channel | Picklist |  |  |
| `Sector__c` | Sector | Picklist |  |  |

## Opportunity

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Sales_Channel__c` | Sales Channel | Picklist |  |  |
| `Sector__c` | Sector | Picklist |  |  |

## Sales_Channel_Cluster__mdt

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Cluster_Value__c` | Cluster Value | Picklist |  |  |
| `ObjectAPIName__c` | Object API Name | Picklist |  |  |
| `Rule_Condition__c` | Rule Condition | LongTextArea | 32768 |  |

## Shopify_At_Risk_Config__mdt

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Active__c` | Active | Checkbox |  | Untick to pause the whole process. No notices created or sent while off. |
| `At_Risk_Mode__c` | At Risk Mode | Picklist |  |  |
| `Auto_Offboard__c` | Auto Offboard | Checkbox |  |  |
| `Deactivation_Months__c` | Deactivation Months | Number |  |  |
| `Email_Template_Name__c` | Email Template Name | Text | 255 | Template used for the notice. |
| `Exclude_Bounced__c` | Exclude Bounced | Checkbox |  |  |
| `Legacy_Notice_Enabled__c` | Legacy Notice Enabled | Checkbox |  |  |
| `Offboard_Owner_Username__c` | Offboard Owner Username | Text | 255 |  |
| `Offboard_Reason__c` | Offboard Reason | Text | 255 |  |
| `Org_Wide_Email__c` | Org Wide Email | Text | 255 | Address the notice is sent from. |
| `Reminder_Days__c` | Reminder Days | Number |  |  |
| `Require_Opt_In__c` | Require Opt In | Checkbox |  |  |
| `Template_Stage_1__c` | Template Stage 1 | Text | 100 |  |
| `Template_Stage_2__c` | Template Stage 2 | Text | 100 |  |
| `Template_Stage_3__c` | Template Stage 3 | Text | 100 |  |
| `Template_Stage_4__c` | Template Stage 4 | Text | 100 |  |
| `Template_Stage_5__c` | Template Stage 5 | Text | 100 |  |
| `Test_Store_Name_Filter__c` | Test Store Name Filter | Text | 100 |  |

## Shopify_At_Risk_Notice__c

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `At_Risk_Since__c` | At Risk Since | Date |  | The date the store location became at risk on this occasion. / Copied from the account when the notice is created. Identifies which at-risk episode this notice belongs to and forms part of the unique notice key. |
| `Company_Account__c` | Company Account | Text |  | The parent company this location belongs to. / The parent company this location belongs to. |
| `Contact__c` | Contact | Lookup |  | The person this notice was sent to. / The person this notice was sent to. |
| `Days_Since_Notice__c` | Days Since Notice | Number |  | How many days have passed since the notice was sent. |
| `Days_To_Recovery__c` | Days To Recovery | Number |  | How many days it took this store to start ordering again after the notice was sent. |
| `Deactivation_Date__c` | Deactivation Date | Date |  |  |
| `Decline_Ratio_At_Notice__c` | Decline Ratio At Notice | Number |  |  |
| `Email_Sent__c` | Email Sent | Checkbox |  | Ticked once the notice email has been sent. |
| `Email_Subject__c` | Email Subject | Text | 255 | The subject line of the notice email that was sent. |
| `Last_Order_Date_At_Notice__c` | Last Order Date At Notice | Date |  |  |
| `Months_Inactive_At_Notice__c` | Months Inactive At Notice | Number |  |  |
| `Notice_Date__c` | Notice Date | Date |  | The date the notice email was sent to this contact. |
| `Notice_Key__c` | Notice Key | Text | 100 | System field. Prevents the same person being notified twice for the same at-risk occasion. / Contact ID plus episode start date. Database-level guarantee behind the send-once rule. |
| `Performance_Percent_At_Notice__c` | Performance Percent At Notice | Percent |  |  |
| `Prior_YTD_Sales_At_Notice__c` | Prior YTD Sales At Notice | Currency |  |  |
| `R12_Sales_At_Notice__c` | R12 Sales At Notice | Currency |  |  |
| `Recovered_Date__c` | Recovered Date | Date |  | The date this store location started ordering again. |
| `Stage__c` | Stage | Picklist |  |  |
| `Status__c` | Status | Picklist |  | Pending Send â€” identified, email not yet sent. Notice Sent â€” email issued, countdown running. Recovered â€” the store started ordering again. Offboard Due â€” countdown elapsed, store still not ordering. Cancelled â€” withdrawn manually. |
| `Store_Account__c` | Store Account | MasterDetail |  | The store location whose sales triggered this notice. / The store location whose sales triggered this notice. |
| `Store_Name__c` | Store Name | Text |  |  |
| `YTD_Sales_At_Notice__c` | YTD Sales At Notice | Currency |  |  |

## Custom metadata records

| Type | Records | Purpose |
|---|---|---|
| `Account_Cluster_Team__mdt` | 218 | Team members per cluster and object: Team_Role__c, User_Identifier__c, Access_Level__c. Read by ClusterTeamEngine. |
| `Case_Queue_Team_Routing__mdt` | 7 | Case queue -> case team routing. |
| `NetSuite_Config__mdt` | 1 | NetSuite OAuth 2.0 settings. **Secret fields are not stored in git.** |
| `NetSuite_Credential__mdt` | 1 | NetSuite TBA credentials. **Not stored in git.** |
| `Sales_Channel_Cluster__mdt` | 41 | Cluster rules: Rule_Condition__c (e.g. Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service') -> Cluster_Value__c, per ObjectAPIName__c. Read by ClusterRuleEngine. |
| `Shopify_At_Risk_Config__mdt` | 1 | At-risk / offboarding thresholds, email template, org-wide email. |
| `SLA_Configuration__mdt` | 23 | Case SLA targets. |

## Sales Channel -> Cluster rules (Sales_Channel_Cluster__mdt)

| Record | Object | Rule condition | Cluster |
|---|---|---|---|
| `Global` | Account | `Sales_Channel__c = 'Global'` | Cluster 7 |
| `Global_Contact` | Contact | `Sales_Channel__c = 'Global'` | Cluster 7 |
| `Global_Lead` | Lead | `Sales_Channel__c = 'Global'` | Cluster 7 |
| `Global_Opp` | Opportunity | `Sales_Channel__c = 'Global'` | Cluster 7 |
| `Key_Account_Contact` | Contact | `Sales_Channel__c = 'Key Account'` | Cluster 1 |
| `Key_Account_Lead` | Lead | `Sales_Channel__c = 'Key Account'` | Cluster 1 |
| `Key_Account_Opp` | Opportunity | `Sales_Channel__c = 'Key Account'` | Cluster 1 |
| `Keys_Account_Account` | Account | `Sales_Channel__c = 'Key Account'` | Cluster 1 |
| `Mid_Market` | Account | `Sales_Channel__c = 'Mid-Market'` | Cluster 5 |
| `Mid_Market_Contact` | Contact | `Sales_Channel__c = 'Mid-Market'` | Cluster 5 |
| `Mid_Market_Lead` | Lead | `Sales_Channel__c = 'Mid-Market'` | Cluster 5 |
| `Mid_Market_Opp` | Opportunity | `Sales_Channel__c = 'Mid-Market'` | Cluster 5 |
| `PartnershipsAccount` | Account | `Sales_Channel__c = 'Partnerships'` | Cluster 8 |
| `PartnershipsContact` | Contact | `Sales_Channel__c = 'Partnerships'` | Cluster 8 |
| `PartnershipsLead` | Lead | `Sales_Channel__c = 'Partnerships'` | Cluster 8 |
| `PartnershipsOpp` | Opportunity | `Sales_Channel__c = 'Partnerships'` | Cluster 8 |
| `Specialty_Bridge_Account` | Account | `Sales_Channel__c = 'Specialty' && Sector__c = 'Bridge'` | Cluster 5 |
| `Specialty_Bridge_Contact` | Contact | `Sales_Channel__c = 'Specialty' && Sector__c = 'Bridge'` | Cluster 5 |
| `Specialty_Bridge_Lead` | Lead | `Sales_Channel__c = 'Specialty' && Sector__c = 'Bridge'` | Cluster 5 |
| `Specialty_Bridge_Opp` | Opportunity | `Sales_Channel__c = 'Specialty' && Sector__c = 'Bridge'` | Cluster 5 |
| `Specialty_Contact` | Contact | `Sales_Channel__c = 'Specialty' && Sector__c = 'Sellgoodr USA'` | Cluster 6 |
| `Specialty_Lead` | Lead | `Sales_Channel__c = 'Specialty' && Sector__c = 'Sellgoodr USA'` | Cluster 6 |
| `Specialty_Opp` | Opportunity | `Sales_Channel__c = 'Specialty' && Sector__c = 'Sellgoodr USA'` | Cluster 6 |
| `Specialty_Planned_Account` | Account | `Sales_Channel__c = 'Specialty' && Sector__c = 'Planned'` | Cluster 5 |
| `Specialty_Planned_Contact` | Contact | `Sales_Channel__c = 'Specialty' && Sector__c = 'Planned'` | Cluster 5 |
| `Specialty_Planned_Lead` | Lead | `Sales_Channel__c = 'Specialty' && Sector__c = 'Planned'` | Cluster 5 |
| `Specialty_Planned_Opp` | Opportunity | `Sales_Channel__c = 'Specialty' && Sector__c = 'Planned'` | Cluster 5 |
| `Specialty_Self_Service_Account` | Account | `Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service'` | Cluster 6 |
| `Specialty_Self_Service_Contact` | Contact | `Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service'` | Cluster 6 |
| `Specialty_Self_Service_Lead` | Lead | `Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service'` | Cluster 6 |
| `Specialty_Self_Service_Opp` | Opportunity | `Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service'` | Cluster 6 |
| `SpecialtyCAN_Bridge_Account` | Account | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Bridge'` | Cluster 5 |
| `SpecialtyCAN_Bridge_Contact` | Contact | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Bridge'` | Cluster 5 |
| `SpecialtyCAN_Bridge_Lead` | Lead | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Bridge'` | Cluster 5 |
| `SpecialtyCAN_Bridge_Opportunity` | Opportunity | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Bridge'` | Cluster 5 |
| `SpecialtyCAN_Contact` | Contact | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Sellgoodr CAN'` | Cluster 6 |
| `SpecialtyCAN_Opp` | Opportunity | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Sellgoodr CAN'` | Cluster 6 |
| `SpecialtyCANAcc` | Account | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Sellgoodr CAN'` | Cluster 6 |
| `SpecialtyCANLead` | Lead | `Sales_Channel__c = 'Specialty CAN' && Sector__c = 'Sellgoodr CAN'` | Cluster 6 |
| `SpeciaSpecialtylity` | Account | `Sales_Channel__c = 'Specialty' && Sector__c = 'Sellgoodr USA'` | Cluster 6 |
| `Testtwoconditions` | Account | `Sales_Channel__c = 'Key Account'` | Cluster 1 |
