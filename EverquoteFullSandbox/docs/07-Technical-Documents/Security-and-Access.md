# Security and Access

Source: `force-app/main/default/profiles` (2) and `force-app/main/default/permissionsets` (111).

All counts below are from the retrieved XML. A retrieve only includes permissions for components that were part of the same retrieve, so counts may be lower than in the org. "Objects (R/C/E)" is the number of objects with Read, Create or Edit; "Delete" is the number with Delete. "Notable system perms" lists only high-impact user permissions, including ModifyAllData, ViewAllData, AuthorApex, ModifyMetadata, ManageUsers, CustomizeApplication, BulkApiHardDelete and TransferAnyEntity.

## Profiles

| Profile | License | Objects (R/C/E) / Delete | Modify All objects | FLS entries / editable | Apex classes enabled | VF pages enabled | Apps visible | Record types visible | User perms enabled | Notable system perms |
|---|---|---|---|---|---|---|---|---|---|---|
| Admin (System Administrator) | Salesforce | 553 / 553 | 553 | 5036 / 4332 | 1268 | 242 | 50 | 59 | 234 | ModifyAllData, ViewAllData, AuthorApex, ModifyMetadata, CustomizeApplication, ManageUsers, ManageProfilesPermissionsets, AssignPermissionSets, InstallPackaging, TransferAnyEntity, ExportReport, ResetPasswords |
| EQ Cross-Functional | Salesforce | 552 / 546 | 66 | 5036 / 4332 | 1268 | 242 | 50 | 59 | 229 | **No** ModifyAllData / ViewAllData, but has AuthorApex, ModifyMetadata, CustomizeApplication, ManageUsers, ManageInternalUsers, ManageProfilesPermissionsets, AssignPermissionSets, ManageRoles, ManageSharing, ResetPasswords, TransferAnyEntity, ExportReport |

> **EQ Cross-Functional is effectively an admin profile.** It can edit metadata, write Apex, manage users and assign permission sets, and a user with those rights can grant themselves Modify All Data. Review who has it.

## Permission sets: risk overview

| Group | Count | Comment |
|---|---|---|
| A. Modify All Data | 7 | `Classic_Access`, `Lightning_and_Classic_View`, `Permission_for_merging_leads`, `Pro_Permission`, `PS_Ops_Full_Data`, `Service_Cloud_Admin`, `Temp_Modify_all_to_download_Dataloader`. Several have **misleading names** for admin-level access (e.g. "Classic Access", "Lightning and Classic View", "Permission for merging leads"). |
| B. View All Data / read-all | 4 | `Developer_Console_Permissions` and `View_All_Data` (ViewAllData); `PS_Read_All_Objects` (View All on 553 objects); `sfdcInternalInt__sfdc_a360_sfcrm_data_extract` (Data Cloud connector, View All on 487 objects) |
| C. Hard delete | 3 | `Bulk_API_Hard_Delete`, `Hard_Delete`, `Temp_Delete_Master_Accounts` (the last also has Modify All on 94 objects) |
| D. Setup / user admin | 5 | `PS_IT_User_Admin` (AuthorApex, ModifyMetadata, ManageUsers...), `Customize_app`, `Customize_Application`, `edit_quota_on_user_record`, `Messaging_SMS_Admin` |
| E. Service Cloud / Voice / Messaging / Knowledge | 14 | Contact center, Omni, chat, SMS and Knowledge sets |
| F. Salesforce internal integration (`sfdcInternalInt__`) | 5 (+1 in B) | Salesforce-managed integration sets ("Cloud Integration User" license, activation required) |
| G. Sales Engagement | 3 | `SalesCloudUnlimitedPsl` license sets plus `PS_Sales_Cadence_Member` |
| H. Targeted object / field grants | 32 | Mostly single-field edit grants and small object grants |
| I. Feature / user-permission toggles | 23 | Single user permissions (Run Flows, Transfer, list views, MFA, SSO...) |
| J. Empty in retrieved metadata | 15 | No object, field, class, page or user permissions in the XML |

