# Custom Fields Reference (from automation)

This project has **no `objects` folder**, so field metadata (types, labels, help text) was not retrieved. This reference is built only from references in:

- the 33 triggers and the handler and helper classes they call: `LeadHandler`, `LeadTriggerHelper`, `etcd8_RRLeadAssignment`, `EventHandler`, `TaskHandler`, `OpportunityLineItemHandler`, `OpportunityTriggerHandler`, `AutoPopulateContactOnVoiceCall`;
- the 4 flows;
- the 18 workflow files.

Other Apex classes (for example `OdieWrapper` and `NotifyCTI`) are not covered here.

Legend:
- **(W)** = written, **(R)** = read.
- `*` after a trigger name = that trigger is **Inactive**.
- A few standard fields (OwnerId, MobilePhone) are included where several automations compete for them.
- Workflow components are listed whether the rule is active or not. Check active status in `Workflows/README.md`.

## Custom objects, custom metadata and platform events referenced

| API name | Kind | Referenced by |
|---|---|---|
| Referral__c | Custom object | LeadHandler.updateConvertedLeadReferrals, UpdateReferral* |
| etcd8_LeadRecipient__c | Custom object (eightCloud round-robin) | etcd8_RRLeadAssignment (via LeadHandler) |
| Carrier__c | Custom object (via `Carrier__r` lookups on Lead, Account) | Lead and Opportunity workflow formulas |
| Customer_Success__c | Custom object | Customer_Success__c workflow (8 rules, all inactive) |
| File_a_Ticket__c | Custom object | File_a_Ticket__c workflow (4 rules, all inactive) |
| Survey_Response_Customer_Support_Survey__c | Custom object | 1 email alert |
| Team_Member__c | Custom object | Team_Member__c workflow (1 inactive rule) |
| Time_Off_Request__c | Custom object | 2 field updates, 2 email alerts (likely approval-process actions) |
| Trigger_Setting__mdt | Custom metadata type | LeadHandler.checkLeadScore (records `LeadBeforeInsert`, `LeadBeforeUpdate`, field `Is_Active__c`) |
| OnboardingSettings__c | Custom setting | Only in **commented-out** code in OpportunityTriggerHandler |
| Platform events (`__e`) | none | No platform events are referenced by triggers, flows or workflows |

## Fields by object

### Account

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Account_Status__c |  |  | WF rule 'Open Customer, Change Account Type (New)' (criteria); WF rule 'Type update - Locked Account' (criteria) |
| AGP__c |  |  | WF field update AGP_to_Yes (writes) |
| AGP_Pass_up_Closed_Won__c |  |  | WF field update AGP_Closed (writes); WF field update AGP_Passup_to_closed_won (writes); WF rule 'Referral Rock Integration - Agency' (criteria) |
| Auto_Folio_Opt_in_Date__c |  |  | WF field update Update_FPD (reads); WF rule 'FPD Folio Update' (criteria) |
| Choice_UUID__c |  |  | WF rule 'IsCustomer field update' (criteria); WF rule 'Type update to prospect' (criteria) |
| Core_IO_Win_Date__c |  |  | WF field update Core_IO_Win_Date (writes); WF field update Core_IO_Win_Date_f (writes) |
| First_Payment_Date__c |  |  | WF field update Update_FPD (writes); WF rule 'FPD Folio Update' (criteria) |
| Is_Customer__c |  |  | WF field update Is_Customer_Field_Update (writes) |
| Last_Monthly_Review__c |  |  | WF field update Last_Monthly_Review (reads); WF rule 'Last Monthly Review update' (criteria) |
| Last_Monthly_Review_Completed_Date_del__c |  |  | WF field update Prior_to_Last_Monthly_Review_Date (reads); WF rule 'Last Monthly Review Date Changes' (criteria) |
| LifeCycle_Stage__c |  |  | WF field update Lifecycle_Onboard (writes) |
| Master__c |  |  | WF field update MasterID_Update (writes) |
| Next_To_Last_Monthly_Review__c |  |  | WF field update Last_Monthly_Review (writes) |
| Notes_from_Sales__c |  |  | WF field update Notes_from_Sales (writes) |
| office_count__c |  |  | WF rule 'Field Update-Offices Update Time' (criteria) |
| OfficesUpdateTime__c |  |  | WF field update OfficesUpdateTIme (writes) |
| Prior_to_Last_Monthly_Review_Date__c |  |  | WF field update Prior_to_Last_Monthly_Review_Date (writes) |
| producer_count__c |  |  | WF rule 'Field Update-Num Producers Update' (criteria) |
| ProducersUpdateTime__c |  |  | WF field update NumProducersUpdateTime (writes) |
| RecordType_Conversion__c |  |  | WF rule 'Flip Acct Record Type to partner' (criteria) |
| saturday_cap__c |  |  | WF rule 'Saturday Cap Changed' (criteria) |
| Saturday_Cap_Changed__c |  |  | WF field update Saturday_Cap_Change (writes) |
| Sunday_Cap__c |  |  | WF rule 'Sunday Cap Changed' (criteria) |
| Sunday_Cap_Changed__c |  |  | WF field update Sunday_Cap_Changed (writes) |
| Support_Rep__c |  | Case_Update_Case_Owner_to_Account_Support_Rep_1 (R, via Case.Account) | WF alert CaseEmail_Template_Alert (recipient) |
| TICA__c |  |  | WF field update TICA_to_account (writes) |
| Update__c |  |  | WF field update Core_IO_Win (writes) |
| weekday_cap__c |  |  | WF rule 'Weekday Cap Changed' (criteria) |
| Weekday_Cap_changed__c |  |  | WF field update Weekday_Cap_Changed (writes) |
| Years_in_Business__c |  |  | WF rule 'Field Update-YRs in business' (criteria) |
| YearsinBusinessUpdateTime__c |  |  | WF field update Years_IN_business_update (writes) |

