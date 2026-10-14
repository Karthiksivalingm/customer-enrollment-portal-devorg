# Security and Permissions

Built from retrieved source (2026-10-14). **Coverage is partial:** profiles, permission set groups, roles, groups and sharing rules belong to
the `routing` and `access` retrieval batches, which were still running when this page was written (see
[Retrieval-Report.md](../07-Technical-Documents/Retrieval/Retrieval-Report.md)). INFERENCE marks interpretation.

## Org-wide defaults (Confirmed, from object metadata)
- **Custom objects:** every custom object is **Public Read/Write** or **Controlled by Parent** (master-detail children). None is Private or Read Only.
- **Standard objects:**
  - Account: Public Read/Write internally, Private externally.
  - Contact: Public Read/Write.
  - Case: Read/Write/Transfer.
  - Campaign: Private.
- INFERENCE: visibility is therefore controlled mainly by profiles and permission sets (object and field access), not by record sharing.

## Permission sets (48 unmanaged; grouping is INFERENCE from names and labels)
| Purpose | Permission sets |
|---|---|
| Admin / elevated | Admin_System_Expanded, Production_Admin, Production_Admins, System_Admin_Additional_Perms, Service_Cloud_Admin, View_all_data, Query_All, Hard_Delete, Export_Reports, Update_Inactive_Owners, Salesforce_Support_472059499 |
| MFA exemptions | Disable_MFA, Unrequire_MFA |
| Service, Omni-Channel and voice | Omni_Users_Access, Omni_Case_Voice, Omni_Supervisor_permission_set, Omnichannel_Supervisor, ContactCenterAgentVD, ServiceCloudVoiceCustomPsl, PartnerTelephonyCustomPsl, Listviews_Cases, General_Support, Knowledge_LSF_Permission_Set |
| Sales | Sales_User, Opp_Delete_Access, Transfer_Opportunity |
| Foundation (FNDN) | FND_User_permission, Foundation_Account_Access, Foundation_SFtoSF_integration, FNDN_Accounting |
| Functional access | Compliance_Creative_Permissions, Delete_Onboarding_Projects, Edit_Access_for_Touch_Point_Master_Id, Show_RPM_Bounceback_Fields, JYD_Access |
| UI and tools | Allow_Flows, Customize_Lightning_Pages, Listview_Manager, Data_cloud_tab_access, Use_Lightning_Content_Builder_With_CMS, USF_Flow_Action_Collection_Actions, USF_Flow_Screen_Component_Custom_Objects, Slack_Admin_User, Slack_Feedback_User |
| Look like test or sample sets | abc, abc1, abcs, dreamhouse |

The full list with licenses and permission counts is in [Metadata-Inventory/Permission-Sets.md](../07-Technical-Documents/Metadata-Inventory/Permission-Sets.md).

## Custom permissions
`Franchise_Type_Edit` and `Show_RPM_Bounceback_Fields`. The latter is granted by the permission set of the same name.

## Integration security
- **Bypass:** integration triggers are bypassed through `Process_Switches__c` and the "Integration User".
- **Credentials:** hardcoded in 7 Apex classes and 1 external credential ([CF-001](../05-Conflicts/2026-10-14-CF-001-hardcoded-credentials-in-org-apex-and-external-credential-so.md)). `TouchPoint_Callout__mdt` holds tokens (org only).

## Risks to review (INFERENCE)
- High-risk access: View_all_data, Query_All, Hard_Delete and the MFA exemption sets. Review who holds them.
- abc, abc1, abcs and dreamhouse look like leftover test or sample permission sets.
- With all custom objects Public Read/Write, any user with object access can see all records of that object.

## Pending
- Profiles (102), permission set groups (14), roles (72), groups (35) and sharing rules for in-scope objects will be added after the
  `routing` and `access` batches complete.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from object metadata and permission sets; profile and sharing coverage pending. |