Other prefixes and packages:
- `jrsl_ul_Unsubscribe_Link` comes from the Salesforce Labs "Unsubscribe Link" unmanaged package.
- No other managed-package namespaces have permission sets in source, although DupeDive, Gong, DocuSign (`dsfs`/`dfsle`), Handwrytten and Delighted objects appear in object permissions.
- "Temp"/"Temporary" sets still in source: `Temp_Change_Opp_Owner`, `Temp_Delete_Master_Accounts`, `Temp_Modify_all_to_download_Dataloader`, `Temporary_Approve_Leads`, `Account_Support`, `Customize_Application`. These should be reviewed and removed if no longer needed.

## Permission sets: detail (grouped)

People's names in descriptions or API names are redacted as `[name]`. License is blank where the XML has none, which means no license restriction.

### A. Modify All Data (admin-equivalent) - 7

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Classic_Access | Classic Access | Salesforce | 537 / 531 | 527 | 0 | 0 / 0 | 0 | 0 | 58 | AssignPermissionSets, ConvertLeads, CustomizeApplication, DelegatedTwoFactor, ImportLeads, ManageCustomPermissions, ManageInternalUsers, ManageProfilesPermissionsets, ManageRoles, ManageSharing, ManageTranslation, ManageUsers, ModifyAllData, ModifyMetadata, ResetPasswords, RunReports, TransferAnyEntity, TransferAnyLead, ViewAllData, ViewAllForecasts, ViewAllUsers, ViewSetup |  |
| Lightning_and_Classic_View | Lightning and Classic View |  | 537 / 531 | 527 | 0 | 0 / 0 | 0 | 0 | 58 | AssignPermissionSets, ConvertLeads, CustomizeApplication, DelegatedTwoFactor, ImportLeads, ManageCustomPermissions, ManageInternalUsers, ManageProfilesPermissionsets, ManageRoles, ManageSharing, ManageTranslation, ManageUsers, ModifyAllData, ModifyMetadata, ResetPasswords, RunReports, TransferAnyEntity, TransferAnyLead, ViewAllData, ViewAllForecasts, ViewAllUsers, ViewSetup |  |
| Permission_for_merging_leads | Permission for merging leads | Salesforce | 537 / 531 | 527 | 0 | 0 / 0 | 0 | 0 | 42 | ConvertLeads, ImportLeads, ManageTranslation, ModifyAllData, ModifyMetadata, RunReports, TransferAnyEntity, TransferAnyLead, ViewAllData, ViewAllForecasts, ViewSetup | For [names] |
| Pro_Permission | Pro Permission | Salesforce | 537 / 531 | 527 | 0 | 0 / 0 | 0 | 0 | 42 | ConvertLeads, ImportLeads, ManageTranslation, ModifyAllData, ModifyMetadata, RunReports, TransferAnyEntity, TransferAnyLead, ViewAllData, ViewAllForecasts, ViewSetup | Modify All and Customize set up |
| PS_Ops_Full_Data | PS_Ops_Full_Data |  | 537 / 531 | 527 | 0 | 4738 / 4271 | 0 | 0 | 231 | ApiEnabled, AssignPermissionSets, AuthorApex, ConvertLeads, CustomizeApplication, DelegatedTwoFactor, EditReadonlyFields, ExportReport, ImportLeads, InstallPackaging, ManageAnalyticSnapshots, ManageCases, ManageCustomPermissions, ManageDataIntegrations, ManageInternalUsers, ManageLeads, ManageProfilesPermissionsets, ManageRoles, ManageSharing, ManageTranslation, ManageUsers, MassInlineEdit, ModifyAllData, ModifyAllPolicyCenterPolicies, ModifyMetadata, ResetPasswords, RunReports, ScheduleReports, TransferAnyCase, TransferAnyEntity, TransferAnyLead, ViewAllData, ViewAllForecasts, ViewAllUsers, ViewSetup | C/R/E/D + View All + Modify All on every object. Manage Public List Views = ON. |
| Service_Cloud_Admin | Service Cloud Admin |  | 537 / 531 | 527 | 0 | 0 / 0 | 0 | 0 | 42 | ConvertLeads, ImportLeads, ManageTranslation, ModifyAllData, ModifyMetadata, RunReports, TransferAnyEntity, TransferAnyLead, ViewAllData, ViewAllForecasts, ViewSetup | Admin set of permissions to setup and configure service cloud |
| Temp_Modify_all_to_download_Dataloader | Temp Modify all to download Dataloader | Salesforce | 537 / 531 | 527 | 0 | 0 / 0 | 0 | 0 | 42 | ApiEnabled, ConvertLeads, ImportLeads, ManageTranslation, ModifyAllData, ModifyMetadata, RunReports, TransferAnyEntity, TransferAnyLead, ViewAllData, ViewAllForecasts, ViewSetup |  |

