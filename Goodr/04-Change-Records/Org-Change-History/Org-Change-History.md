# Org Change History (generated)

_Generated 2026-10-14 12:15 (local time) by `scripts/doc-builders/build_org_change_history.ps1` from each org's own records._
_Sources: DeployRequest (Salesforce keeps it for about 30 days) and the Setup Audit Trail (180 days), filtered to user `sandipp@goodr.com%` since 2026-08-01._
_Raw CSVs are in this folder. The narrative explanation of each change is in [DOCUMENT-INDEX](../../DOCUMENT-INDEX.md#04--change-records) and the CR-0xx documents in [04-Change-Records](../)._

## GDRSAND

Deploys: 25 (succeeded 23) Â· validations: 22 Â· Setup Audit Trail entries: 779

### Deploys and validations

| Date | Deploy ID | Type | Status | Components | Tests (errors) | Components deployed |
|---|---|---|---|---|---|---|
| 2026-08-14 17:22 | `0Afdx00000FXhwoCAD` | Deploy | Succeeded | 33 | 0 (0) | EmailTemplateFolder:EmailTemplatesMVP (No change)<br>EmailTemplate:EmailTemplatesMVP/First_Reply_Key_Account_Inbounds_1761686244065 (No change)<br>EmailTemplate:EmailTemplatesMVP/First_Reply_Specialty_Inbounds_1761686449174 (Changed)<br>EmailTemplate:EmailTemplatesMVP/First_Reply_Specialty_Inbounds_CAN_1761686796362 (No change)<br>EmailTemplate:EmailTemplatesMVP/Global_Email_Inbound_First_Reply_1761680388197 (No change)<br>EmailTemplate:EmailTemplatesMVP/New_Lead_Account_Approved_1762544201939 (No change)<br>EmailTemplate:EmailTemplatesMVP/New_Lead_Application_Rejected_1762544491388 (No change)<br>EmailTemplate:EmailTemplatesMVP/New_Lead_Submision_CAN_1761687624103 (No change)<br>... +25 more (see CSV) |
| 2026-09-28 15:27 | `0Afdx00000G3ISECA3` | Deploy | Succeeded | 1 | 0 (0) | Flow:Send_Shopify_At_Risk_Notice (Changed) |
| 2026-09-28 15:29 | `0Afdx00000G3PVJCA3` | Deploy | Failed | 0 | 0 (0) |  |
| 2026-09-28 15:59 | `0Afdx00000G3RwvCAF` | Deploy | Failed | 0 | 0 (0) |  |
| 2026-09-28 16:06 | `0Afdx00000G3SPxCAN` | Deploy | Succeeded | 1 | 0 (0) | EmailTemplate:unfiled$public/Warm_Off_1_Check_In (Changed) |
| 2026-09-28 16:06 | `0Afdx00000G3SWPCA3` | Deploy | Succeeded | 1 | 0 (0) | EmailTemplate:unfiled$public/Warm_Off_2_Early_Notice (Changed) |
| 2026-09-28 16:07 | `0Afdx00000G3SbFCAV` | Deploy | Succeeded | 1 | 0 (0) | EmailTemplate:unfiled$public/Warm_Off_3_30_Day_Warning (Changed) |
| 2026-09-28 16:07 | `0Afdx00000G3SeTCAV` | Deploy | Succeeded | 1 | 0 (0) | EmailTemplate:unfiled$public/Warm_Off_4_15_Day_Reminder (Changed) |
| 2026-09-28 16:08 | `0Afdx00000G3Sg5CAF` | Deploy | Succeeded | 1 | 0 (0) | EmailTemplate:unfiled$public/Warm_Off_5_Deactivation_Notice (Changed) |
| 2026-10-06 12:16 | `0Afdx00000GAhnFCAT` | Validation (check-only) | Succeeded | 5 | 0 (0) |  |
| 2026-10-06 12:19 | `0Afdx00000GAgZSCA1` | Deploy | Succeeded | 5 | 0 (0) | CustomMetadata:Sales_Channel_Cluster.Key_Account_Contact (Changed)<br>CustomMetadata:Sales_Channel_Cluster.Key_Account_Lead (Changed)<br>CustomMetadata:Sales_Channel_Cluster.Key_Account_Opp (Changed)<br>CustomMetadata:Sales_Channel_Cluster.Keys_Account_Account (Changed)<br>CustomMetadata:Sales_Channel_Cluster.Testtwoconditions (Changed) |
| 2026-10-06 12:20 | `0Afdx00000GAgKwCAL` | Validation (check-only) | Succeeded | 2 | 0 (0) |  |
| 2026-10-06 12:22 | `0Afdx00000GAi4zCAD` | Deploy | Succeeded | 2 | 0 (0) | FlexiPage:Account_Company_Record_Page (Changed)<br>FlexiPage:Lead_Record_Page (Changed) |
| 2026-10-06 12:24 | `0Afdx00000GAi8DCAT` | Validation (check-only) | Succeeded | 9 | 0 (0) |  |
| 2026-10-06 12:24 | `0Afdx00000GAiBRCA1` | Validation (check-only) | Failed | 9 | 139 (2) |  |
| 2026-10-06 12:28 | `0Afdx00000GAiL7CAL` | Deploy | Succeeded | 9 | 0 (0) | ApexClass:AccountCascadeHandlerTest (Changed)<br>ApexClass:ClusterRuleEngineTest (Changed)<br>ApexClass:ClusterTriggerTest (Changed)<br>ApexClass:ContactTriggerHandlerTest (Changed)<br>ApexClass:LeadConversionHandlerTest (Changed)<br>ApexClass:LeadConversionHandlerTest1 (Changed)<br>ApexClass:ShopifyAddressSyncTest (Changed)<br>ApexClass:ShopifyOrderSyncTest (Changed)<br>... +1 more (see CSV) |
| 2026-10-06 12:30 | `0Afdx00000GAfwkCAD` | Validation (check-only) | Succeeded | 117 | 0 (0) |  |
| 2026-10-06 12:34 | `0Afdx00000GAijJCAT` | Deploy | Succeeded | 117 | 0 (0) | CustomField:Account_Cluster_Team__mdt.Sales_Channel__c (Changed)<br>CustomMetadata:Account_Cluster_Team.Cluster_1_Account_Manager (Changed)<br>CustomMetadata:Account_Cluster_Team.Cluster_1_Account_Manager_Case (Changed)<br>CustomMetadata:Account_Cluster_Team.Cluster_1_Account_Manager_Contact (Changed)<br>CustomMetadata:Account_Cluster_Team.Cluster_1_Account_Manager_Lead (Changed)<br>CustomMetadata:Account_Cluster_Team.Cluster_1_Account_Manager_Opportunity (Changed)<br>CustomMetadata:Account_Cluster_Team.Cluster_1_Field_Marketing_Opportunity (Changed)<br>CustomMetadata:Account_Cluster_Team.Cluster_1_Field_Marketing_Support (Changed)<br>... +109 more (see CSV) |
| 2026-10-06 12:36 | `0Afdx00000GAio9CAD` | Validation (check-only) | Succeeded | 1 | 0 (0) |  |
| 2026-10-06 12:38 | `0Afdx00000GAizRCAT` | Deploy | Succeeded | 1 | 0 (0) | ApexClass:ShopifyAssociationRetryBatch (Changed) |
| 2026-10-06 12:39 | `0Afdx00000GAj4HCAT` | Validation (check-only) | Succeeded | 8 | 0 (0) |  |
| 2026-10-06 13:03 | `0Afdx00000GAkoLCAT` | Validation (check-only) | Succeeded | 8 | 0 (0) |  |
| 2026-10-06 13:07 | `0Afdx00000GAl4TCAT` | Deploy | Succeeded | 8 | 0 (0) | CustomMetadata:Sales_Channel_Cluster.Specialty_Planned_Account (Created)<br>CustomMetadata:Sales_Channel_Cluster.Specialty_Planned_Contact (Created)<br>CustomMetadata:Sales_Channel_Cluster.Specialty_Planned_Lead (Created)<br>CustomMetadata:Sales_Channel_Cluster.Specialty_Planned_Opp (Created)<br>CustomMetadata:Sales_Channel_Cluster.Specialty_Self_Service_Account (Created)<br>CustomMetadata:Sales_Channel_Cluster.Specialty_Self_Service_Contact (Created)<br>CustomMetadata:Sales_Channel_Cluster.Specialty_Self_Service_Lead (Created)<br>CustomMetadata:Sales_Channel_Cluster.Specialty_Self_Service_Opp (Created) |
| 2026-10-06 13:09 | `0Afdx00000GAihiCAD` | Validation (check-only) | Succeeded | 2 | 0 (0) |  |
| 2026-10-06 14:34 | `0Afdx00000GAp02CAD` | Deploy | Succeeded | 2 | 0 (0) | FlexiPage:Account_Company_Record_Page (Changed)<br>FlexiPage:Lead_Record_Page (Changed) |
| 2026-10-08 11:02 | `0Afdx00000GDWorCAH` | Validation (check-only) | Succeeded | 1 | 0 (0) |  |
| 2026-10-08 11:10 | `0Afdx00000GDSZyCAP` | Deploy | Succeeded | 1 | 0 (0) | Flow:Lead_From_US_Retailer_Form_Assignment_And_Email (Changed) |
| 2026-10-08 11:11 | `0Afdx00000GDX1lCAH` | Validation (check-only) | Succeeded | 2 | 13 (0) |  |
| 2026-10-08 11:15 | `0Afdx00000GDXEfCAP` | Deploy | Succeeded | 2 | 0 (0) | ApexClass:LeadConversionHandlerTest1 (Changed)<br>ApexClass:ShopifyAssociationSyncSchedulableTest (Changed) |
| 2026-10-08 11:19 | `0Afdx00000GDXWPCA5` | Validation (check-only) | Succeeded | 2 | 0 (0) |  |
| 2026-10-08 11:28 | `0Afdx00000GDXrNCAX` | Deploy | Succeeded | 2 | 0 (0) | Report:Cluster3/Shopify_Accounts_CANSource_Cluster_3_Abw (Changed)<br>Report:Cluster3/Shopify_Accounts_Created_CAN_Cluster_3_k2J (Changed) |
| 2026-10-08 15:49 | `0Afdx00000GDn9lCAD` | Deploy | Succeeded | 4 | 105 (0) | ApexClass:BackfillLastShopifyOrderDateTest (Created)<br>ApexClass:ShopifyAtRiskNoticeBatchTest (Changed)<br>ApexClass:ShopifyOrderSyncTest (Changed)<br>ApexClass:ShopifyR12SalesTest (Changed) |
| 2026-10-09 09:49 | `0Afdx00000GEnxJCAT` | Validation (check-only) | Succeeded | 3 | 0 (0) |  |
| 2026-10-09 09:49 | `0Afdx00000GEjosCAD` | Deploy | Succeeded | 3 | 0 (0) | CustomField:Account.Sales_Channel_V1__c (Created)<br>CustomField:Account.Sector_V1__c (Created)<br>Profile:Admin (Changed) |
| 2026-10-09 09:56 | `0Afdx00000GEo8bCAD` | Validation (check-only) | Failed | 2 | 0 (0) |  |
| 2026-10-09 10:00 | `0Afdx00000GEoJtCAL` | Validation (check-only) | Succeeded | 2 | 0 (0) |  |
| 2026-10-09 10:01 | `0Afdx00000GEoLVCA1` | Validation (check-only) | Failed | 0 | 0 (0) |  |
| 2026-10-09 10:03 | `0Afdx00000GEoOjCAL` | Deploy | Succeeded | 2 | 0 (0) | FlexiPage:Account_Franchise_Record_Page1 (Changed)<br>FlexiPage:Account_Store_Location_Record_Page1 (Changed) |
| 2026-10-09 10:10 | `0Afdx00000GEoi5CAD` | Validation (check-only) | Failed | 0 | 0 (0) |  |
| 2026-10-09 10:10 | `0Afdx00000GEojhCAD` | Validation (check-only) | Failed | 0 | 0 (0) |  |
| 2026-10-09 10:11 | `0Afdx00000GEmQBCA1` | Validation (check-only) | Succeeded | 1 | 0 (0) |  |
| 2026-10-09 10:14 | `0Afdx00000GEoq9CAD` | Validation (check-only) | Succeeded | 1 | 0 (0) |  |
| 2026-10-09 10:15 | `0Afdx00000GEotNCAT` | Deploy | Succeeded | 1 | 0 (0) | FlexiPage:Account_Company_Record_Page (Changed) |
| 2026-10-09 10:17 | `0Afdx00000GEoyDCAT` | Validation (check-only) | Succeeded | 1 | 0 (0) |  |
| 2026-10-09 10:20 | `0Afdx00000GEp9VCAT` | Deploy | Succeeded | 1 | 0 (0) | FlexiPage:Lead_Record_Page (Changed) |
| 2026-10-09 10:30 | `0Afdx00000GEpUTCA1` | Validation (check-only) | Succeeded | 5 | 119 (0) |  |
| 2026-10-09 10:34 | `0Afdx00000GEpsfCAD` | Deploy | Succeeded | 5 | 0 (0) | ApexClass:AccountCascadeHandler (Changed)<br>ApexClass:AccountCascadeHandlerTest (Changed)<br>ApexClass:ClusterRuleEngine (Changed)<br>ApexClass:ClusterRuleEngineTest (Changed)<br>ApexClass:LeadConversionHandler (Changed) |

### Setup changes by day (Setup Audit Trail)

#### 2026-08-03  (16 entries)

- **Apex Class**: 15 changes (e.g. Changed LeadTriggerHandler Apex Class code ...). Full list in CSV.
- 16:51 **Certificate and Key Management**: Created Certificate Netsuite M2M

#### 2026-08-04  (48 entries)

- **Apex Class**: 34 changes (e.g. Deleted ContactTriggerHelperTest Apex Class code ...). Full list in CSV.
- 11:30 **Security Controls**: Remote Proxy insert NetSuite_JWT_Signer_Site: https://netsuite-signer-abc123.vercel.app
- 12:08 **Manage Users**: Created permission set External Credential Principal Access: with no license
- 12:10 **Manage Users**: Deleted permission set External Credential Principal Access
- 12:57 **Manage Users**: For user sandipp@goodr.com.partial, the User Verified Email status changed to verified
- 14:27 **Manage Users**: Created permission set NetSuite Integration Access: with no license
- 14:28 **Manage Users**: Changed permission set NetSuite Integration Access: Netsuite_Sync - NetSuite_Integration_User External Credential principal access was enabled
- 14:30 **Manage Users**: Permission set NetSuite Integration Access: assigned to user Ruben Smith (UserID: [005Pn00000F2aQ9])
- 14:49 **Manage Users**: For user sandipp@goodr.com.partial, the User Verified Email status changed to verified
- 13:12 **Named Credentials**: Created a new named credential: NetSuite_JWT_Signer
- 13:12 **Named Credentials**: Created a new parameter: Url (Parameter Type: URL, Parameter Value: https://netsuitesigner-xyz123.vercel.app) for NetSuite_JWT_Signer
- 13:12 **Named Credentials**: Created a new parameter: ExternalCredential (Parameter Type: Authentication, External Credential: Netsuite_Sync) for NetSuite_JWT_Signer
- 16:46 **Certificate and Key Management**: Deleted Certificate netsuite_m2m
- 16:47 **Certificate and Key Management**: Deleted Certificate Netsuite M2M
- 16:47 **Certificate and Key Management**: Created Certificate Netsuite M2M

#### 2026-08-05  (115 entries)

- **Apex Class**: 110 changes (e.g. Changed ShopifyAssociationSyncQueueableTest Apex Class code ...). Full list in CSV.
- 12:43 **Files Connect Settings**: Files Connect external objects now use search interface similar to custom objects.
- 12:44 **Manage Users**: Created permission set File Connect: with User License Salesforce
- 12:45 **Manage Users**: Changed permission set File Connect: Files Connect Cloud permission was changed from disabled to enabled
- 12:46 **Manage Users**: Permission set File Connect: assigned to user Ruben Smith (UserID: [005Pn00000F2aQ9])
- 14:54 **Manage Users**: For user sandipp@goodr.com.partial, the User Verified Email status changed to verified

#### 2026-08-06  (74 entries)

- **Apex Class**: 36 changes (e.g. Created AutomatedTaskTriggerHandler Apex Class code ...). Full list in CSV.
- 13:32 **Apex Trigger**: Created Task Trigger code: AutomatedTaskTrigger
- 13:33 **Apex Trigger**: Changed Task Trigger code: AutomatedTaskTrigger
- **Custom Metadata Types**: 24 changes (e.g. Created custom metadata type: NetSuite_Config__mdt ...). Full list in CSV.
- 18:55 **NetSuite_Config__mdt**: Client Id was created
- 18:56 **NetSuite_Config__mdt**: Certificate Id was created
- 18:56 **NetSuite_Config__mdt**: Account Id was created
- 18:56 **NetSuite_Config__mdt**: Scope was created
- 19:00 **NetSuite_Config__mdt**: Private Key was created
- 19:00 **NetSuite_Config__mdt**: Account Id was deleted
- 19:00 **NetSuite_Config__mdt**: Certificate Id was deleted
- 19:01 **NetSuite_Config__mdt**: Client Id was deleted
- 19:01 **NetSuite_Config__mdt**: Private Key was deleted
- 19:01 **NetSuite_Config__mdt**: Scope was deleted
- 19:07 **NetSuite_Config__mdt**: Default_Config was created
- 19:14 **NetSuite_Config**: Default Config was created

#### 2026-08-07  (31 entries)

- **Apex Class**: 31 changes (e.g. Changed NetSuiteProductSyncBatchTest Apex Class code ...). Full list in CSV.

#### 2026-08-10  (6 entries)

- 12:38 **Apex Class**: Changed AccountTriggerHelperTest Apex Class code
- 12:53 **Apex Class**: Changed AccountTriggerHandler Apex Class code
- 12:57 **Apex Class**: Changed AccountTriggerHelperTest Apex Class code
- 13:09 **Apex Class**: Changed AccountTriggerHelperTest Apex Class code
- 13:22 **Apex Class**: Changed AccountTriggerHelperTest Apex Class code
- 13:28 **Apex Class**: Changed AccountTriggerHelperTest Apex Class code

#### 2026-08-14  (8 entries)

- 09:30 **Customize Leads**: Created custom field: Shopify Created (Checkbox)
- 09:32 **Customize Leads**: Created custom field: Shopify Created Date (Date/Time)
- 09:35 **Apex Class**: Changed LeadConversionService Apex Class code
- 09:43 **Flows**: Created flow version #4 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_email_based_on_US_And_Canada_Retailer"
- 09:43 **Flows**: Activated flow version #4 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_email_based_on_US_And_Canada_Retailer"
- 09:43 **Flows**: Deactivated flow version #3 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_email_based_on_US_And_Canada_Retailer"
- 17:22 **Flows**: Created flow with Name "Send Rejection Email on account rejection" and Unique Name "Send_Rejection_Email_on_account_rejection"
- 17:23 **Inbound Change Sets**: Deployed Change Set: Approval and Rejection Email

#### 2026-08-17  (4 entries)

- 11:40 **Flows**: Activated flow with Name "Send Rejection Email on account rejection" and Unique Name "Send_Rejection_Email_on_account_rejection"
- 18:00 **Manage Users**: For user sandipp@goodr.com.partial, the User Verified Email status changed to verified
- 18:00 **Manage Users**: Temporary verification code "Salesforce generated code" added for integrations@goodr.com
- 18:00 ****: Built-In Authenticator credential 0modx00000018wP with nickname "Built-In Authenticator #1 2026-08-17T12:30:11Z" added for sandipp@goodr.com

#### 2026-08-18  (1 entries)

- 15:41 **Manage Users**: Temporary verification code "Salesforce generated code" added for sandipp@goodr.com

#### 2026-08-19  (1 entries)

- 02:37 ****: Built-In Authenticator credential 0modx0000001Dpd with nickname "Built-In Authenticator #2 2026-08-18T21:06:42Z" added for sandipp@goodr.com

#### 2026-08-20  (2 entries)

- 16:05 **Manage Users**: Temporary verification code "Salesforce generated code" added for sandipp@goodr.com
- 16:05 ****: Built-In Authenticator credential 0modx0000001GM5 with nickname "Built-In Authenticator #3 2026-08-20T10:35:37Z" added for sandipp@goodr.com

#### 2026-08-21  (72 entries)

- **Custom Metadata Types**: 13 changes (e.g. Created custom metadata type: Shopify At Risk Config ...). Full list in CSV.
- 12:14 **Customize Accounts**: Created custom field: At Risk Since (Date)
- 12:15 **Customize Accounts**: Created custom field: At Risk Episode Count (Number)
- 13:24 **Customize Accounts**: Created roll up summary field: Total Notices Sent (count)
- 13:25 **Customize Accounts**: Created roll up summary field: Open Notices (count)
- 13:40 **Customize Accounts**: Changed Account page layout Store Layout
- 12:19 **Customize Contacts**: Created custom formula field: Store At Risk (Checkbox)
- 12:19 **Customize Contacts**: Changed Contact page layout Contact Layout
- 12:21 **Customize Contacts**: Created custom formula field: Store Is Location (Checkbox)
- 12:21 **Customize Contacts**: Changed Contact page layout Contact Layout
- 12:19 **Lightning Pages**: Changed Lightning Page: Contact Record Page
- 12:19 **Lightning Pages**: Changed Lightning Page: Contact Record Page - Three Column
- 12:21 **Lightning Pages**: Changed Lightning Page: Contact Record Page - Three Column
- 12:21 **Lightning Pages**: Changed Lightning Page: Contact Record Page
- 13:38 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 13:39 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 13:42 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- **Custom Objects**: 40 changes (e.g. Created custom object: Shopify At Risk Notice ...). Full list in CSV.
- 12:25 **Custom Tabs**: Created custom object tab: Shopify At Risk Notice
- 13:42 **Custom Tabs**: Changed style of Shopify At Risk Notice custom object tab from Sack to Trophy
- 12:59 **Shopify At Risk Config**: Default was created

#### 2026-08-24  (24 entries)

- 10:50 **Shopify At Risk Config**: Default: Email Template Name has changed from null to Shopify At Risk Notice
- 11:31 **Shopify At Risk Config**: Default: Org Wide Email has changed from null to retailsupportuat@goodr.com
- 11:31 **Shopify At Risk Config**: Default: Active has changed from 0 to 1
- 10:54 **Apex Class**: Created ShopifyAtRiskNoticeBatch Apex Class code
- 10:54 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 10:55 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 12:40 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 11:06 **Flows**: Created flow with Name "Set At Risk Dates on Store Location" and Unique Name "Set_At_Risk_Dates_on_Store_Location"
- 11:12 **Flows**: Created flow version #1 "Set At Risk Dates on Store Location" for flow with Unique Name "Set_At_Risk_Dates_on_Store_Location"
- 11:12 **Flows**: Deleted flow version #-1 "Set At Risk Dates on Store Location" for flow with Unique Name "Set_At_Risk_Dates_on_Store_Location"
- 11:13 **Flows**: Created flow version #1 "Set At Risk Dates on Store Location" for flow with Unique Name "Set_At_Risk_Dates_on_Store_Location"
- 11:13 **Flows**: Deleted flow version #-1 "Set At Risk Dates on Store Location" for flow with Unique Name "Set_At_Risk_Dates_on_Store_Location"
- 11:16 **Flows**: Activated flow with Name "Set At Risk Dates on Store Location" and Unique Name "Set_At_Risk_Dates_on_Store_Location"
- 11:22 **Flows**: Created flow with Name "Send Shopify At Risk Notice" and Unique Name "Send_Shopify_At_Risk_Notice"
- 11:31 **Flows**: Created flow version #1 "Send Shopify At Risk Notice" for flow with Unique Name "Send_Shopify_At_Risk_Notice"
- 11:31 **Flows**: Deleted flow version #-1 "Send Shopify At Risk Notice" for flow with Unique Name "Send_Shopify_At_Risk_Notice"
- 11:32 **Flows**: Activated flow with Name "Send Shopify At Risk Notice" and Unique Name "Send_Shopify_At_Risk_Notice"
- 11:15 **Customize Accounts**: Changed default value for At Risk Episode Count custom field from null to 0
- 12:57 **Lightning Pages**: Created Lightning Page: Shopify At Risk Notice Record Page
- 12:58 **Lightning Pages**: Changed Lightning Page: Shopify At Risk Notice Record Page
- 12:57 **Custom Objects**: Added standard button override on Shopify At Risk Notice: View (Lightning Page null)
- 12:57 **Custom Objects**: Added standard button override on Shopify At Risk Notice: View (Lightning Page null)
- 13:00 **Custom Objects**: Created custom formula field Store Name (Text) on Shopify At Risk Notice
- 13:00 **Custom Objects**: Changed Shopify At Risk Notice page layout Shopify At Risk Notice Layout

#### 2026-08-25  (15 entries)

- 11:29 **Flows**: Deactivated flow with Name "Send Shopify At Risk Notice" and Unique Name "Send_Shopify_At_Risk_Notice"
- 11:30 **Flows**: Activated flow with Name "Send Shopify At Risk Notice" and Unique Name "Send_Shopify_At_Risk_Notice"
- 11:37 **Customize Accounts**: Added value Store At Risk to Offboarding Reason picklist with color Assigned dynamically
- 11:43 **Custom Metadata Types**: Created custom field Auto Offboard (Checkbox) on Shopify At Risk Config
- 11:43 **Custom Metadata Types**: Changed Shopify At Risk Config page layout Shopify At Risk Config Layout
- 11:44 **Custom Metadata Types**: Created custom field Offboard Reason (Text) on Shopify At Risk Config
- 11:44 **Custom Metadata Types**: Changed Shopify At Risk Config page layout Shopify At Risk Config Layout
- 11:45 **Custom Metadata Types**: Created custom field Offboard Owner Username (Text) on Shopify At Risk Config
- 11:45 **Custom Metadata Types**: Changed Shopify At Risk Config page layout Shopify At Risk Config Layout
- 11:47 **Shopify At Risk Config**: Default: Offboard Reason has changed from null to Store At Risk
- 11:47 **Shopify At Risk Config**: Default: Offboard Owner Username has changed from null to kaylanewby@goodr.com.partial
- 12:30 **Shopify At Risk Config**: Default: Auto Offboard has changed from 0 to 1
- 11:53 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 12:00 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 12:48 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code

#### 2026-09-01  (2 entries)

- 13:23 **Manage Users**: Temporary verification code "Salesforce generated code" added for sandipp@goodr.com
- 13:25 ****: Built-In Authenticator credential 0modx0000001UC9 with nickname "Built-In Authenticator #4 2026-09-01T07:54:51Z" added for sandipp@goodr.com

#### 2026-09-09  (3 entries)

- 11:07 **Apex Class**: Created CaseReopenHandlerTest Apex Class code
- 11:07 **Apex Class**: Changed CaseReopenHandlerTest Apex Class code
- 11:09 **Apex Class**: Changed CaseReopenHandlerTest Apex Class code

#### 2026-09-11  (8 entries)

- 10:28 **Apex Class**: Changed ShopifyR12SalesService Apex Class code
- 10:33 **Apex Class**: Changed ShopifyR12SalesBatch Apex Class code
- 12:42 **Apex Class**: Changed ShopifyR12SalesTest Apex Class code
- 11:25 **Customize Accounts**: Changed help text of TY R12 Sales custom field
- 11:26 **Customize Accounts**: Changed help text of YTD of sales custom field
- 11:26 **Customize Accounts**: Changed help text of R12 Sales Decline Ratio custom field
- 11:27 **Customize Accounts**: Changed help text of R12 Sales Performance Percent custom field
- 11:41 **Customize Accounts**: Changed help text of YTD of sales custom field

#### 2026-09-15  (22 entries)

- 11:05 **Apex Class**: Changed CaseReopenHandler Apex Class code
- 11:06 **Apex Class**: Changed CaseReopenHandlerTest Apex Class code
- 11:15 **Apex Class**: Changed CaseReopenHandler Apex Class code
- 11:15 **Apex Class**: Changed CaseReopenHandlerTest Apex Class code
- 11:37 **Apex Class**: Changed CaseReopenHandler Apex Class code
- 11:37 **Apex Class**: Changed CaseReopenHandlerTest Apex Class code
- 11:50 **Apex Class**: Changed CaseReopenHandler Apex Class code
- 11:57 **Apex Class**: Changed CaseReopenHandlerTest Apex Class code
- 12:27 **Apex Class**: Changed ShopifyR12SalesService Apex Class code
- 12:27 **Apex Class**: Changed ShopifyR12SalesBatch Apex Class code
- 12:30 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 12:21 **Customize Accounts**: Created custom field: Current YTD Sales (Currency)
- 12:22 **Customize Accounts**: Created custom field: Prior YTD Sales (Currency)
- 12:23 **Customize Accounts**: Created custom field: YTD Performance Percent (Percent)
- 19:53 **Customize Accounts**: Changed help text of TY R12 Sales custom field
- 19:54 **Customize Accounts**: Changed help text of YTD of sales custom field
- 19:54 **Customize Accounts**: Changed help text of R12 Sales Decline Ratio custom field
- 19:55 **Customize Accounts**: Changed help text of R12 Sales Performance Percent custom field
- 19:56 **Customize Accounts**: Changed help text of Current YTD Sales custom field
- 19:57 **Customize Accounts**: Changed help text of Prior YTD Sales custom field
- 12:29 **Custom Objects**: Created custom field Prior YTD Sales At Notice (Currency) on Shopify At Risk Notice
- 12:29 **Custom Objects**: Changed Shopify At Risk Notice page layout Shopify At Risk Notice Layout

#### 2026-09-16  (5 entries)

- 10:45 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 11:34 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 11:00 **Apex Class**: Changed ShopifyR12SalesService Apex Class code
- 11:01 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 11:07 **Shopify At Risk Config**: Default: Auto Offboard has changed from 1 to 0

#### 2026-09-24  (7 entries)

- 12:25 **Customize Accounts**: Changed label of custom field from TY R12 Sales to Rolling 12 Month Sales
- 12:26 **Customize Accounts**: Changed label of custom field from YTD of sales to Prior Rolling 12 Month Sales
- 12:55 **Flows**: Created flow with Name "Create At Risk Task for Account Owner" and Unique Name "Create_At_Risk_Task_for_Account_Owner"
- 12:58 **Flows**: Created flow version #1 "Create At Risk Task for Account Owner" for flow with Unique Name "Create_At_Risk_Task_for_Account_Owner"
- 12:58 **Flows**: Deleted flow version #-1 "Create At Risk Task for Account Owner" for flow with Unique Name "Create_At_Risk_Task_for_Account_Owner"
- 13:03 **Flows**: Activated flow with Name "Create At Risk Task for Account Owner" and Unique Name "Create_At_Risk_Task_for_Account_Owner"
- 14:41 **Manage Users**: Temporary verification code "Salesforce generated code" added for sandipp@goodr.com

#### 2026-09-25  (19 entries)

- 12:36 **Customize Accounts**: Created custom field: Last Shopify Order Sync Date (Date)
- 14:33 **Customize Accounts**: Created custom formula field: Months Since Last Order (Number)
- 14:35 **Customize Accounts**: Created custom formula field: Scheduled Deactivation Date (Date)
- 12:44 **Apex Class**: Changed ShopifyOrderSyncService Apex Class code
- 12:44 **Apex Class**: Changed ShopifyOrderSyncBatch Apex Class code
- 12:45 **Apex Class**: Created BackfillLastShopifyOrderDate Apex Class code
- 12:45 **Apex Class**: Changed BackfillLastShopifyOrderDate Apex Class code
- 12:51 **Apex Class**: Changed ShopifyOrderSyncBatch Apex Class code
- 13:03 **Apex Class**: Changed BackfillLastShopifyOrderDate Apex Class code
- 13:03 **Apex Class**: Changed ShopifyOrderSyncService Apex Class code
- 13:03 **Apex Class**: Changed ShopifyOrderSyncBatch Apex Class code
- 14:38 **Custom Objects**: Created custom field Stage (Picklist) on Shopify At Risk Notice
- 14:38 **Custom Objects**: Changed Shopify At Risk Notice page layout Shopify At Risk Notice Layout
- 14:39 **Custom Objects**: Created custom field Months Inactive At Notice (Number) on Shopify At Risk Notice
- 14:39 **Custom Objects**: Changed Shopify At Risk Notice page layout Shopify At Risk Notice Layout
- 14:40 **Custom Objects**: Created custom field Last Order Date At Notice (Date) on Shopify At Risk Notice
- 14:40 **Custom Objects**: Changed Shopify At Risk Notice page layout Shopify At Risk Notice Layout
- 14:44 **Lightning Pages**: Changed Lightning Page: Shopify At Risk Notice Record Page
- 14:45 **Lightning Pages**: Changed Lightning Page: Shopify At Risk Notice Record Page

#### 2026-09-28  (64 entries)

- 11:05 **Custom Objects**: Created custom field Deactivation Date (Date) on Shopify At Risk Notice
- 11:05 **Custom Objects**: Changed Shopify At Risk Notice page layout Shopify At Risk Notice Layout
- 13:12 **Custom Objects**: Changed formula of Offboard Due Date custom field on Shopify At Risk Notice from "IF( ISBLANK(Notice_Date__c), null, Notice_Date__c + $CustomMetadata.Shopify_At_Risk_Config__mdt.Default.Offboard_Days__c )" to "IF(ISPICKVAL(Stage__c, ""), Notice_Date__c + $CustomMetadata.Shopify_At_Risk_Config__mdt.D
- 14:17 **Custom Objects**: Added value Send Failed to Status picklist with color Assigned dynamically on Shopify At Risk Notice
- 14:20 **Custom Objects**: Organization setup action: changedCFUniqueOnCustom has changed from Notice Key to Shopify At Risk Notice
- 11:34 **Global Value Sets**: Added value Enterprise to Sector picklist with color Assigned dynamically
- 11:34 **Global Value Sets**: Added value Strategic to Sector picklist with color Assigned dynamically
- 11:34 **Global Value Sets**: Added value Development to Sector picklist with color Assigned dynamically
- 11:34 **Global Value Sets**: Added value Discount to Sector picklist with color Assigned dynamically
- 11:34 **Global Value Sets**: Added value Planned to Sector picklist with color Assigned dynamically
- 11:34 **Global Value Sets**: Added value Self Service to Sector picklist with color Assigned dynamically
- 11:34 **Global Value Sets**: Added value Distributor to Sector picklist with color Assigned dynamically
- 11:41 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sales Channel" on object Lead
- 11:42 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sales Channel" on object Account
- 11:43 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sales Channel" on object Contact
- 11:44 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sales Channel" on object Opportunity
- 13:08 **Customize Accounts**: Created custom formula field: Inactivity Stage (Text)
- 14:20 **Company Information**: Created external identifier designation: Shopify_At_Risk_Notice.Notice Key
- **Custom Metadata Types**: 26 changes (e.g. Created custom field Template Stage 1 (Text) on Shopify At Risk Config ...). Full list in CSV.
- 14:34 **Shopify At Risk Config**: Default: Template Stage 1 has changed from null to Warm Off 1 - Check In
- 14:34 **Shopify At Risk Config**: Default: Template Stage 2 has changed from null to Warm Off 2 - Early Notice
- 14:34 **Shopify At Risk Config**: Default: Template Stage 3 has changed from null to Warm Off 3 - 30 Day Warning
- 14:34 **Shopify At Risk Config**: Default: Template Stage 4 has changed from null to Warm Off 4 - 15 Day Reminder
- 14:34 **Shopify At Risk Config**: Default: Template Stage 5 has changed from null to Warm Off 5 - Deactivation Notice
- 14:34 **Shopify At Risk Config**: Default: At Risk Mode has changed from null to Every Stage
- 14:34 **Shopify At Risk Config**: Default: Reminder Days has changed from null to 15
- 14:34 **Shopify At Risk Config**: Default: Deactivation Months has changed from null to 18
- 14:34 **Shopify At Risk Config**: Default: Test Store Name Filter has changed from null to R12%
- 14:53 **Shopify At Risk Config**: Default: Auto Offboard has changed from 0 to 1
- 15:02 **Shopify At Risk Config**: Default: Auto Offboard has changed from 1 to 0
- 14:49 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 14:50 **Apex Class**: Created ShopifyAtRiskNoticeBatchTest Apex Class code
- 14:51 **Apex Class**: Created SendWarmOffEmail Apex Class code
- 14:51 **Apex Class**: Changed SendWarmOffEmail Apex Class code
- 14:51 **Apex Class**: Changed ShopifyAtRiskNoticeBatchTest Apex Class code
- 14:51 **Apex Class**: Changed ShopifyAtRiskNoticeBatchTest Apex Class code
- 15:27 **Flows**: Created flow version #2 "Send Shopify At Risk Notice" for flow with Unique Name "Send_Shopify_At_Risk_Notice"
- 15:27 **Flows**: Activated flow version #2 "Send Shopify At Risk Notice" for flow with Unique Name "Send_Shopify_At_Risk_Notice"
- 15:27 **Flows**: Deactivated flow version #1 "Send Shopify At Risk Notice" for flow with Unique Name "Send_Shopify_At_Risk_Notice"

#### 2026-09-29  (8 entries)

- 11:35 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 11:43 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 11:50 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 12:12 **Apex Class**: Created WarmOffTest Apex Class code
- 12:30 **Apex Class**: Deleted WarmOffTest Apex Class code
- 12:32 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 13:13 **Shopify At Risk Config**: Default: Test Store Name Filter has changed from R12% to R12 WO A%
- 14:17 **Shopify At Risk Config**: Default: Auto Offboard has changed from 0 to 1

#### 2026-09-30  (21 entries)

- 11:15 **Shopify At Risk Config**: Default: Auto Offboard has changed from 1 to 0
- 11:15 **Shopify At Risk Config**: Default: Test Store Name Filter has changed from R12 WO A% to R12 WOT%
- 11:36 **Shopify At Risk Config**: Default: Auto Offboard has changed from 0 to 1
- 11:38 **Shopify At Risk Config**: Default: Auto Offboard has changed from 1 to 0
- 12:54 **Shopify At Risk Config**: Default: Auto Offboard has changed from 0 to 1
- 12:50 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 12:50 **Apex Class**: Changed ShopifyAtRiskNoticeBatchTest Apex Class code
- 12:50 **Apex Class**: Changed ShopifyAtRiskNoticeBatchTest Apex Class code
- 13:33 **Apex Class**: Changed ShopifyAtRiskNoticeBatch Apex Class code
- 12:53 **Custom Objects**: Changed formula of Offboard Due Date custom field on Shopify At Risk Notice from "IF(ISPICKVAL(Stage__c, ""), Notice_Date__c + $CustomMetadata.Shopify_At_Risk_Config__mdt.Default.Offboard_Days__c, Deactivation_Date__c)" to "IF(ISPICKVAL(Stage__c, ""), Notice_Date__c + $CustomMetadata.Shopify_At_Risk
- 12:53 **Custom Objects**: Deleted custom field Offboard Due Date from Shopify At Risk Notice
- 12:54 **Custom Metadata Types**: Deleted custom field Offboard Days from Shopify At Risk Config
- 13:41 **Customize Accounts**: Changed formula of Scheduled Deactivation Date custom field from "Last_Shopify_Order_Date__c + 548" to "ADDMONTHS(Last_Shopify_Order_Date__c, 18)"
- 13:42 **Customize Accounts**: Changed formula of Inactivity Stage custom field from "IF(ISBLANK(Last_Shopify_Order_Date__c), "Never Ordered", IF(Last_Shopify_Order_Date__c <= TODAY() - 548, "Month 18", IF(Last_Shopify_Order_Date__c <= TODAY() - 517, "Month 17", IF(Last_Shopify_Order_Date__c <= TODAY() - 456, "Month 15", IF(Last_
- 15:03 **Track Field History**: Track History for Account field Last Shopify Order Date on
- 15:03 **Track Field History**: Track History for Account field Shopify Ordering Enabled on
- 15:03 **Track Field History**: Track History for Account field Shopify Sales At Risk on
- 15:03 **Track Field History**: Track History for Account field YTD Performance Percent on
- 15:03 **Track Field History**: Track History for Account field Vertical off
- 15:03 **Track Field History**: Track History for Account field Sport / Category off
- 15:03 **Track Field History**: Track History for Account field Website off

#### 2026-10-01  (5 entries)

- 10:52 **Shopify At Risk Config**: Default: Auto Offboard has changed from 1 to 0
- 10:53 **Shopify At Risk Config**: Default: Auto Offboard has changed from 0 to 1
- 11:54 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 12:05 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 12:09 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page

#### 2026-10-05  (5 entries)

- 12:28 **Customize Accounts**: Created custom field: Order Channel (Picklist)
- 12:29 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 12:30 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 12:31 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 12:32 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page

#### 2026-10-06  (149 entries)

- 10:45 **Global Value Sets**: Changed Sales Channel picklist value from Key Accounts to Key Account
- 10:45 **Global Value Sets**: Changed Sales Channel picklist value's API name from Key Accounts to Key Account
- 10:46 **Global Value Sets**: Changed Sales Channel1 picklist value from Key Accounts to Key Account
- 10:46 **Global Value Sets**: Changed Sales Channel1 picklist value's API name from Key Accounts to Key Account
- **Sales Channel Clusters**: 13 changes (e.g. Key Account - Contact: Rule Condition has changed from Sales_Channel__c = 'Key Accounts' to Sales_Channel__c = 'Key Acco ...). Full list in CSV.
- 12:22 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 12:22 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 14:34 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 14:34 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 12:28 **Apex Class**: Changed AccountCascadeHandlerTest Apex Class code
- 12:28 **Apex Class**: Changed ClusterRuleEngineTest Apex Class code
- 12:28 **Apex Class**: Changed ClusterTriggerTest Apex Class code
- 12:28 **Apex Class**: Changed ContactTriggerHandlerTest Apex Class code
- 12:28 **Apex Class**: Changed LeadConversionHandlerTest Apex Class code
- 12:28 **Apex Class**: Changed LeadConversionHandlerTest1 Apex Class code
- 12:28 **Apex Class**: Changed ShopifyAddressSyncTest Apex Class code
- 12:28 **Apex Class**: Changed ShopifyOrderSyncTest Apex Class code
- 12:28 **Apex Class**: Changed ShopifySalesSyncServiceTest Apex Class code
- 12:38 **Apex Class**: Changed ShopifyAssociationRetryBatch Apex Class code
- 12:34 **Custom Objects**: Added value Key Account to Sales Channel picklist with color Assigned dynamically on Account Cluster Teams
- 12:34 **Custom Objects**: Reordered Sales Channel picklist on Account Cluster Teams
- **Account Cluster Teams**: 116 changes (e.g. Cluster 1 Account Manager: Sales Channel has changed from Key Accounts to Key Account ...). Full list in CSV.

#### 2026-10-07  (1 entries)

- 12:38 **Lightning Pages**: Changed Lightning Page: Account Company Record Page

#### 2026-10-08  (29 entries)

- 11:10 **Flows**: Created flow version #4 "Lead From TypeForm Form Assignment And Email" for flow with Unique Name "Lead_From_US_Retailer_Form_Assignment_And_Email"
- 11:10 **Flows**: Activated flow version #4 "Lead From TypeForm Form Assignment And Email" for flow with Unique Name "Lead_From_US_Retailer_Form_Assignment_And_Email"
- 11:10 **Flows**: Deactivated flow version #3 "Lead From TypeForm Form Assignment And Email" for flow with Unique Name "Lead_From_US_Retailer_Form_Assignment_And_Email"
- 11:16 **Apex Class**: Changed LeadConversionHandlerTest1 Apex Class code
- 11:16 **Apex Class**: Changed ShopifyAssociationSyncSchedulableTest Apex Class code
- 15:49 **Apex Class**: Created BackfillLastShopifyOrderDateTest Apex Class code
- 15:49 **Apex Class**: Changed ShopifyAtRiskNoticeBatchTest Apex Class code
- 15:49 **Apex Class**: Changed ShopifyOrderSyncTest Apex Class code
- 15:49 **Apex Class**: Changed ShopifyR12SalesTest Apex Class code
- 12:07 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sector" on object Account
- 12:07 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sector" on object Contact
- 12:07 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sector" on object Opportunity
- 18:35 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sector" on object Account
- 18:35 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sector" on object Contact
- 18:35 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sector" on object Opportunity
- 18:36 **Field Dependencies**: Updated dependency rules for "Sector" controlled by "Sector" on object Lead
- **Global Value Sets**: 13 changes (e.g. Deactivated value Specialty CAN from Sales Channel picklist with color Assigned dynamically ...). Full list in CSV.

#### 2026-10-09  (14 entries)

- 09:49 **Customize Accounts**: Created custom field: Sales Channel V1 (Text)
- 09:49 **Customize Accounts**: Created custom field: Sector V1 (Text)
- 09:49 **Manage Users**: Changed profile System Administrator: field-level security for Account: Sector V1 was changed from No Access to Read/Write
- 09:49 **Manage Users**: Changed profile System Administrator: field-level security for Account: Sales Channel V1 was changed from No Access to Read/Write
- 23:04 **Manage Users**: Temporary verification code "Salesforce generated code" added for integrations@goodr.com
- 10:03 **Lightning Pages**: Changed Lightning Page: Account Franchise Record Page
- 10:03 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 10:15 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 10:20 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 10:34 **Apex Class**: Changed AccountCascadeHandler Apex Class code
- 10:34 **Apex Class**: Changed AccountCascadeHandlerTest Apex Class code
- 10:34 **Apex Class**: Changed ClusterRuleEngine Apex Class code
- 10:34 **Apex Class**: Changed ClusterRuleEngineTest Apex Class code
- 10:34 **Apex Class**: Changed LeadConversionHandler Apex Class code

## GDRPROD

Deploys: 31 (succeeded 29) Â· validations: 41 Â· Setup Audit Trail entries: 246

### Deploys and validations

| Date | Deploy ID | Type | Status | Components | Tests (errors) | Components deployed |
|---|---|---|---|---|---|---|
| 2026-08-05 12:51 | `0AfPn000002A5EzKAK` | Validation (check-only) | Failed | 22 | 0 (0) |  |
| 2026-08-05 13:09 | `0AfPn000002A5N3KAK` | Validation (check-only) | Succeeded | 25 | 16 (0) |  |
| 2026-08-05 13:11 | `0AfPn000002A5OfKAK` | Deploy | Succeeded | 25 | 16 (0) | ApexClass:LeadConversionService (Changed)<br>ApexClass:LeadConversionServiceTest (No change)<br>ApexClass:ShopifyConfigService (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>... +17 more (see CSV) |
| 2026-08-05 13:15 | `0AfPn000002A5RtKAK` | Validation (check-only) | Succeeded | 24 | 20 (0) |  |
| 2026-08-05 13:16 | `0AfPn000002A5TVKA0` | Deploy | Succeeded | 24 | 20 (0) | ApexClass:ShopifyAccountIntegration (Changed)<br>ApexClass:ShopifyAccountIntegrationTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 13:26 | `0AfPn000002A5YLKA0` | Validation (check-only) | Failed | 23 | 0 (0) |  |
| 2026-08-05 13:36 | `0AfPn000002A5gPKAS` | Validation (check-only) | Failed | 22 | 0 (0) |  |
| 2026-08-05 15:21 | `0AfPn000002A69RKAS` | Validation (check-only) | Succeeded | 24 | 4 (0) |  |
| 2026-08-05 15:21 | `0AfPn000002A6B3KAK` | Deploy | Succeeded | 24 | 4 (0) | ApexClass:AccountContactRelationHandler (Changed)<br>ApexClass:AccountContactRelationHandlerTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 15:26 | `0AfPn000002A6CfKAK` | Validation (check-only) | Failed | 23 | 0 (0) |  |
| 2026-08-05 15:46 | `0AfPn000002A6PZKA0` | Validation (check-only) | Succeeded | 24 | 15 (0) |  |
| 2026-08-05 15:47 | `0AfPn000002A6SnKAK` | Deploy | Succeeded | 24 | 15 (0) | ApexClass:AccountTriggerHandler (Changed)<br>ApexClass:AccountTriggerHelperTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 15:50 | `0AfPn000002A6ZFKA0` | Validation (check-only) | Succeeded | 24 | 36 (0) |  |
| 2026-08-05 15:53 | `0AfPn000002A6cTKAS` | Deploy | Succeeded | 24 | 36 (0) | ApexClass:ContactTriggerHandler (Changed)<br>ApexClass:ContactTriggerHandlerTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:03 | `0AfPn000002A6m9KAC` | Validation (check-only) | Failed | 24 | 6 (0) |  |
| 2026-08-05 16:06 | `0AfPn000002A6pNKAS` | Validation (check-only) | Succeeded | 24 | 12 (0) |  |
| 2026-08-05 16:07 | `0AfPn000002A6qzKAC` | Deploy | Succeeded | 24 | 12 (0) | ApexClass:ShopifyManualAssociationQueueable (Changed)<br>ApexClass:ShopifyManualAssociationQueueableTest (No change)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:10 | `0AfPn000002A6sbKAC` | Validation (check-only) | Succeeded | 24 | 24 (0) |  |
| 2026-08-05 16:11 | `0AfPn000002A6uDKAS` | Deploy | Succeeded | 24 | 24 (0) | ApexClass:ShopifyAssociationIntegration (Changed)<br>ApexClass:ShopifyAssociationIntegrationTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:14 | `0AfPn000002A6vpKAC` | Validation (check-only) | Succeeded | 24 | 4 (0) |  |
| 2026-08-05 16:15 | `0AfPn000002A6xRKAS` | Deploy | Succeeded | 24 | 4 (0) | ApexClass:ShopifyAssociationSyncSchedulable (Changed)<br>ApexClass:ShopifyAssociationSyncSchedulableTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:18 | `0AfPn000002A6z3KAC` | Validation (check-only) | Succeeded | 24 | 19 (0) |  |
| 2026-08-05 16:21 | `0AfPn000002A73tKAC` | Deploy | Succeeded | 24 | 19 (0) | ApexClass:ShopifyActiveStatusPushService (Changed)<br>ApexClass:ShopifyActiveStatusPushServiceTest (No change)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:27 | `0AfPn000002A7ALKA0` | Validation (check-only) | Succeeded | 24 | 17 (0) |  |
| 2026-08-05 16:28 | `0AfPn000002A7BxKAK` | Deploy | Succeeded | 24 | 17 (0) | ApexClass:ShopifyAddressSyncService (Changed)<br>ApexClass:ShopifyAddressSyncTest (No change)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:31 | `0AfPn000002A7FBKA0` | Validation (check-only) | Succeeded | 24 | 9 (0) |  |
| 2026-08-05 16:32 | `0AfPn000002A7GnKAK` | Deploy | Succeeded | 24 | 9 (0) | ApexClass:ShopifyAssociationSyncQueueable (Changed)<br>ApexClass:ShopifyAssociationSyncQueueableTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:36 | `0AfPn000002A7IPKA0` | Validation (check-only) | Succeeded | 24 | 15 (0) |  |
| 2026-08-05 16:37 | `0AfPn000002A7K1KAK` | Deploy | Succeeded | 24 | 15 (0) | ApexClass:ShopifyContactIntegration (Changed)<br>ApexClass:ShopifyContactIntegrationTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:40 | `0AfPn000002A7LdKAK` | Validation (check-only) | Failed | 24 | 23 (1) |  |
| 2026-08-05 16:44 | `0AfPn000002A7OrKAK` | Validation (check-only) | Succeeded | 24 | 23 (0) |  |
| 2026-08-05 16:45 | `0AfPn000002A7QTKA0` | Deploy | Succeeded | 24 | 23 (0) | ApexClass:ShopifyOrderSyncService (Changed)<br>ApexClass:ShopifyOrderSyncTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 16:48 | `0AfPn000002A7S5KAK` | Validation (check-only) | Succeeded | 24 | 23 (0) |  |
| 2026-08-05 16:49 | `0AfPn000002A7ThKAK` | Deploy | Succeeded | 24 | 23 (0) |  |
| 2026-08-05 16:54 | `0AfPn000002A7VJKA0` | Validation (check-only) | Succeeded | 25 | 18 (0) |  |
| 2026-08-05 16:54 | `0AfPn000002A7WvKAK` | Deploy | Succeeded | 25 | 18 (0) | ApexClass:ShopifySalesSyncBatch (Changed)<br>ApexClass:ShopifySalesSyncService (Changed)<br>ApexClass:ShopifySalesSyncServiceTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>... +17 more (see CSV) |
| 2026-08-05 16:59 | `0AfPn000002A7blKAC` | Validation (check-only) | Succeeded | 24 | 12 (0) |  |
| 2026-08-05 17:00 | `0AfPn000002A7ezKAC` | Deploy | Succeeded | 24 | 12 (0) | ApexClass:ShopifyStoreLocationManualSyncQTest (Changed)<br>ApexClass:ShopifyStoreLocationManualSyncQueueable (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-05 17:07 | `0AfPn000002A7gbKAC` | Validation (check-only) | Succeeded | 25 | 7 (0) |  |
| 2026-08-05 17:07 | `0AfPn000002A7iDKAS` | Deploy | Succeeded | 25 | 7 (0) | ApexClass:APILogger (No change)<br>ApexClass:APILoggerTest (Changed)<br>ApexClass:ApiLogTriggerHandler (No change)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>... +17 more (see CSV) |
| 2026-08-05 17:11 | `0AfPn000002A7ofKAC` | Validation (check-only) | Failed | 24 | 9 (0) |  |
| 2026-08-05 19:13 | `0AfPn000002A9yXKAS` | Validation (check-only) | Failed | 25 | 48 (0) |  |
| 2026-08-05 19:17 | `0AfPn000002AA3NKAW` | Validation (check-only) | Failed | 24 | 15 (0) |  |
| 2026-08-05 19:21 | `0AfPn000002AA8DKAW` | Validation (check-only) | Succeeded | 24 | 508 (0) |  |
| 2026-08-05 19:30 | `0AfPn000002AAPxKAO` | Deploy | Succeeded | 24 | 508 (0) | ApexClass:ShopifyContactIntegrationTest (No change)<br>ApexClass:ShopifyContactSyncQueueable (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>Profile:CPQ Integration User (No change)<br>... +16 more (see CSV) |
| 2026-08-07 15:24 | `0AfPn000002AiHxKAK` | Validation (check-only) | Failed | 2 | 0 (0) |  |
| 2026-08-07 15:30 | `0AfPn000002AiLBKA0` | Validation (check-only) | Failed | 24 | 0 (0) |  |
| 2026-08-07 15:41 | `0AfPn000002AiMnKAK` | Validation (check-only) | Failed | 32 | 12 (4) |  |
| 2026-08-07 15:47 | `0AfPn000002AiOPKA0` | Validation (check-only) | Failed | 32 | 0 (0) |  |
| 2026-08-07 15:48 | `0AfPn000002AiQ1KAK` | Deploy | Succeeded | 32 | 524 (0) | CustomField:PricebookEntry.NetSuite_Pricebook_Entry_Key__c (Created)<br>CustomField:Product2.NetSuite_Internal_Id__c (Created)<br>CustomField:Product2.NetSuite_Status__c (Created)<br>ApexClass:NetSuiteOAuth2HelperES256 (Created)<br>ApexClass:NetSuiteProductSyncBatch (Created)<br>ApexClass:NetSuiteProductSyncBatchTest (Created)<br>ApexClass:NetSuiteProductWrapper (Created)<br>ApexClass:NetSuiteProductWrapperTest (Created)<br>... +24 more (see CSV) |
| 2026-08-10 13:30 | `0AfPn000002B5RRKA0` | Validation (check-only) | Failed | 9 | 35 (1) |  |
| 2026-08-10 14:16 | `0AfPn000002B5o1KAC` | Validation (check-only) | Succeeded | 29 | 0 (0) |  |
| 2026-08-10 14:16 | `0AfPn000002B5rFKAS` | Deploy | Succeeded | 29 | 0 (0) | CustomField:Account.Active__c (Changed)<br>CustomField:Account.Offboarded_By__c (Created)<br>CustomField:Account.Offboarding_Date__c (Created)<br>CustomField:Account.Offboarding_Notes__c (Created)<br>CustomField:Account.Offboarding_Reason__c (Created)<br>ValidationRule:Account.Require_Offboarding_Reason_And_Notes (Created)<br>Flow:Account_Auto_Populate_Offboarding_Date_and_User (Created)<br>Profile:Account Management (Changed)<br>... +21 more (see CSV) |
| 2026-08-10 14:20 | `0AfPn000002B5uTKAS` | Validation (check-only) | Succeeded | 25 | 36 (0) |  |
| 2026-08-10 14:21 | `0AfPn000002B5w5KAC` | Deploy | Succeeded | 25 | 0 (0) | ApexClass:AccountTriggerHandler (Changed)<br>ApexClass:AccountTriggerHelper (Changed)<br>ApexClass:AccountTriggerHelperTest (Changed)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>... +17 more (see CSV) |
| 2026-08-11 10:55 | `0AfPn000002BN09KAG` | Validation (check-only) | Succeeded | 30 | 102 (0) |  |
| 2026-08-11 10:57 | `0AfPn000002BN1lKAG` | Deploy | Succeeded | 30 | 0 (0) | ApexClass:AccountTriggerHelper (No change)<br>ApexClass:AccountTriggerHelperTest (No change)<br>ApexClass:ContactTriggerHandlerTest (No change)<br>ApexClass:ContactTriggerHelper (Changed)<br>ApexClass:LeadTriggerHandler (Changed)<br>ApexClass:LeadTriggerHandlerTest (Changed)<br>ApexClass:ShopifyAccountIntegration (No change)<br>ApexClass:ShopifyAccountIntegrationTest (No change)<br>... +22 more (see CSV) |
| 2026-08-14 17:24 | `0AfPn000002CCM1KAO` | Validation (check-only) | Succeeded | 26 | 16 (0) |  |
| 2026-08-17 11:39 | `0AfPn000002CTxxKAG` | Deploy | Succeeded | 26 | 0 (0) | CustomField:Lead.Shopify_Created_Date__c (Created)<br>CustomField:Lead.Shopify_Created__c (Created)<br>ApexClass:LeadConversionService (Changed)<br>ApexClass:LeadConversionServiceTest (No change)<br>Profile:Account Management (Changed)<br>Profile:Admin (Changed)<br>Profile:Analytics Cloud Integration User (Changed)<br>Profile:Analytics Cloud Security User (Changed)<br>... +18 more (see CSV) |
| 2026-08-17 12:40 | `0AfPn000002CUArKAO` | Validation (check-only) | Succeeded | 25 | 4 (0) |  |
| 2026-08-17 12:41 | `0AfPn000002CTxyKAG` | Deploy | Succeeded | 25 | 0 (0) | ApexClass:AutomatedTaskTriggerHandler (Created)<br>ApexClass:AutomatedTaskTriggerHandlerTest (Created)<br>ApexTrigger:AutomatedTaskTrigger (Created)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>... +17 more (see CSV) |
| 2026-09-09 11:45 | `0AfPn000002HJMrKAO` | Validation (check-only) | Succeeded | 25 | 4 (0) |  |
| 2026-09-15 10:52 | `0AfPn000002ITnBKAW` | Deploy | Succeeded | 25 | 4 (0) | ApexClass:CaseReopenHandler (Created)<br>ApexClass:CaseReopenHandlerTest (Created)<br>ApexTrigger:CaseReopenOnCustomerReply (Created)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>... +17 more (see CSV) |
| 2026-09-15 11:59 | `0AfPn000002IUWLKA4` | Validation (check-only) | Succeeded | 25 | 12 (0) |  |
| 2026-09-15 12:00 | `0AfPn000002IUZZKA4` | Deploy | Succeeded | 25 | 0 (0) | ApexClass:CaseReopenHandler (Changed)<br>ApexClass:CaseReopenHandlerTest (Changed)<br>ApexTrigger:CaseReopenOnCustomerReply (No change)<br>Profile:Account Management (No change)<br>Profile:Admin (No change)<br>Profile:Analytics Cloud Integration User (No change)<br>Profile:Analytics Cloud Security User (No change)<br>Profile:Anypoint Integration (No change)<br>... +17 more (see CSV) |
| 2026-09-21 12:08 | `0AfPn000002Ja53KAC` | Deploy | Failed | 27 | 0 (0) |  |
| 2026-09-21 12:10 | `0AfPn000002Ja6fKAC` | Deploy | Failed | 56 | 0 (0) |  |
| 2026-09-21 12:18 | `0AfPn000002Ja8HKAS` | Deploy | Succeeded | 59 | 0 (0) | CustomField:Account.Cluster__c (No change)<br>CustomField:Account.Location_Cluster__c (No change)<br>CustomField:Account.Parent_Record__c (No change)<br>CustomField:Case.Business_Hours__c (Created)<br>CustomField:Case.Case_Cluster__c (No change)<br>CustomField:Case.Cluster__c (No change)<br>CustomField:Case.Email_Reply_Received__c (No change)<br>CustomField:Case.Email_Sent__c (No change)<br>... +51 more (see CSV) |
| 2026-09-21 12:24 | `0AfPn000002Ja9tKAC` | Deploy | Succeeded | 37 | 0 (0) | CustomField:Case.Next_Reply_Due_Date__c (No change)<br>CustomField:Case.Requestor_Type__c (No change)<br>CustomField:Case.SLA_Pause_Start__c (No change)<br>CustomField:Case.Survey_Link__c (No change)<br>CustomField:Case.Total_Pause_Hours__c (No change)<br>CustomField:Case.Total_Pause_Millis__c (No change)<br>CustomField:Case.Zendesk_Description__c (No change)<br>CustomField:SurveyInvitation.Case__c (No change)<br>... +29 more (see CSV) |
| 2026-09-21 12:39 | `0AfPn000002JaD7KAK` | Deploy | Succeeded | 40 | 0 (0) | CustomField:Case.Next_Reply_Due_Date__c (No change)<br>CustomField:Case.Requestor_Type__c (No change)<br>CustomField:Case.SLA_Pause_Start__c (No change)<br>CustomField:Case.Survey_Link__c (No change)<br>CustomField:Case.Total_Pause_Hours__c (No change)<br>CustomField:Case.Total_Pause_Millis__c (No change)<br>CustomField:Case.Zendesk_Description__c (No change)<br>CustomField:SurveyInvitation.Case__c (No change)<br>... +32 more (see CSV) |
| 2026-10-07 11:18 | `0AfPn000002N1ALKA0` | Validation (check-only) | Failed | 113 | 0 (0) |  |
| 2026-10-07 11:19 | `0AfPn000002N1BxKAK` | Validation (check-only) | Succeeded | 113 | 17 (0) |  |

### Setup changes by day (Setup Audit Trail)

#### 2026-08-03  (36 entries)

- 10:25 **Flows**: Created flow version #20 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_emails_when_lead_status_changes"
- 10:26 **Flows**: Activated flow version #20 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_emails_when_lead_status_changes"
- 10:54 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 10:54 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 10:55 **Lightning Pages**: Changed Lightning Page: Account Franchise Record Page
- 11:11 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 11:12 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 11:18 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 11:19 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 11:58 **Lightning Pages**: Changed Lightning Page: Account Franchise Record Page
- 12:11 **Inbox mobile and legacy desktop apps**: User Ruben Smith accepted Einstein Activity Capture Terms of Service
- 12:12 **Global Actions**: Changed Action Layout for action: New Lead
- **Manage Users**: 24 changes (e.g. Changed profile Account Management: Email Application page layout for Master record type was changed from Outlook Layout ...). Full list in CSV.

#### 2026-08-05  (58 entries)

- 12:26 **Manage Users**: For user sandipp@goodr.com, the User Verified Email status changed to verified
- **Apex Class**: 39 changes (e.g. Changed LeadConversionService Apex Class code ...). Full list in CSV.
- **Inbound Change Sets**: 18 changes (e.g. Deployed Change Set: LeadConversionService1 ...). Full list in CSV.

#### 2026-08-06  (2 entries)

- 12:11 **Manage Users**: For user sandipp@goodr.com, the User Verified Email status changed to verified
- 12:14 **Certificate and Key Management**: Created Certificate Netsuite M2M

#### 2026-08-07  (29 entries)

- 11:31 **Manage Users**: Logged in using Login-As access for Integrations Integrations
- 15:26 **Custom Metadata Types**: Created custom metadata type: NetSuite_Config
- 15:27 **Custom Metadata Types**: Created custom field Account Id (Text) on NetSuite_Config
- 15:27 **Custom Metadata Types**: Changed NetSuite_Config page layout NetSuite_Config Layout
- 15:27 **Custom Metadata Types**: Created custom field Certificate Id (Text) on NetSuite_Config
- 15:27 **Custom Metadata Types**: Changed NetSuite_Config page layout NetSuite_Config Layout
- 15:27 **Custom Metadata Types**: Created custom field Client Id (Text) on NetSuite_Config
- 15:27 **Custom Metadata Types**: Changed NetSuite_Config page layout NetSuite_Config Layout
- 15:28 **Custom Metadata Types**: Created custom field Private Key (Text) on NetSuite_Config
- 15:28 **Custom Metadata Types**: Changed NetSuite_Config page layout NetSuite_Config Layout
- 15:28 **Custom Metadata Types**: Created custom field Scope (Text) on NetSuite_Config
- 15:28 **Custom Metadata Types**: Changed NetSuite_Config page layout NetSuite_Config Layout
- 15:29 **NetSuite_Config**: Default Config was created
- 15:34 **Custom Objects**: Created custom object: Sync Config
- 15:35 **Custom Objects**: Created custom field Last Sync DateTime (Date/Time) on Sync Config
- 15:46 **Customize Products**: Changed field type of Replen custom field from Picklist to Checkbox
- 15:48 **Customize Products**: Created custom field: NetSuite Internal Id (Text)
- 15:48 **Customize Products**: Created custom field: NetSuite Status (Picklist)
- 15:48 **Named Credentials**: Created a new named credential: NetSuite_Sandbox
- 15:48 ****: Created custom field: NetSuite Pricebook Entry Key (Text)
- 15:48 **Track Field History**: Track History for Product field NetSuite Internal Id on
- 15:48 **Track Field History**: Track History for Product field NetSuite Status on
- 15:48 **Apex Class**: Created NetSuiteOAuth2HelperES256 Apex Class code
- 15:48 **Apex Class**: Created NetSuiteProductSyncBatch Apex Class code
- 15:48 **Apex Class**: Created NetSuiteProductSyncBatchTest Apex Class code
- 15:48 **Apex Class**: Created NetSuiteProductWrapper Apex Class code
- 15:48 **Apex Class**: Created NetSuiteProductWrapperTest Apex Class code
- 15:48 **Apex Class**: Created NetSuiteSyncScheduler Apex Class code
- 15:48 **Inbound Change Sets**: Deployed Change Set: Netsuite - 2

#### 2026-08-10  (17 entries)

- 14:16 **Customize Accounts**: Changed label of custom field from Shopify Active to Shopify Ordering Enabled
- 14:16 **Customize Accounts**: Created custom lookup relationship Offboarded By (User)
- 14:16 **Customize Accounts**: Created custom field: Offboarding Date (Date)
- 14:16 **Customize Accounts**: Created custom field: Offboarding Notes (Text)
- 14:16 **Customize Accounts**: Created custom field: Offboarding Reason (Picklist)
- 14:17 **Validation Rules**: New Accounts validation rule "Require_Offboarding_Reason_And_Notes"
- 14:17 **Flows**: Created flow with Name "Account - Auto-Populate Offboarding Date and User" and Unique Name "Account_Auto_Populate_Offboarding_Date_and_User"
- 16:09 **Flows**: Activated flow with Name "Account - Auto-Populate Offboarding Date and User" and Unique Name "Account_Auto_Populate_Offboarding_Date_and_User"
- 14:17 **Inbound Change Sets**: Deployed Change Set: Shopify Offboarding deployment - v1
- 14:21 **Inbound Change Sets**: Deployed Change Set: Shopify Offboarding classes
- 14:21 **Apex Class**: Changed AccountTriggerHandler Apex Class code
- 14:21 **Apex Class**: Changed AccountTriggerHelper Apex Class code
- 14:21 **Apex Class**: Changed AccountTriggerHelperTest Apex Class code
- 14:24 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 14:24 **Lightning Pages**: Changed Lightning Page: Account Company Record Page
- 14:26 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page
- 14:28 **Lightning Pages**: Changed Lightning Page: Account Store Location Record Page

#### 2026-08-11  (42 entries)

- 10:57 **Apex Class**: Changed AccountTriggerHelper Apex Class code
- 10:57 **Apex Class**: Changed AccountTriggerHelperTest Apex Class code
- 10:57 **Apex Class**: Changed ContactTriggerHandlerTest Apex Class code
- 10:57 **Apex Class**: Changed ContactTriggerHelper Apex Class code
- 10:57 **Apex Class**: Changed LeadTriggerHandler Apex Class code
- 10:57 **Apex Class**: Changed LeadTriggerHandlerTest Apex Class code
- 10:57 **Apex Class**: Changed ShopifyAccountIntegration Apex Class code
- 10:57 **Apex Class**: Changed ShopifyAccountIntegrationTest Apex Class code
- 10:57 **Inbound Change Sets**: Deployed Change Set: Prevention of case creation
- 11:00 **NetSuite_Config**: Default Config: Account Id has changed from null to 5631345
- 11:00 **NetSuite_Config**: Default Config: Certificate Id has changed from null to GFXtrsYtwKGI4KNGst65RHWtQCElqsCeb1ZrcDaar4A
- 11:00 **NetSuite_Config**: Default Config: Client Id has changed from null to 4c704a562ca3197157970c17733ab6c6a1f10d7628d0cd8997ca6fe120aa02c0
- 11:00 **NetSuite_Config**: Default Config: Scope has changed from null to rest_webservices
- 11:02 **Named Credentials**: URL changed for named credential NetSuite_Sandbox from https://5631345-sb2.suitetalk.api.netsuite.com to https://5631345.suitetalk.api.netsuite.com
- 11:04 **Security Controls**: Remote Proxy insert NetSuite_OAuth2_Token_Endpoint: https://5631345.suitetalk.api.netsuite.com
- 12:01 **Track Field History**: Track History for Product field Active on
- 12:01 **Track Field History**: Track History for Product field B2B Launch Date on
- 12:01 **Track Field History**: Track History for Product field Launch Date on
- 12:01 **Track Field History**: Track History for Product field Product Family on
- 12:01 **Track Field History**: Track History for Product field Product SKU on
- 12:01 **Track Field History**: Track History for Product field Product Stage on
- 12:01 **Track Field History**: Track History for Product field Product Type on
- 12:01 **Track Field History**: Track History for Product field Replen on
- 12:07 **Lightning Pages**: Changed Lightning Page: Product Record Page
- 12:07 **Lightning Pages**: Changed Lightning Page: Product Record Page
- 12:13 **Lightning Pages**: Changed Lightning Page: Product Record Page
- 12:13 **Lightning Pages**: Changed Lightning Page: Product Record Page
- 12:14 **Lightning Pages**: Changed Lightning Page: Product Record Page
- 12:14 **Lightning Pages**: Changed Lightning Page: Product Record Page
- **Customize Products**: 13 changes (e.g. Changed Product page layout Product Layout ...). Full list in CSV.

#### 2026-08-17  (14 entries)

- 11:39 **Customize Leads**: Created custom field: Shopify Created Date (Date/Time)
- 11:39 **Customize Leads**: Created custom field: Shopify Created (Checkbox)
- 11:39 **Apex Class**: Changed LeadConversionService Apex Class code
- 11:39 **Apex Class**: Changed LeadConversionServiceTest Apex Class code
- 12:41 **Apex Class**: Created AutomatedTaskTriggerHandler Apex Class code
- 12:41 **Apex Class**: Created AutomatedTaskTriggerHandlerTest Apex Class code
- 11:39 **Inbound Change Sets**: Deployed Change Set: Lead Conversion Service changes
- 12:41 **Inbound Change Sets**: Deployed Change Set: Delete automated Task
- 11:42 **Flows**: Created flow version #21 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_emails_when_lead_status_changes"
- 11:42 **Flows**: Activated flow version #21 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_emails_when_lead_status_changes"
- 11:42 **Flows**: Deactivated flow version #20 "Send Approval email based on US And Canada Retailer" for flow with Unique Name "Send_Approval_Rejection_emails_when_lead_status_changes"
- 11:59 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 11:59 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 12:41 **Apex Trigger**: Created Task Trigger code: AutomatedTaskTrigger

#### 2026-08-18  (3 entries)

- 11:52 **Manage Users**: For user sandipp@goodr.com, the User Verified Email status changed to verified
- 15:43 **Manage Users**: Temporary verification code "Salesforce generated code" added for sandipp@goodr.com
- 11:52 ****: Built-In Authenticator credential 0moPn000000328X with nickname "Built-In Authenticator #1 2026-08-18T06:22:07Z" added for sandipp@goodr.com

#### 2026-08-19  (1 entries)

- 02:38 ****: Built-In Authenticator credential 0moPn00000037cr with nickname "Built-In Authenticator #2 2026-08-18T21:08:15Z" added for sandipp@goodr.com

#### 2026-08-20  (5 entries)

- 16:02 **Manage Users**: Temporary verification code "Salesforce generated code" added for sandipp@goodr.com
- 16:03 ****: Built-In Authenticator credential 0moPn0000003CMP with nickname "Built-In Authenticator #3 2026-08-20T10:33:47Z" added for sandipp@goodr.com
- 20:46 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 20:47 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 20:47 **Lightning Pages**: Changed Lightning Page: Lead Record Page

#### 2026-08-21  (6 entries)

- 11:50 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 11:51 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 11:55 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 11:59 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 11:59 **Lightning Pages**: Changed Lightning Page: Lead Record Page
- 12:04 **Lightning Pages**: Changed Lightning Page: Lead Record Page

#### 2026-09-01  (7 entries)

- 11:26 **Manage Users**: Changed profile Account Management: Email Message page layout for Master record type was changed from Not Assigned to Email Message Layout
- 11:26 **Manage Users**: Changed profile Service Supervisor: Email Message page layout for Master record type was changed from Not Assigned to Email Message Layout
- 11:26 **Manage Users**: Changed profile Service Agent: Email Message page layout for Master record type was changed from Not Assigned to Email Message Layout
- 11:26 **Manage Users**: Changed profile Minimum Access - API Only Integrations: Email Message page layout for Master record type was changed from Not Assigned to Email Message Layout
- 11:26 **Manage Users**: Changed profile Minimum Access - Salesforce: Email Message page layout for Master record type was changed from Not Assigned to Email Message Layout
- 13:26 **Manage Users**: Temporary verification code "Salesforce generated code" added for sandipp@goodr.com
- 13:27 ****: Built-In Authenticator credential 0moPn0000003cf3 with nickname "Built-In Authenticator #4 2026-09-01T07:57:28Z" added for sandipp@goodr.com

#### 2026-09-04  (8 entries)

- 22:48 **Manage Users**: Unlocked user integrations@goodr.com (UserID: [005fL000003TmvZ])
- 22:49 **Manage Users**: Created permission set Use Any API Auth PS: with no license
- 22:50 **Manage Users**: Changed permission set Use Any API Auth PS: Use Any API Auth permission was changed from disabled to enabled
- 22:51 **Manage Users**: Permission set Use Any API Auth PS: assigned to user Insights Integration (UserID: [005fL000003CzUD])
- 22:51 **Manage Users**: Permission set Use Any API Auth PS: assigned to user Integration User (UserID: [005Pn00000WscjD])
- 22:51 **Manage Users**: Permission set Use Any API Auth PS: assigned to user Integrations Integrations (UserID: [005fL000003TmvZ])
- 22:51 **Manage Users**: Permission set Use Any API Auth PS: assigned to user SalesforceIQ Integration (UserID: [005Pn00000V205J])
- 22:51 **Manage Users**: Permission set Use Any API Auth PS: assigned to user Klaviyo Integration (UserID: [005Pn00000UVycz])

#### 2026-09-09  (1 entries)

- 11:44 **Customize Cases**: Added value Reopened to Case Status picklist with color Assigned dynamically

#### 2026-09-15  (8 entries)

- 10:52 **Apex Class**: Created CaseReopenHandler Apex Class code
- 10:52 **Apex Class**: Created CaseReopenHandlerTest Apex Class code
- 12:00 **Apex Class**: Changed CaseReopenHandler Apex Class code
- 12:00 **Apex Class**: Changed CaseReopenHandlerTest Apex Class code
- 10:52 **Apex Trigger**: Created Email Message Trigger code: CaseReopenOnCustomerReply
- 12:00 **Apex Trigger**: Changed Email Message Trigger code: CaseReopenOnCustomerReply
- 10:52 **Inbound Change Sets**: Deployed Change Set: Case Reopen
- 12:00 **Inbound Change Sets**: Deployed Change Set: Case Reopen

#### 2026-09-21  (6 entries)

- 12:18 **Customize Cases**: Created custom field: Business Hours (Number)
- 12:18 **Customize Cases**: Created custom field: Requestor Type (Picklist)
- 12:18 **Customize Cases**: Created custom formula field: Total Pause Hours (Number)
- 12:18 **Inbound Change Sets**: Deployed Change Set: Report Type
- 12:24 **Inbound Change Sets**: Deployed Change Set: CSAT Reports
- 12:39 **Inbound Change Sets**: Deployed Change Set: CSAT Dashboard

#### 2026-10-06  (1 entries)

- 11:48 **Global Value Sets**: Changed Sales Channel picklist value from Key Accounts to Key Account

#### 2026-10-08  (1 entries)

- 15:08 **Lightning Pages**: Changed Lightning Page: Case Record

#### 2026-10-12  (1 entries)

- 12:59 ****: Organization setup action: showDeveloperConsoleWithWebIdeOffOn has changed.