### Case

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Account_Closure__c |  |  | WF field update Account_Closure_CF_reason (writes) |
| Case_Results__c |  |  | WF rule 'Cancellation Reason Slack' (criteria); WF rule 'Core Business Review Completed Date' (criteria) |
| Case_Transferred__c |  |  | WF field update Case_Transfer_Date (writes) |
| Charge_Attempts__c |  |  | WF field update count_charge_attempts (reads); WF field update count_charge_attempts (writes) |
| Completed_Date__c |  |  | WF field update CBR_Completed_Date_with_Close_Date (writes) |
| Customer_Support_Type__c |  |  | WF field update Account_Closure_CF (writes); WF rule 'Account Closure Record Type Update' (criteria); WF rule 'Cancellation Reason Slack' (criteria); WF rule 'Case Record type to DNC' (criteria); WF rule 'Referral Credit Update Record Type' (criteria) |
| Initial_Solve_Date__c |  |  | WF field update Update_initial_solve_date_on_first_close (writes); WF rule 'Update initial solve date on first close' (criteria) |
| Last_Call_Time__c | UpdateCaseFromTask* (W) |  |  |
| Last_Charge_Attempt_Date__c |  |  | WF rule 'Charge Attempts' (criteria) |
| Monthly_Calls_Review_QBR__c |  |  | WF rule 'Send CSAT survey AGP first QBR' (criteria) |
| OwnerId (standard) |  | Case_Move_to_Smart_Campaign_Queue (W); Case_Update_Case_Owner_to_Account_Support_Rep_1 (W) |  |
| Remove_Smart_Campaign__c |  | Case_Move_to_Smart_Campaign_Queue (R, entry criteria) | WF rule 'Move to Smart Campaign Queue' (criteria) |
| Send_CSAT_survey_AGP_first_QBR__c |  |  | WF field update Send_CSAT_survey_AGP_first_QBR (writes) |
| Time_to_First_Response__c | EventCaseFirstActivity* (W); TaskCaseFirstActivity* (W); EventHandler.handleCaseFirstActivity (W) |  |  |

