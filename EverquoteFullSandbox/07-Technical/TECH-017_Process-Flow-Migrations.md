# Process Builder to Flow Migrations

Source: `force-app/main/default/processflowmigrations` (121 `.processflowmigration-meta.xml` files).

## What these files are

A `ProcessFlowMigration` record is created by Salesforce's **Migrate to Flow** tool each time it converts one criteria node of a **Process Builder** process (source `processVersion`, criteria `migratedCriteriaName` / `migratedCriteriaLabel`) into a flow (`destinationFlowDefinition` / `destinationFlowVersion`).

- They are a **history log**. They do not activate or deactivate anything.
- Deploying them does not deploy the flows. Only 1 of the 56 destination flows (`Case_Update_Case_Owner_to_Account_Support_Rep_1`) is in `force-app/main/default/flows`. The other 55 exist only in the org.
- The file names are `<criteria>_<record Id>`, for example `myRule_11_301VZ00000zLvpVYAS`. The `301` prefix is the record's own ID in this sandbox.

## Totals

| Measure | Count |
|---|---|
| Migration records | 121 |
| Distinct source processes (process versions) | 47 |
| Distinct destination flows | 56 |
| Destination flows present in this repo | 1 |
| Sources migrated to **more than one** destination flow | 8 |

**Sources migrated more than once.** These have 2 or 3 destination flows each, so check that only one of each is **Active** in the org to avoid double execution:
- `BDR_Meeting_Set`
- `Case_Update_Case_Owner_to_Account_Support_Rep`
- `Contact_Update_Last_Campaign_Responded_From_Campaign_Member`
- `Do_Not_Contact_Contact_submits_Contact_Me`
- `Lead_Type_Update` (16 criteria x 2 flows = 32 records)
- `Primary_2` (3 flows)
- `Ringlead_Contact_Me_Event_is_Scheduled`
- `Worked_LF`

The source processes' activation state cannot be seen here, because the Process Builder (`processType = Workflow`) flow definitions were not retrieved. The one exception is `BDR_Activity_completed_change_lead_owner_to_activity_owner`, which is still Active; see the Flows README. If the source process is still active alongside its migrated flow, both run.

## Migration table (grouped by source process)