### B. View All Data / read-all - 4

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Developer_Console_Permissions | Developer Console Permissions | Salesforce | 216 / 0 | 0 | 206 | 0 / 0 | 0 | 0 | 9 | ApiEnabled, ViewAllData, ViewAllForecasts, ViewSetup | View All and API enabled |
| PS_Read_All_Objects | PS_Read_All_Objects |  | 553 / 0 | 0 | 553 | 0 / 0 | 0 | 0 | 0 |  | Read + View All on every object. No Create/Edit/Delete/Modify All. |
| sfdcInternalInt__sfdc_a360_sfcrm_data_extract | Data Cloud Salesforce Connector | Cloud Integration User | 497 / 0 | 0 | 487 | 6 / 0 | 0 | 0 | 10 | ViewAllActivities, ViewAllForecasts | Allows object and field access for ingestion to Data Cloud. |
| View_All_Data | View All Data | Salesforce | 247 / 0 | 0 | 237 | 0 / 0 | 0 | 0 | 9 | ViewAllData, ViewAllForecasts, ViewSetup |  |

### C. Hard delete - 3

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Bulk_API_Hard_Delete | Bulk API Hard Delete |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 | BulkApiHardDelete | Should not be assigned except in special, temporary, circumstances where an Admin needs to mass hard delete data. S3P-11... |
| Hard_Delete | Hard Delete | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 | BulkApiHardDelete |  |
| Temp_Delete_Master_Accounts | Temp Delete Master Accounts | Salesforce | 98 / 98 | 94 | 0 | 0 / 0 | 0 | 0 | 27 | BulkApiHardDelete, ConvertLeads, ImportLeads, RunReports, TransferAnyEntity, TransferAnyLead, ViewAllForecasts |  |

### D. Setup / user administration - 5

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Customize_app | Customize app | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 4 | CustomizeApplication, ManageCustomPermissions, ViewSetup | Give to [name] for hoopla admin |
| Customize_Application | Customize Application | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 4 | CustomizeApplication, ManageCustomPermissions, ViewSetup | Temporary access to support specific needs like web to lead |
| edit_quota_on_user_record | edit quota on user record | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 3 | ManageInternalUsers, ViewSetup |  |
| Messaging_SMS_Admin | Messaging SMS Admin |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 10 | CustomizeApplication, ManageCustomPermissions, ViewSetup |  |
| PS_IT_User_Admin | PS_IT_User_Admin |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 22 | AssignPermissionSets, AuthorApex, DelegatedTwoFactor, ManageInternalUsers, ManageProfilesPermissionsets, ManageRoles, ManageSharing, ManageUsers, ModifyMetadata, ResetPasswords, ViewAllUsers, ViewSetup | Manage Users, Reset Passwords, Manage MFA, Manage Auth Settings (SSO), View Setup, View Event Log Files, Manage Login Ac... |