### Contact

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| BDR_Main_View__c |  |  | WF alert BDR_Main_View_Alert_Contact (recipient) |
| BDR_meeting_set_on_task__c |  |  | WF rule 'Contact Me No Meeting Scheduled' (criteria) |
| City__c |  |  | WF rule 'Contact_Cityc_Field_Changed' (criteria) |
| Contact_Me_Checkbox__c |  |  | WF rule 'Contact Me Checkbox date' (criteria); WF rule 'Contact Me No Meeting Scheduled' (criteria) |
| Contact_Me_Checkbox_date__c |  |  | WF field update Contact_Me_Checkbox_date (writes) |
| Contact_Status__c |  |  | WF rule 'Round Robin assigned contact mewebinar' (criteria); WF rule 'Round Robin assigned webinar' (criteria); WF rule 'Unqualified - Change owner' (criteria) |
| Home_Page_Check_box__c |  |  | WF rule 'Home Page contact me date' (criteria) |
| Home_Page_Contact_Me_Date__c |  |  | WF field update Home_Page_contact_me_date (writes) |
| State__c |  |  | WF rule 'Contact_Statec_Field_Changed' (criteria) |
| Street_Address__c |  |  | WF rule 'Contact_StreetAddressc_Field_Changed' (criteria) |
| Update_Picklist__c |  |  | WF rule 'Round Robin assigned contact mewebinar' (criteria); WF rule 'Round Robin assigned webinar' (criteria) |
| Zip_Code__c |  |  | WF rule 'Contact_ZipCodec_Field_Changed' (criteria) |

### Event

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Meeting_Purpose__c |  |  | WF rule 'BDR Meeting Event' (criteria) |
| Meeting_Result__c | ConvertLead* (R); EventHandler.handleConvertLead (R) |  | WF rule 'BDR Meeting Event' (criteria) |
| User_Profile__c | EventUpdateUserRole* (W); EventHandler.handleUpdateUserRole (W) |  |  |
| User_Role__c | EventUpdateUserRole* (W); EventHandler.handleUpdateUserRole (W) |  |  |