| Source process [version] | Records | Criteria migrated (node: label) | Destination flow(s) [version] | # dest. flows |
|---|---|---|---|---|
| `Account_Type_Tracker-2` | 6 | myRule_1: Type changes; myRule_3: Core; myRule_5: Core IO; myRule_7: Starter; myRule_9: Accelerated; myRule_11: Accelerated AGP | `Account_Type_Tracker_1` [Account_Type_Tracker_1-1] | 1 |
| `AGP_Pass_Up_turn_off_if_AGP_closed_lost-1` | 1 | myRule_1: AGP associates an Agency Opp | `AGP_Pass_Up_turn_off_if_AGP_closed_lost_1` [AGP_Pass_Up_turn_off_if_AGP_closed_lost_1-1] | 1 |
| `AGP_Pass_up-1` | 1 | myRule_1: AGP associates an Agency Opp | `AGP_Pass_up_1` [AGP_Pass_up_1-1] | 1 |
| `AGP_Support_Rep_Assigned_on_Opp_Closed_Won-11` | 1 | myRule_1: Commit and Support Rep changed | `Commit_and_support_rep_changes_create_onboarding_1` [Commit_and_support_rep_changes_create_onboarding_1-1] | 1 |
| `AGP_Upsell_Opp_Expiration-1` | 1 | myRule_1: Name = [AGP Upsell] | `AGP_Upsell_Opp_Expiration_1` [AGP_Upsell_Opp_Expiration_1-1] | 1 |
| `Answerforce-1` | 1 | myRule_1: Notes contains If no, Why Not | `Case_Answerforce_Update` [Case_Answerforce_Update-1] | 1 |
| `BDR_Meeting_Completed_Opp_to_be_created-6` | 2 | myRule_1: BDR Meeting Held - Lead; myRule_3: BDR meeting held - Contact | `BDR_Meeting_Completed_Opp_to_be_created_1` [BDR_Meeting_Completed_Opp_to_be_created_1-2] | 1 |
| `BDR_Meeting_No_Show_email_alert-2` | 1 | myRule_1: BDR Meeting No Show Lead | `BDR_Meeting_No_Show_email_alert_1` [BDR_Meeting_No_Show_email_alert_1-2] | 1 |
| `BDR_Meeting_Pre_Populate-1` | 1 | myRule_1: BDR Meeting record type | `BDR_Meeting_Pre_Populate_1` [BDR_Meeting_Pre_Populate_1-1] | 1 |
| `BDR_Meeting_Set-7` | 3 | myRule_1: BDR Meeting Set Lead; myRule_3: BDR Meeting Set Contact | `BDR_Meeting_Set_1` [BDR_Meeting_Set_1-1]<br>`BDR_Meeting_Set_2` [BDR_Meeting_Set_2-2] | 2 |
| `Campaign_Response_after_closed_won-1` | 1 | myRule_1: Responds but  already a customer | `Campaign_Response_after_closed_won_1` [Campaign_Response_after_closed_won_1-1] | 1 |
| `Case_Update_Case_Owner_to_Account_Support_Rep-14` | 2 | myRule_1: Account has a Support Rep | `Case_Update_Case_Owner_to_Account_Support_Rep_1` [Case_Update_Case_Owner_to_Account_Support_Rep_1-2] **(in source)**<br>`Case_Update_Case_Owner_to_Account_Support_Rep_2` [Case_Update_Case_Owner_to_Account_Support_Rep_2-1] | 2 |
| `Closed_Won_Copy_Opp_owner_to_Account_owner-3` | 1 | myRule_1: Closed Won Sales record types | `Closed_Won_Copy_Opp_owner_to_Account_owner_1` [Closed_Won_Copy_Opp_owner_to_Account_owner_1-1] | 1 |
| `Contact_ID_on_account_when_contact_is_created-5` | 1 | myRule_1: Choice UUID | `Contact_ID_on_account_when_contact_is_created_1` [Contact_ID_on_account_when_contact_is_created_1-1] | 1 |
| `Contact_Me_Event_Scheduled-2` | 2 | myRule_1: Event Scheduled for a Lead; myRule_3: Event Scheduled for a Contact | `Contact_Me_Event_Scheduled_1` [Contact_Me_Event_Scheduled_1-2] | 1 |
| `Contact_Record_type_to_DNC_when_status_is_DNC-1` | 1 | myRule_1: Status is DNC | `Contact_Record_type_to_DNC_when_status_is_DNC_1` [Contact_Record_type_to_DNC_when_status_is_DNC_1-1] | 1 |
| `Contact_Update_Last_Campaign_Responded_From_Campaign_Member-1` | 2 | myRule_1: Is Responded Contact | `Contact_Update_Last_Campaign_Responded_From_Campaign_Member_1` [Contact_Update_Last_Campaign_Responded_From_Campaign_Member_1-1]<br>`Contact_Update_Last_Campaign_Responded_From_Campaign_Member_2` [Contact_Update_Last_Campaign_Responded_From_Campaign_Member_2-1] | 2 |
| `CORE_ACCOUNT_CLOSURE_IN_56_DAY_WINDOW-11` | 4 | myRule_1: account closure farmers; myRule_3: State Farm; myRule_5: Allstate; myRule_7: IA Life | `CORE_ACCOUNT_CLOSURE_IN_56_DAY_WINDOW_1` [CORE_ACCOUNT_CLOSURE_IN_56_DAY_WINDOW_1-1] | 1 |
| `Core_Account_down_to_starter_or_up_to_AGP_closed_lost_the_continuity-2` | 2 | myRule_1: Type to Starter; myRule_3: Type to AGP | `Core_Account_down_to_starter_or_up_to_AGP_closed_lost_the_continuity_1` [Core_Account_down_to_starter_or_up_to_AGP_closed_lost_the_continuity_1-1] | 1 |
| `Core_IO_Win_date_changes2-2` | 1 | myRule_1: Core IO Closed Won | `Core_IO_Win_date_changes_2` [Core_IO_Win_date_changes_2-1] | 1 |
| `Create_Partner_Acccount_Relationship-1` | 1 | myRule_1: Account has related partner | `Create_Partner_Acccount_Relationship_1` [Create_Partner_Acccount_Relationship_1-1] | 1 |
| `Customer_Success_Create_Continuity-4` | 2 | myRule_1: AGP Onboarding Closed Won; myRule_4: Core Onboarding Complete | `Customer_Success_Create_Continuity_1` [Customer_Success_Create_Continuity_1-1] | 1 |
| `Customer_Success_Update_task_with_Last_Month_Revenue-6` | 1 | myRule_1: CS - Account ID task completed | `Customer_Success_Update_task_with_Last_Month_Revenue_1` [Customer_Success_Update_task_with_Last_Month_Revenue_1-1] | 1 |
| `Do_Not_Call-1` | 1 | myRule_1: Do not Call | `Do_Not_Call_Lead` [Do_Not_Call_Lead-1] | 1 |
| `Do_Not_Contact_Contact_submits_Contact_Me-1` | 2 | myRule_1: Do Not Contact | `Do_Not_Contact_Contact_submits_Contact_Me_1` [Do_Not_Contact_Contact_submits_Contact_Me_1-1]<br>`Do_Not_Contact_Contact_submits_Contact_Me_2` [Do_Not_Contact_Contact_submits_Contact_Me_2-1] | 2 |
| `Feed_Item_Contain_insertion-3` | 1 | myRule_1: Feed Item contains insertion | `Feed_Item_Contain_insertion_1` [Feed_Item_Contain_insertion_1-2] | 1 |
| `File_a_Ticket_Resolution-3` | 1 | myRule_1: Resolution Entered | `File_a_Ticket_Resolution_1` [File_a_Ticket_Resolution_1-2] | 1 |
| `LCS_Close_Won-5` | 2 | myRule_1: LCS Closed Won Agency; myRule_3: LCS Closed Won AGP | `LCS_Close_Won_1` [LCS_Close_Won_1-1] | 1 |
| `LCS_update_from_product_2-2` | 1 | myRule_1: lcs | `LCS_update_from_product_2_1` [LCS_update_from_product_2_1-1] | 1 |
| `Lead_Auto_Delete_Internal_Leads-6` | 1 | myRule_1: Email contains EQ or ADH | `Lead_Auto_Delete_Internal_Leads_1` [Lead_Auto_Delete_Internal_Leads_1-1] | 1 |
| `Lead_Type_Update-1` | 32 | myRule_1: Premium Lead Type Update; myRule_3: Premium (Exclusive) Lead Type Update; myRule_5: Preferred Lead Type; myRule_7: Preferred (Exclusive) Lead Type; myRule_9: Standard Lead Type; myRule_11: Standard (Exclusive) Lead Type; myRule_13: Non Standard Lead Type; myRule_15: Non Standard (Exclusive) Lead Type; myRule_17: Premium uncheck; myRule_19: Premium (Exclusive) uncheck; myRule_21: Preferred uncheck; myRule_23: Preferred (Exclusive) uncheck; myRule_25: Standard uncheck; myRule_27: Standard (Exclusive) uncheck; myRule_29: Non-Standard uncheck; myRule_31: Non-Standard (Exclusive) unchecked | `Lead_Type_Update_2` [Lead_Type_Update_2-1]<br>`Lead_Type_Update_2_1` [Lead_Type_Update_2_1-1] | 2 |
| `Locked_Account_Revert_to_Prior_Account_Type-1` | 1 | myRule_1: type is locked | `Locked_Account_Revert_to_Prior_Account_Type_1` [Locked_Account_Revert_to_Prior_Account_Type_1-1] | 1 |
| `No_Contact_Lead_fills_out_Contact_Me_form-1` | 1 | myRule_1: No Contact Record Type fill Contact Me form | `No_Contact_Lead_fills_out_Contact_Me_form_1` [No_Contact_Lead_fills_out_Contact_Me_form_1-1] | 1 |
| `No_Show_task_email_alert-1` | 1 | myRule_1: Meeting Outcome is No Sjow | `No_Show_task_email_alert_1` [No_Show_task_email_alert_1-1] | 1 |
| `Pause_Unpause_Update-1` | 4 | myRule_1: Paused Date; myRule_3: Unpaused Date; myRule_5: Remove Paused Date; myRule_7: Remove Unpaused Date | `Pause_Unpause_Update_1` [Pause_Unpause_Update_1-1] | 1 |
| `Populate_Parent_Account_on_Conversion-1` | 1 | myRule_1: Account Created with Parent account | `Populate_Parent_Account_on_Conversion_1` [Populate_Parent_Account_on_Conversion_1-1] | 1 |
| `Primary_2-1` | 3 | myRule_1: Account Doesn't have a primary contact | `Primary_2_1` [Primary_2_1-1]<br>`Primary_2_2` [Primary_2_2-2]<br>`Primary_2_3` [Primary_2_3-1] | 3 |
| `Primary_Contact_Setting_on_Account_when_opp_contact_role_is_created-1` | 1 | myRule_1: Account Doesn't have a primary contact | `Primary_Contact_Setting_on_Account_when_opp_contact_role_is_created_1` [Primary_Contact_Setting_on_Account_when_opp_contact_role_is_created_1-2] | 1 |
| `Pro_Lead_Source_Contact_Me-7` | 2 | myRule_1: Event type contact me; myRule_3: Event Type Abandoned Wizard | `Pro_Lead_Source_Contact_Me_1` [Pro_Lead_Source_Contact_Me_1-1] | 1 |
| `Referral_Process_Sept_15-5` | 2 | myRule_1: Active account referral; myRule_3: AGP Referral Inactive Owner | `Referral_Process_Sept_15_1` [Referral_Process_Sept_15_1-1] | 1 |
| `Referral_Set_Prim_Camp_for_Partnerstack_opps-13` | 1 | myRule_1: Partnerstack lead key is present | `Referral_Set_Prim_Camp_for_Partnerstack_opps_1` [Referral_Set_Prim_Camp_for_Partnerstack_opps_1-1] | 1 |
| `Ringlead_Contact_Me_Event_is_Scheduled-2` | 4 | myRule_1: BDR Meeting Set Lead; myRule_3: BDR Meeting Set Contact | `Ringlead_Contact_Me_Event_is_Scheduled_1` [Ringlead_Contact_Me_Event_is_Scheduled_1-1]<br>`Ringlead_Contact_Me_Event_is_Scheduled_2` [Ringlead_Contact_Me_Event_is_Scheduled_2-2] | 2 |
| `Task_Assignment_Notification-5` | 3 | myRule_1: New fresh/hot lead task; myRule_3: New task; myRule_5: Existing Task assigned | `Task_Assignment_Notification_1` [Task_Assignment_Notification_1-2] | 1 |
| `Upsell_Notes_for_next_opp-1` | 1 | myRule_1: opp opened | `Upsell_Notes_for_next_opp_1` [Upsell_Notes_for_next_opp_1-1] | 1 |
| `Upsell_Notes_from_last_opp-1` | 1 | myRule_1: Upsell opp is closed | `Upsell_Notes_from_last_opp_1` [Upsell_Notes_from_last_opp_1-1] | 1 |
| `upsell_update_upsell_field-3` | 1 | myRule_1: update upsell opp | `upsell_update_upsell_field_1` [upsell_update_upsell_field_1-1] | 1 |
| `Worked_LF-8` | 14 | myRule_1: Worked MD; myRule_3: Worked MF; myRule_5: Worked JE; myRule_7: Worked TT; myRule_9: Worked JM; myRule_11: Worked RM; myRule_13: Worked NK | `Worked_BDR_Lead_and_Contact` [Worked_BDR_Lead_and_Contact-1]<br>`Worked_BDR_Lead_and_Contact_1` [Worked_BDR_Lead_and_Contact_1-2] | 2 |