### E. Service Cloud / Voice / Messaging / Knowledge - 14

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Contact_Center_Agent_with_Recording_Control | Contact Center Agent with Recording Control | ServiceCloudVoiceExternalTelephonyPsl | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 3 |  | Access agent features in Service Cloud Voice contact centers that use your preferred telephony provider. Allows agents t... |
| Help_Center_Curator | Help Center Curator |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 5 |  | Permissions needed to create and manage a customer-facing help center |
| Knowledge_LSF_Permission_Set | Knowledge LSF Permission Set |  | 1 / 1 | 1 | 0 | 0 / 0 | 0 | 0 | 4 |  | Grants CRUD permission for Knowledge, as well as Knowledge user permissions. |
| Knowledge_Manager_981601 | Knowledge Manager |  | 1 / 1 | 0 | 0 | 4 / 4 | 0 | 0 | 11 |  | Knowledge Manager Permission Set |
| Live_Agent_Setup_Flow | Chat Setup Flow |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Messaging_Session_View_All | Messaging Session View All |  | 2 / 0 | 0 | 2 | 0 / 0 | 0 | 0 | 0 |  |  |
| Messaging_SMS_User | Messaging SMS User |  | 2 / 0 | 0 | 2 | 7 / 7 | 0 | 0 | 5 |  |  |
| Omni_Setup_Flow | Omni Setup Flow |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| OmniPresenceStatusPermissionSet | Omni Presence Status for Service Messaging with Messaging for In-App and Web |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Access to presence statuses to indicate availability to work with Messaging on Omni-Channel. |
| PartnerTelephonyCustomPsl | Partner Telephony Permission Set | ServiceCloudVoiceExternalTelephonyPsl | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Permission Set to access Partner Telephony Connected Apps and Service Presence |
| Service_Chat | Service Routing: Chat |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | View and manage all routed Chat sessions. |
| Service_Console_Permissions | Service Console Permissions | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Support team permissions for service console usage |
| Service_Console_Permissions_Sales | Service Console Permissions (Sales) | Salesforce | 1 / 1 | 0 | 0 | 0 / 0 | 0 | 0 | 5 |  | Support team permissions for service console usage |
| Service_Console_Permissions_Tester | Service Console Permissions Tester | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Test set for support team permissions for service console usage |

### F. Salesforce internal integration (sfdcInternalInt__ namespace) - 5

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| sfdcInternalInt__sfdc_a360 | Customer 360 Data Platform Integration | Cloud Integration User | 6 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 2 | ViewAllActivities | Allows access to enable Customer 360 Data Platform to properly function. |
| sfdcInternalInt__sfdc_activityplatform | sfdc.activityplatform | Cloud Integration User | 2 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 4 | ViewAllUsers | Permset for the 'sfdc.activityplatform' C2C integration |
| sfdcInternalInt__sfdc_nc_constraints_engine_deploy | Constraint Rules Engine Licenseless permission set | Cloud Integration User | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Create and manage constraint types and rules in Advanced Configurator. |
| sfdcInternalInt__sfdc_scrt2 | SCRT2 Integration User | Cloud Integration User | 1 / 0 | 0 | 1 | 0 / 0 | 0 | 0 | 0 |  | Give SCRT2 Integration User necessary access |
| sfdcInternalInt__sfdc_searchqna | Search QnA | Cloud Integration User | 160 / 2 | 0 | 2 | 5 / 0 | 0 | 0 | 9 | ApiEnabled, ModifyMetadata, ViewSetup | Search QnA Permission Set |

### G. Sales Engagement / Cadences - 3

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| HighVelocitySalesCadenceCreatorIncluded | Sales Engagement Cadence Creator Included v2 | SalesCloudUnlimitedPsl | 2 / 1 | 0 | 0 | 0 / 0 | 0 | 0 | 10 |  | Lets sales manager users access the Sales Engagement app, and create and edit Cadences. |
| PS_Sales_Cadence_Member | PS_Sales_Cadence_Member |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Sales_Engagement_User_EverQuote | Sales Engagement User EverQuote | SalesCloudUnlimitedPsl | 2 / 1 | 0 | 0 | 0 / 0 | 0 | 0 | 10 |  | Lets users access the Sales Engagement app, add buyers to Cadences, and contact them via Work Queue. |