### Lead

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Account1__r.Carrier__r.Name |  |  | WF rule 'Lead Agency Update' (criteria) |
| Added_to_Waitlist_Date__c |  |  | WF field update Date_Added_to_Waitlist (writes) |
| Assigned_Date__c | AggregateCall* (R); EventLeadFirstActivity* (R); TaskLeadFirstActivity* (R); EventHandler.handleLeadFirstActivity (R) |  |  |
| BDR_Main_View__c |  |  | WF alert BDR_Main_View_Alert_Lead (recipient); WF alert BDR_Main_View_Lead2 (recipient) |
| Call_Count__c | AggregateCall* (W) |  | WF field update Reset_Call_Count (writes) |
| Call_Duration_Minutes__c | AggregateCall* (W) |  |  |
| Call_Duration_Seconds__c | AggregateCall* (W) |  |  |
| Campaign__c |  |  | WF rule 'Email test' (criteria) |
| Carrier__r.Name |  |  | WF field update Carrier_Update (reads); WF rule 'Lead Carrier Update' (criteria) |
| Contact_Me_checkbox__c |  |  | WF rule 'Contact Me Checkbox date' (criteria) |
| Contact_Me_Checkbox_date__c |  |  | WF field update Contact_Me_Checkbox_date (writes) |
| DMCallCount__c | AggregateCall* (W); ResetLeadWhenLost* (W); LeadHandler.resetCallFieldsWhenLost (W) |  |  |
| EqLeadUuid__c | LeadOwnerUpdated* (R); LifeLeadCreated* (R); LeadHandler.syncNewLifeLeadsToOdie / syncOwnerChangeToOdie (R) |  |  |
| GateKeeperCallCount__c | AggregateCall* (W); ResetLeadWhenLost* (W); LeadHandler.resetCallFieldsWhenLost (W) |  |  |
| Home_Page_Checkbox__c |  |  | WF rule 'Home Page Contact Me Date' (criteria) |
| Home_Page_Contact_Me_Date__c |  |  | WF field update Home_Page_Contact_Me_Date (writes) |
| IMHeld__c | ConvertLead* (W); ConvertLeadWhenIMHeld* (R); EventHandler.handleConvertLead (W) |  |  |
| InitialMeetingDate__c | ConvertLead* (W); EventHandler.handleConvertLead (W) |  |  |
| Last_Call_Time__c | AggregateCall* (W) |  |  |
| LastCallDispo__c | AggregateCall* (W); ResetLeadWhenLost* (W); LeadHandler.resetCallFieldsWhenLost (W) |  |  |
| Lead_Lost__c |  |  | WF field update Lead_Lost_Date_Time (writes) |
| Lead_Outcome__c | LeadOutcomeUpdated* (R); LeadHandler.syncOutcomeChangeToOdie (R) |  | WF rule 'Set Lead Status Closed' (criteria); WF rule 'Set Lead Status Follow-up' (criteria); WF rule 'Set Lead Status Nurture' (criteria); WF rule 'Set Lead Status Won' (criteria) |
| Lead_owner_changed__c |  |  | WF rule 'No Show Lead to True' (criteria) |
| Lead_Recipient__c | LeadHandler.assignRoundRobinLeads -> etcd8_RRLeadAssignment (W); etcd8_LeadTrigger* (W) |  |  |
| Lead_Source_Update__c |  |  | WF rule 'Lead Source Email' (criteria); WF rule 'Lead Source List Import' (criteria); WF rule 'Lead Source Live Event' (criteria); WF rule 'Lead Source Outbound Call' (criteria); WF rule 'Lead Source Referral' (criteria); WF rule 'Lead Source Search' (criteria); WF rule 'Lead Source Webinar' (criteria); WF rule 'Lead Source ZoomInfo' (criteria) |
| Lost_Reason__c |  |  | WF field update Lost_Reason_to_Blank (writes) |
| mkto71_Lead_Score__c | LeadHandler.checkLeadScore -> LeadTriggerHelper (R/W, set to 90 for LeadSource 'Web Scrape') |  |  |
| MobilePhone (standard) | LeadHandler.syncMobilePhoneWithPhone (W); UpdateLeadMobilePhone* (W) |  |  |
| Next_Due_Date__c | AggregateCall* (W); DueDate* (W) |  |  |
| OwnerId (standard) | LeadHandler round-robin (W); TaskHandler.assignLeadOwnerOnFirstCall (W); EventHandler.handleConvertLead (W); TaskLead*, ChangeOwnerAfterSpokeDM*, ConvertLead* (W) | BDR_Activity_completed_change_lead_owner_to_activity_owner (W); Task_BDR_Activity_Completed_Change_Lead_Owner (W) |  |
| Recycled_Date__c |  |  | WF field update Recycle_Lost_Date_Update (writes) |
| Referral_Rock_Lead__c |  |  | WF rule 'Referral Rock Email Notification' (criteria) |
| Time_to_First_Response__c | EventLeadFirstActivity* (W); TaskLeadFirstActivity* (W); EventHandler.handleLeadFirstActivity (W) |  |  |
| Unqualified_Reason__c |  |  | WF rule 'Unqualified: Commercial Agents' (criteria); WF rule 'Unqualified: Consumer' (criteria); WF rule 'Unqualified: Invalid Contact Info' (criteria); WF rule 'Unqualified: Unqualified' (criteria) |
| Update_Picklist__c |  |  | WF rule 'Lead Assigned Send Round Robin webinar' (criteria) |

