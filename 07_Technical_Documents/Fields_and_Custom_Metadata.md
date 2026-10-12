# Fields and Custom Metadata

_Generated 2026-10-12._ This project only tracks the objects and fields that were changed or used during the Sales Channel / Sector work. Retrieve more objects from the org to extend this list.

## Account

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Sales_Channel_V1__c` | Sales Channel V1 | Text | 50 | Backup of the original Sales Channel value (before the 2026 transition). Do not edit. / Original Sales Channel value before the Oct 2026 Sales Channel / Sector transition. Backup only - populated by data migration. Do not edit. Edit access: System Administrator only. |
| `Sector_V1__c` | Sector V1 | Text | 50 | Backup of the original Sector value (before the 2026 transition). Do not edit. / Original Sector value before the Oct 2026 Sales Channel / Sector transition. Backup only - populated by data migration. Do not edit. Edit access: System Administrator only. |

## Account_Cluster_Team__mdt

| Field | Label | Type | Length | Help text / description |
|---|---|---|---|---|
| `Sales_Channel__c` | Sales Channel | Picklist |  |  |

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