### H. Targeted object / field grants - 32

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Access_Other_peoples_opportunities | Delete opps | Salesforce | 2 / 2 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Also delete cases and opps |
| Account_Lead_Excluded_from_Marketing_Services_R_E | Account/Lead - Excluded from Marketing Services - R/E |  | 0 / 0 | 0 | 0 | 2 / 2 | 0 | 0 | 0 |  | Gives Edit access to the "Excluded from Marketing Services" field on Accounts and Leads. Should only be given to limited... |
| Account_Support | Account Support | Salesforce | 1 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Temporary permission set to show new record types, page layout and field for case - account support |
| AGP_pass_up_flag | AGP pass up flag | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  | Allow sales managers to edit this field for commission purposes |
| BI_Fields_editable_for_Customer_Success_Manager_during_comp_review | BI Fields editable for Customer Success Manager during comp review | Salesforce | 0 / 0 | 0 | 0 | 3 / 3 | 0 | 0 | 0 |  |  |
| BI_Validation_Fields | BI Validation Fields | Salesforce | 0 / 0 | 0 | 0 | 25 / 0 | 0 | 0 | 0 |  | The ability to view and edit BI Validation Fieds |
| Cockpit_Integration_Object_Access | Cockpit Integration Object Access |  | 7 / 0 | 0 | 1 | 1832 / 1781 | 0 | 0 | 1 |  | Object permissions for the Cockpit Integration User |
| Core_IO_Managers_access_to_edit_sales_rep_on_the_opportunity | Core IO Managers access to edit sales rep on the opportunity | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| Delete_for_Lead_Contact_Oppty_and_Account_to_enable_these_users_to_merge_recs | Delete for Lead, Contact, Oppty and Account to enable these users to merge recs | Salesforce | 3 / 3 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Edit_Influential_Agent_Checkbox | Edit Influential Agent Checkbox | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| Edit_Opportunities | Edit Opportunities |  | 1 / 1 | 1 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Edit_Reports_and_Dashboards | Edit Reports and Dashboards | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 7 |  |  |
| Edit_Support_rep_on_Oppty | Edit Support rep on Oppty | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| First_Payment_Date | First Payment Date |  | 4 / 2 | 0 | 0 | 2 / 2 | 0 | 0 | 0 |  |  |
| Grant_access_just_to_type | Grant access just to type | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| Grant_access_to_account_fields_type_and_support_rep | Grant access to account fields - type and support rep | Salesforce | 0 / 0 | 0 | 0 | 2 / 2 | 0 | 0 | 0 |  |  |
| Grant_opportunity_delete_privileges | Grant opportunity delete privileges | Salesforce | 1 / 1 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Intro_Call_Finalized_Date_edit_access_to_CSM_managers | Intro Call Finalized Date - edit access to CSM managers | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| Intro_Completed_Date | Intro Completed Date | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  | For CS managers |
| IO_Attached_Permission | IO Attached Permission |  | 1 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| IO_checkbox_permission_set | IO checkbox permission set | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| Key_Account_Management | Key Account Management | Salesforce | 3 / 0 | 0 | 3 | 7 / 7 | 0 | 0 | 0 |  | Permissions for key account management that allow them to edit/create/view all carriers, promos,  and promo codes. They ... |
| Manager_of_Customer_Success | Manager of Customer Success | Salesforce | 9 / 2 | 0 | 2 | 44 / 26 | 0 | 0 | 15 | ExportReport, MassInlineEdit, RunReports, ScheduleReports, TransferAnyEntity, ViewAllUsers |  |
| Merge_Leads_for_[name] | Merge Leads for [name] | Salesforce | 1 / 1 | 0 | 1 | 0 / 0 | 0 | 0 | 0 |  | Delete on Leads |
| Needs_merging_edit_access | Needs merging edit access | Salesforce | 0 / 0 | 0 | 0 | 1 / 1 | 0 | 0 | 0 |  |  |
| Slack_permission_set | Slack permission set | Salesforce | 1 / 0 | 0 | 0 | 15 / 0 | 0 | 0 | 0 |  |  |
| Temp_Change_Opp_Owner | Temp Change Opp Owner | Salesforce | 1 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 | TransferAnyEntity |  |
| Transfer_Leads | Transfer Leads | Salesforce | 1 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 | TransferAnyLead |  |
| Typeform_Integration_User_Object_Access | Typeform Integration User Object Access |  | 1 / 1 | 1 | 0 | 8 / 8 | 0 | 0 | 0 |  | Grants the Typeform Integration User Create / Read / Update / View All / Modify All permission on the following objects:... |
| View_All_Forecasts | View All Forecasts | Salesforce | 1 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 | ViewAllForecasts |  |
| VP_of_Customer_Success | VP of Customer Success | Salesforce | 8 / 1 | 0 | 5 | 91 / 87 | 0 | 0 | 19 | ExportReport, ManageCases, MassInlineEdit, RunReports, ScheduleReports, TransferAnyCase, TransferAnyEntity, ViewAllUsers |  |
| VP_of_Sales | VP of Sales | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 11 | 1 | 1 |  | Allow access to the Edit Quotas tab along with normal EverQuote Manager access. |