### Opportunity

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Account.Carrier__r.ARPA_Enrolled__c (via Account) |  |  | WF field update Amount_of_Opportunity (reads); WF rule 'Update Amount' (criteria) |
| Account.Carrier__r.Name (via Account) |  |  | WF field update Opportunity_Name_Update (reads); WF field update Set_Opportunity_Name_for_Everlife (reads) |
| Account_in_Extended_Pause__c | OpportunityTriggerHandler.createNewOppWhenClose (R/W, via inactive OpportunityTrigger*) |  |  |
| AGP_Closed_Won__c |  |  | WF field update AGP_Closed_Won (writes) |
| Business_Consultant__c |  |  | WF alert BC_notification_of_assigned_account_after_AGP_opp_closed_wo (recipient); WF alert Tier_Mvmt_BC_Assigned_BC_Sales (recipient) |
| Call_Count__c | UpdateOppFromEvent* (W); UpdateOppFromTask* (no DML) |  | WF rule 'Exhaust Upsell' (criteria) |
| Campaign__c |  |  | WF field update test (writes) |
| Category__c |  |  | WF field update Advertiser_Opp_Name_Update (reads) |
| Core_IO__c |  |  | WF rule 'Core IO Win' (criteria); WF rule 'Mark CORE IO Win' (criteria) |
| CurrentState__c |  |  | WF rule 'Opp Current is Blank' (criteria); WF rule 'Opp Current State is Not Blank' (criteria) |
| Customer_Phone_Number__c |  |  | WF field update Everlife_Add_phone_number_to_oppty (writes) |
| DOCUSIGN_Ad_Spend_Amount__c | OpportunityLineItemHandler (W); OpportunityLineItemTrigger* (W) |  |  |
| DOCUSIGN_Marketing_Services_Products__c | OpportunityLineItemHandler (W); OpportunityLineItemTrigger* (W) |  |  |
| Estimated_Lift__c | OpportunityTriggerHandler.createNewOppWhenClose (R/W, via inactive OpportunityTrigger*) |  |  |
| FutureState__c |  |  | WF rule 'Opp Future State is Blank' (criteria); WF rule 'Opp Future State is Not Blank' (criteria) |
| Gap__c |  |  | WF rule 'Opp Gap is Blank' (criteria); WF rule 'Opp Gap is Not Blank' (criteria) |
| Initial_CC_Failure_Date__c | OpportunityTriggerHandler.createNewOppWhenClose (R/W, via inactive OpportunityTrigger*) |  |  |
| Insertion_Order_Attached__c |  |  | WF rule 'AGP IO Notification' (criteria) |
| ISR_Owner__c |  |  | WF rule 'ISR Referral AGP Closed Won' (criteria) |
| last_call_time__c | UpdateOppFromEvent* (W); UpdateOppFromTask* (no DML) |  |  |
| Lost_Reason__c |  |  | WF field update Lost_Reason_Exhausted (writes) |
| next_due_date__c | UpdateOppFromEvent* (W); UpdateOppFromTask* (no DML) |  | WF rule 'Update stage to Pending' (criteria) |
| Notes_for_CSM__c |  |  | WF field update Notes_from_Sales (reads); WF rule 'Closed Won' (criteria) |
| Notes_for_Next_Opp__c | OpportunityTriggerHandler.createNewOppWhenClose (R, via inactive OpportunityTrigger*) |  |  |
| Notes_from_Last_Opp__c | OpportunityTriggerHandler.createNewOppWhenClose (W, via inactive OpportunityTrigger*) |  |  |
| Onboarding_Owner__c |  |  | WF alert New_Onboarding_Record_Alert (recipient) |
| Opp_Current_State_is_blank__c |  |  | WF field update Current_State_has_text_now (writes); WF field update Current_State_is_Blank (writes) |
| Opp_Future_State_is_Blank__c |  |  | WF field update Future_State_is_Blank (writes); WF field update Future_State_now_has_text (writes) |
| Opp_Gap_is_blank__c |  |  | WF field update Opp_Gap_is_Blank (writes); WF field update Opp_Gap_Now_Has_Text (writes) |
| Pro_Dunning_Success_Time__c | OpportunityTriggerHandler.createNewOppWhenClose (R/W, via inactive OpportunityTrigger*) |  |  |
| Product__c |  |  | WF field update Advertiser_Opp_Name_Update (reads) |
| Product_Class__c |  |  | WF field update Advertiser_Opp_Name_Update (reads) |
| Push_Counter__c |  |  | WF field update Increment_Push_Counter_Field (reads); WF field update Increment_Push_Counter_Field (writes) |
| Support_Rep__c |  |  | WF alert BC_notification_of_assigned_account_after_AGP_opp_closed_wo (recipient); WF alert Core_IO_Support_rep_assignment (recipient); WF rule 'AGP IO Notification' (criteria) |
| Trigger_Ranking__c | OpportunityTriggerHandler.createNewOppWhenClose (R/W, via inactive OpportunityTrigger*) |  |  |

### OpportunityLineItem

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| LCS__c |  |  | WF rule 'Opportunity Product Update' (criteria) |
| Product__c |  |  | WF field update Opportunity_Product_Update (writes) |