### I. Feature / user-permission toggles - 23

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Accelerated_State_Farm | Accelerated State Farm | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | To grant [name] access to the accelerated record type for opps |
| Create_Dashboards | Create Dashboards | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 8 |  | Originally for [name] |
| Create_edit_views | Create/edit views | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  | For people to create their own views/ list of accounts, contacts, opportunities, leads, or cases. |
| Dashboard_and_Report_Access | Dashboard and Report Access |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 7 | RunReports |  |
| Delete_List_Views | Delete List Views | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 2 |  |  |
| Email_Template_Builder | Email Template Builder |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  | Give access to the drag and drop content builder for email templates |
| EverQuote_Sales_Cloud_Console | EverQuote Sales Cloud Console | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Grant_access_to_create_list_views | Grant access to create PUBLIC list views |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 2 |  | This is just for managers |
| Hide_Classic | Hide Classic | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 2 |  |  |
| ISR_create_public_views | ISR create public views | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  |  |
| jrsl_ul_Unsubscribe_Link | Unsubscribe Link |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 1 | 0 |  | Permissions needed with unmanaged package Unsubscribe Link from Salesforce Labs. |
| Lightning_Experience_Access | Lightning Experience Access | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 6 | RunReports |  |
| Lightning_User_Experience | Lightning User Experience | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  |  |
| Magic_MOVER | Magic MOVER | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  |  |
| MFA_Permission_Set | MFA Permission Set | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  |  |
| Multi_Factor | Multi Factor | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  |  |
| PS_Manage_Public_List_Views | PS_Manage_Public_List_Views |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 2 |  | Manage Public List Views only |
| PS_View_Setup | PS_View_Setup |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 2 | ViewSetup | View Setup and Configuration only. |
| Public_List_Views_for_Managers | Public List Views for Managers | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 25 | RunReports, ScheduleReports |  |
| Run_Flows | Run Flows |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  | Gives the Salesforce Run_Flows permission. Should only be assigned to the Typeform Integration user. |
| SSO_Enabled_Permission_Set | SSO-Enabled-Permission-Set | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  | Permission Set to enable SSO for EverQuote Users |
| transfer_record | transfer record | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 | TransferAnyEntity |  |
| View_and_Edit_Converted_Leads | View and Edit Converted Leads |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 1 |  |  |

### J. No permissions in retrieved metadata - 15

| API name | Label | License | Objects (R/C/E) / Delete | Modify All objs | View All objs | FLS entries / editable | Apex classes | VF pages | User perms enabled | Notable system perms | Description |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Affiliate_Developer | Affiliate Developer | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | Permission Set generated for access to custom object Traffic Partner for the app Affiliate |
| BDR_Create_Leads_Without_Approval | BDR Create Leads Without Approval | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Delegate_administrator | Delegate administrator |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Disable_MFA | Disable MFA |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Disable_View_All_Forecast | Disable View All Forecast | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Edit_sales_price_on_opportunity_product | Edit sales price on opportunity product | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Edit_User | Edit User | Salesforce Platform | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | For Compensation to edit roles for promotions and reporting |
| Forecast_Update | Forecast Update | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  | For [names] to update this so a PB is triggered to update forecast category |
| IT_Admin_Access | IT Admin Access |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Login_as_Another_User | Login as Another User |  | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| More_than_just_two_factor | More than just two factor | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Round_Robin_Group_edit_rights | Round Robin Group edit rights | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Salesforce_for_Slack | Salesforce for Slack | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| Temporary_Approve_Leads | Temporary Approve Leads | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |
| View_ODA_Tasks | View ODA Tasks | Salesforce | 0 / 0 | 0 | 0 | 0 / 0 | 0 | 0 | 0 |  |  |