### Task

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Call_Outcome__c |  |  | WF rule 'Callback Follow-up' (criteria) |
| isLead__c |  |  | WF field update isLead_field_update (writes) |
| ReminderDateTime__c | TaskSetReminder* (W); TaskHandler.setReminderDateTime (W) |  |  |
| User_Profile__c | TaskUpdateUserRole* (W); TaskHandler.updateUserRoleAndProfile (W) |  |  |
| User_Role__c | TaskUpdateUserRole* (W); TaskHandler.updateUserRoleAndProfile (W) |  |  |

### User

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Update_User_s_Team_Member_Role__c |  |  | WF field update Check_box_to_update_the_member_s_role (writes) |

### VoiceCall

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Account__c | VoiceCallTrigger -> AutoPopulateContactOnVoiceCall (W) |  |  |
| Contact__c | VoiceCallTrigger -> AutoPopulateContactOnVoiceCall (W) |  |  |

### Customer_Success__c

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| First_Monthly_Call_Finalized__c |  |  | WF rule 'Core First Monthly Completed' (criteria); WF rule 'First Monthly Completed' (criteria) |
| Intro_Call_Finalized__c |  |  | WF rule 'Intro Completed' (criteria) |
| Intro_Call_Finalized_Date__c |  |  | WF field update Intro_Call_Finalized_Date (writes) |
| Onboarding_complete__c |  |  | WF rule 'Onboarding Complete Date' (criteria); WF rule 'Third Monthly Completed' (criteria) |
| Onboarding_Complete_Date__c |  |  | WF field update Onboarding_Complete_Date (writes) |
| Second_Monthly_Call_Finalized__c |  |  | WF rule 'Second Monthly Completed' (criteria) |
| Stage__c |  |  | WF field update Closed_Won (writes); WF field update Core_Monthly_review_completed (writes); WF field update Core_TrainingCompleted (writes); WF field update First_Monthly_Review_Stage (writes); WF field update qbr (writes); WF field update SecondMonth (writes); WF field update Update_Stage_to_Training (writes) |
| Training_Finalized__c |  |  | WF rule 'Training Completed' (criteria); WF rule 'Training Completed Core' (criteria) |

### etcd8_LeadRecipient__c

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Available__c | etcd8_RRLeadAssignment via LeadHandler (R) |  |  |
| NextUp__c | etcd8_RRLeadAssignment via LeadHandler (R/W) |  |  |
| User__c | etcd8_RRLeadAssignment via LeadHandler (R) |  |  |

### File_a_Ticket__c

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Category__c |  |  | WF rule 'ODA Notify Request' (criteria); WF rule 'ODA Notify Sales or Lumico Support Users' (criteria); WF rule 'ODA Notify SF Support Users' (criteria); WF rule 'ODA Notify Twilio Support Users' (criteria) |

### Referral__c

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Referral__c (lookup to Lead) | LeadHandler.updateConvertedLeadReferrals (R); UpdateReferral* (R) |  |  |
| Referral_Account__c | LeadHandler.updateConvertedLeadReferrals (W); UpdateReferral* (W) |  |  |
| Referral_Contact__c | LeadHandler.updateConvertedLeadReferrals (W); UpdateReferral* (W) |  |  |
| Referral_Opportunity__c | LeadHandler.updateConvertedLeadReferrals (W); UpdateReferral* (W) |  |  |

### Survey_Response_Customer_Support_Survey__c

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Case_Owner_ID__c |  |  | WF alert email_alert_for_task_creation_on_csat_survey_response_of_2 (recipient) |

### Team_Member__c

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Team_Member_Name__r.Id |  |  | WF field update Update_Team_Members_ID (reads) |
| Team_Member_Name__r.UserRole.Name |  |  | WF field update Update_Team_Member_Role (reads) |
| Team_Member_Role__c |  |  | WF field update Update_Team_Member_Role (writes) |

### Time_Off_Request__c

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Approved__c |  |  | WF field update Time_Off_Approved (writes) |
| Rejected__c |  |  | WF field update Rejected (writes) |

### Trigger_Setting__mdt

| Field | Apex triggers / handlers | Flows | Workflow rules / field updates / alerts |
|---|---|---|---|
| Is_Active__c | LeadHandler.checkLeadScore (R; records 'LeadBeforeInsert', 'LeadBeforeUpdate') |  |  |

