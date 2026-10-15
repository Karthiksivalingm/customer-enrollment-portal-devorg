# Workflow Rules

Source: `force-app/main/default/workflows` (18 `.workflow-meta.xml` files, one per object).

> **Retirement notice:** Salesforce has retired Workflow Rules and Process Builder. Existing active rules keep running, but you cannot create new ones and support has ended. Every active rule below should be migrated to a record-triggered flow. Before-save flows suit same-record field updates; after-save flows suit cross-object updates, email alerts and tasks.
>
> Rules marked **"(migration failed)"** have a `failedMigrationToolVersion` (262.12.5) element in the XML. That means the Migrate to Flow tool attempted them and did not complete.

Notes on redaction: recipients and members that are named users are shown as `[named user]`, email addresses as `[email set]`, and people's names in API names or descriptions as `[name]`. The tokens in outbound-message URLs are masked.

## Summary

| Object | Rules | Active | Migration failed | Field updates | Email alerts | Outbound msgs | Tasks |
|---|---|---|---|---|---|---|---|
| Account | 22 | 5 | 7 | 18 | 2 | 0 | 0 |
| CampaignMember | 1 | 0 | 0 | 0 | 3 | 0 | 0 |
| Case | 12 | 4 | 5 | 16 | 15 | 0 | 0 |
| Contact | 10 | 7 | 5 | 2 | 7 | **3** | 0 |
| Customer_Success__c | 8 | 0 | 0 | 9 | 0 | 0 | 0 |
| EmailMessage | 1 | 1 | 1 | 1 | 0 | 0 | 0 |
| Event | 1 | 0 | 0 | 0 | 1 | 0 | 0 |
| File_a_Ticket__c | 4 | 0 | 0 | 0 | 4 | 0 | 0 |
| Lead | 31 | 8 | 8 | 31 | 9 | 0 | 1 |
| Opportunity | 19 | 11 | 5 | 27 | 12 | 0 | 0 |
| OpportunityLineItem | 2 | 0 | 0 | 2 | 0 | 0 | 0 |
| SocialPost | 1 | 0 | 0 | 0 | 1 | 0 | 0 |
| Survey_Response_Customer_Support_Survey__c | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| Task | 6 | 3 | 3 | 3 | 8 | 0 | 1 |
| Team_Member__c | 1 | 0 | 0 | 2 | 0 | 0 | 0 |
| Time_Off_Request__c | 0 | 0 | 0 | 2 | 2 | 0 | 0 |
| User | 1 | 0 | 0 | 1 | 2 | 0 | 0 |
| VoiceCall | 0 | 0 | 0 | 0 | 2 | 0 | 0 |
| **Total** | **120** | **39** | **34** | **114** | **69** | **3** | **2** |

Many field updates and alerts are not referenced by any rule. They may be used by approval processes, by processes or flows not in source, or be orphans. Examples: Account `AGP_to_Yes` and `Lifecycle_Onboard`; Opportunity `AGP_Closed`, `TICA_to_account` and the Everlife updates; Time_Off_Request__c `Rejected` and `Time_Off_Approved`.

## Key findings

**Active rules with no actions.** These evaluate on every save but do nothing:
- Account: `*_Field_Changed` (4 active), `Fraudulent Account` (hard-coded phone numbers).
- Contact: `Contact_*c_Field_Changed` (4), `Unqualified - Change owner`.
- Opportunity: `Referral Rock Integration - Agency`.
- Task: `Update Contact Field on Activity`, `Update Correct Contact`.
- Lead: `No Show Lead to True` (time trigger with no actions).

These rules are probably leftovers from outbound messages or Process Builder hand-offs that were removed.

**Outbound messages (Contact).** There are 3, all pointing at `delighted.com` (CSAT_Starter_Team_Delighted_Outbound, LCS_Survey, LCS_Survey_2). No workflow rule in source calls them, so they appear orphaned, or are called from processes or flows that were not retrieved.

**Active owner and record-type updates that overlap with code or flows:**

| Field | Workflow component (active) | Also written by |
|---|---|---|
| Case.OwnerId | Move to Smart Campaign Queue -> `Owner_Change_to_Smart_Campaign_Queue` | Flow Case_Move_to_Smart_Campaign_Queue (same logic, before save); Flow Case_Update_Case_Owner_to_Account_Support_Rep_1 (after save, every edit) |
| Case.Status (cross-object) | EmailMessage: Reopen Closed Case on New Email -> `Reopen_Closed_Case_on_New_Email` | The Case update re-runs the Support Rep owner flow |
| Case.RecordTypeId | Account Closure Record Type Update, Case Record type to DNC, Referral Credit Update Record Type | Not written elsewhere in source |
| Lead.OwnerId | Lead: Duplicate Queue, Recycle Lost Leads, Unqualified: Commercial Agents / Consumer / Invalid Contact Info / Unqualified | LeadHandler (round-robin), TaskHandler.assignLeadOwnerOnFirstCall, EventHandler.handleConvertLead, BDR Task flows (2). Owner changes made by workflow are not synced to ODIE because of the run-once recursion guard (see Triggers README) |
| Lead.RecordTypeId | Revert Back Do Not Call Leads (`reevaluateOnChange = true`) | Not written elsewhere in source |
| Account.Core_IO_Win_Date__c | **Two active rules**: Core IO Win -> `Core_IO_Win_Date_f`; Mark CORE IO Win -> `Core_IO_Win_Date` | Process migration `Core_IO_Win_date_changes2` (flow not in source) |
| Opportunity.StageName | Update stage to Pending (criteria uses `next_due_date__c`) | `next_due_date__c` is only maintained by the **inactive** UpdateOppFromTask/UpdateOppFromEvent triggers, so it is stale |

---

## Account

### Rules (22)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Account_BillingCity_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(BillingCity)` |  |  |
| Account_BillingCountry_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(BillingCountry)` |  |  |
| Account_BillingPostalCode_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(BillingPostalCode)` |  |  |
| Account_BillingState_Field_Changed | false (migration failed) | onAllChanges | Formula: `ISCHANGED(BillingState)` |  |  |
| Account_BillingStreet_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(BillingStreet)` |  |  |
| FPD Folio Update | false | onCreateOrTriggeringUpdate | Formula: `ISBLANK(First_Payment_Date__c) &&  NOT(ISBLANK(Auto_Folio_Opt_in_Date__c))` | FieldUpdate: Update_FPD |  |
| Field Update-Num Producers Update | false | onAllChanges | Formula: `ISCHANGED (  producer_count__c )` | FieldUpdate: NumProducersUpdateTime |  |
| Field Update-Offices Update Time | false | onAllChanges | Formula: `ISCHANGED (    office_count__c   )` | FieldUpdate: OfficesUpdateTIme |  |
| Field Update-YRs in business | false | onAllChanges | Formula: `ISCHANGED (     Years_in_Business__c    )` | FieldUpdate: Years_IN_business_update |  |
| Flip Acct Record Type to partner | false (migration failed) | onCreateOnly | Account.RecordType_Conversion__c equals "0121a000000RLk9" | FieldUpdate: Account_Record_Type |  |
| Fraudulent Account | true (migration failed) | onAllChanges | Formula: `OR( Phone = "(202) 288-2807", Phone = "(301) 445-8990", Phone = "(301) 434-2807", Phone = "(301) 285-8552")` |  |  |
| IsCustomer field update | false | onCreateOrTriggeringUpdate | Account.Choice_UUID__c notEqual "" | FieldUpdate: Is_Customer_Field_Update |  |
| Last Monthly Review Date Changes | false | onAllChanges | Formula: `ISCHANGED(  Last_Monthly_Review_Completed_Date_del__c  )` | FieldUpdate: Prior_to_Last_Monthly_Review_Date |  |
| Last Monthly Review update | false | onAllChanges | Formula: `ISCHANGED(Last_Monthly_Review__c)` | FieldUpdate: Last_Monthly_Review |  |
| MasterID Update | false | onCreateOrTriggeringUpdate | Formula: `NOT(ISBLANK( ParentId ))  &&   Parent.RecordTypeId  = "0121a000000RM9w" &&  RecordTypeId = "0121a000000EqqQ"` | FieldUpdate: MasterID_Update |  |
| Open Customer%2C Change Account Type %28New%29 | false | onCreateOrTriggeringUpdate | Account.Account_Status__c equals "Open"; Account.Type equals "Prospect,Closed Account" | FieldUpdate: Change_Type_to_Starter |  |
| Saturday Cap Changed | false | onAllChanges | Formula: `ISCHANGED(   saturday_cap__c   )` | FieldUpdate: Saturday_Cap_Change |  |
| Sunday Cap Changed | false | onAllChanges | Formula: `ISCHANGED( Sunday_Cap__c )` | FieldUpdate: Sunday_Cap_Changed |  |
| Type update - Locked Account | false | onCreateOrTriggeringUpdate | Account.Account_Status__c equals "Locked" | FieldUpdate: Change_Type_to_Locked |  |
| Type update - Partner | false | onCreateOnly | Account.RecordTypeId equals "Partner" | FieldUpdate: Account_Type_Partner |  |
| Type update to prospect | false | onCreateOnly | Account.Choice_UUID__c equals "" | FieldUpdate: Type_update_Prospect |  |
| Weekday Cap Changed | false | onAllChanges | Formula: `ISCHANGED(   weekday_cap__c    )` | FieldUpdate: Weekday_Cap_Changed |  |

### Field updates (18)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| AGP_to_Yes | AGP__c | Literal: 1 | false | false |
| Account_Record_Type | RecordTypeId | Lookup: RecordType Partner | false | false |
| Account_Type_Partner | Type | Literal: Partner | false | false |
| Change_Type_to_Locked | Type | Literal: Locked Account | false | false |
| Change_Type_to_Starter | Type | Literal: Starter | false | false |
| Is_Customer_Field_Update | Is_Customer__c | Literal: 1 | true | false |
| Last_Monthly_Review | Next_To_Last_Monthly_Review__c | Formula: `PRIORVALUE( Last_Monthly_Review__c )` | false | false |
| Lifecycle_Onboard | LifeCycle_Stage__c | Literal: Onboard | false | false |
| MasterID_Update | Master__c | Formula: `Parent.Name` | false | false |
| NumProducersUpdateTime | ProducersUpdateTime__c | Formula: `NOW()` | false | false |
| OfficesUpdateTIme | OfficesUpdateTime__c | Formula: `NOW()` | false | false |
| Prior_to_Last_Monthly_Review_Date | Prior_to_Last_Monthly_Review_Date__c | Formula: `TEXT( PRIORVALUE(  Last_Monthly_Review_Completed_Date_del__c  ) )` | false | false |
| Saturday_Cap_Change | Saturday_Cap_Changed__c | Formula: `NOW()` | false | false |
| Sunday_Cap_Changed | Sunday_Cap_Changed__c | Formula: `NOW()` | false | false |
| Type_update_Prospect | Type | Literal: Prospect | false | false |
| Update_FPD | First_Payment_Date__c | Formula: `Auto_Folio_Opt_in_Date__c` | false | false |
| Weekday_Cap_Changed | Weekday_Cap_changed__c | Formula: `NOW()` | false | false |
| Years_IN_business_update | YearsinBusinessUpdateTime__c | Formula: `NOW()` | false | false |

### Email alerts (2)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| CaseEmail_Template_Alert | CaseEmail Template Alert | unfiled$public/CaseEmail_Template | userLookup (Support_Rep__c) |  | CurrentUser |
| New_IO_Ready_for_CSM | New IO Ready for CSM Alert | Onboarding_Emails/New_IO_Ready_for_CSM | user [named user] |  | CurrentUser |

## CampaignMember

### Rules (1)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Facebook lead member created | false | onCreateOnly | Formula: `NOT(ISBLANK( LeadId )) &&  CampaignId = "7011a0000007rGy"` | Alert: New_Facebook_campaign_lead |  |

### Email alerts (3)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| LCS_Campaign_Member_alert | LCS Campaign Member alert | Sales_Available_Emails/Campaign_member_LCS_alert | user [named user] | [1 email(s) set] | CurrentUser |
| [name]_Campaign_Member | [name] Campaign Member | unfiled$public/BDR_Main_View | user [named user] |  | CurrentUser |
| New_Facebook_campaign_lead | New Facebook campaign lead | unfiled$public/New_Facebook_lead | campaignMemberDerivedOwner, user [named user] | [1 email(s) set] | CurrentUser |

## Case

### Rules (12)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Account Closure Record Type Update | true (migration failed) | onCreateOrTriggeringUpdate | Case.Customer_Support_Type__c equals "Account Closure" | FieldUpdate: Account_Closure_Updates |  |
| CF Terminations case detail update | false | onCreateOrTriggeringUpdate | Case.SuppliedEmail equals "[email set]"; Case.Subject equals "Terminated Representatives - Action Required" | FieldUpdate: Account_Closure_CF<br>FieldUpdate: Account_Closure_CF_reason<br>FieldUpdate: CF_Termination_High_Priority<br>FieldUpdate: Update_Subject |  |
| Cancellation Reason Slack | false | onCreateOrTriggeringUpdate | Case.Case_Results__c equals "Closed,Save"; Case.Customer_Support_Type__c equals "Account Closure"; Case.Status equals "Closed" | Alert: Cancellation_Reason_Slack |  |
| Case Record type to DNC | true (migration failed) | onCreateOrTriggeringUpdate | Case.Customer_Support_Type__c equals "DNC Request" | FieldUpdate: Record_type_to_DNC |  |
| Charge Attempts | false | onAllChanges | Formula: `ISCHANGED( Last_Charge_Attempt_Date__c )` | FieldUpdate: count_charge_attempts |  |
| Choice Lead Delivery Failure Auto close | false (migration failed) | onCreateOnly | Case.RecordTypeId equals "Lead Delivery Failure" | FieldUpdate: Close_Lead_Delivery_Failure_case |  |
| Core Business Review Completed Date | false | onCreateOrTriggeringUpdate | Case.RecordTypeId equals "Core Business Review"; Case.Case_Results__c equals "Completed Review" | FieldUpdate: CBR_Completed_Date_with_Close_Date |  |
| Move to Smart Campaign Queue | true (migration failed) | onCreateOrTriggeringUpdate | Case.Remove_Smart_Campaign__c equals "True" | FieldUpdate: Owner_Change_to_Smart_Campaign_Queue |  |
| Referral Credit Update Record Type | true (migration failed) | onCreateOrTriggeringUpdate | Case.Customer_Support_Type__c equals "Referral Credit" | FieldUpdate: Referral_Credit_Update_Record_Type |  |
| Send CSAT survey AGP first QBR | false | onCreateOrTriggeringUpdate | Case.Monthly_Calls_Review_QBR__c equals "First QBR" | FieldUpdate: Send_CSAT_survey_AGP_first_QBR |  |
| Transfer Date | false | onAllChanges | Formula: `AND ( LEFT(PRIORVALUE(OwnerId),3) = '00G', LEFT(OwnerId,3) = '005' )` | FieldUpdate: Case_Transfer_Date |  |
| Update initial solve date on first close | false | onCreateOrTriggeringUpdate | Case.Status equals "Closed"; Case.Initial_Solve_Date__c equals "" | FieldUpdate: Update_initial_solve_date_on_first_close |  |

### Field updates (16)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Account_Closure_CF | Customer_Support_Type__c | Literal: Account Closure | false | false |
| Account_Closure_CF_reason | Account_Closure__c | Literal: Office Closing | false | false |
| Account_Closure_Record_Update | RecordTypeId | Lookup: RecordType Account_Closure | false | false |
| Account_Closure_Updates | RecordTypeId | Lookup: RecordType Account_Closure | false | false |
| CBR_Completed_Date_with_Close_Date | Completed_Date__c | Formula: `TODAY ()` | false | false |
| CF_Termination_High_Priority | Priority | Literal: High | false | false |
| Case_Transfer_Date | Case_Transferred__c | Formula: `TODAY()` | false | false |
| ChangePriorityToHigh | Priority | Literal: High | false | false |
| Close_Lead_Delivery_Failure_case | Status | Literal: Closed | false | false |
| Owner_Change_to_Smart_Campaign_Queue | OwnerId | Lookup: Queue Smart_Campaign | false | false |
| Record_type_to_DNC | RecordTypeId | Lookup: RecordType DNC_Consumer | false | false |
| Referral_Credit_Update_Record_Type | RecordTypeId | Lookup: RecordType Referral_Credit | false | false |
| Send_CSAT_survey_AGP_first_QBR | Send_CSAT_survey_AGP_first_QBR__c | Literal: 1 | false | false |
| Update_Subject | Subject | Formula: `"Country Financial Account Closure"` | false | false |
| Update_initial_solve_date_on_first_close | Initial_Solve_Date__c | Formula: `NOW()` | false | false |
| count_charge_attempts | Charge_Attempts__c | Formula: `Charge_Attempts__c +1` | false | false |

### Email alerts (15)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| ASAccount_Closure_in_56_day_windows_as | Account Closure in 56 day window allstate | AM_CS_Email_Templates/Closure_in_56_day_window | user [named user] |  | DefaultWorkflowUser |
| Cancellation_Reason_Slack | Cancellation Reason Slack | Sales_Strategy_Ops/Cancellation_Reason_Slack |  | [1 email(s) set] | DefaultWorkflowUser |
| Case_Close_Alert | Case Close Alert | Sales_Strategy_Ops/Case_Complete_Notification | creator |  | DefaultWorkflowUser |
| Case_Email_Alert_to_owner_on_Creation_by_Fill_Rate | Case Email Alert to owner on Creation by Fill Rate | unfiled$public/CaseEmail_Template | owner |  | CurrentUser |
| Case_Escalation_1_[name] | Case Escalation 1 Alert - [name] | unfiled$public/SUPPORTCaseescalationnotification | user [named user] |  | DefaultWorkflowUser |
| Case_Escalation_1_[name] | Case Escalation 1 Alert [name] | unfiled$public/SUPPORTCaseescalationnotification | user [named user] |  | DefaultWorkflowUser |
| Case_Escalation_2_[name] | Case Escalation 2 Alert - [name] | unfiled$public/SUPPORTCaseescalationnotification | user [named user] |  | DefaultWorkflowUser |
| Case_Escalation_2_[name] | Case Escalation 2 Alert - [name] | unfiled$public/SUPPORTCaseescalationnotification | user [named user] |  | DefaultWorkflowUser |
| Core_IO_30_Call_Completed_alert | Core Day 30 Call Completed alert | Onboarding_Emails/Core_30day_Completed_Alert | user [named user] |  | DefaultWorkflowUser |
| FMAccount_Closure_in_56_day_window | Account Closure in 56 day window Farmers | AM_CS_Email_Templates/Closure_in_56_day_window | accountOwner, user [named user] |  | DefaultWorkflowUser |
| IAAccount_Closure_in_56_day_windows_ialife | Account Closure in 56 day window IA life | AM_CS_Email_Templates/Closure_in_56_day_window | accountOwner |  | DefaultWorkflowUser |
| Low_IBC_Billable_Rate_Warning_Alert | Low IBC Billable Rate Warning Alert | unfiled$public/Low_IBC_Billable_Rate_Warning | owner |  | CurrentUser |
| New_Case_Assignment | New Case Assignment | AM_CS_Email_Templates/Case_Assigned | owner |  | DefaultWorkflowUser |
| SFAccount_Closure_in_56_day_windowsf | Account Closure in 56 day window state far, | AM_CS_Email_Templates/Closure_in_56_day_window | accountOwner |  | DefaultWorkflowUser |
| Send_Email_Alert_when_the_Owner_is_changed | Send Email Alert when the Owner is changed | unfiled$public/Send_email_when_the_Case_Owner_is_changed | owner, user [named user] |  | CurrentUser |

## Contact

### Rules (10)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Contact Me Checkbox date | true | onCreateOrTriggeringUpdate | Contact.Contact_Me_Checkbox__c equals "True" | FieldUpdate: Contact_Me_Checkbox_date |  |
| Contact Me No Meeting Scheduled | false | onCreateOrTriggeringUpdate | Contact.BDR_meeting_set_on_task__c notEqual "Yes"; Contact.Contact_Me_Checkbox__c equals "True" | Alert: Contact_Me_not_Scheduled_on_Instant_Book_calender_of_the_BDR |  |
| Contact_Cityc_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(City__c)` |  |  |
| Contact_Statec_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(State__c)` |  |  |
| Contact_StreetAddressc_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(Street_Address__c)` |  |  |
| Contact_ZipCodec_Field_Changed | true (migration failed) | onAllChanges | Formula: `ISCHANGED(Zip_Code__c)` |  |  |
| Home Page contact me date | true | onCreateOrTriggeringUpdate | Contact.Home_Page_Check_box__c equals "True" | FieldUpdate: Home_Page_contact_me_date |  |
| Round Robin assigned contact mewebinar | false | onCreateOrTriggeringUpdate | Contact.Contact_Status__c equals "Assigned"; Contact.Update_Picklist__c equals "Contact me" | Alert: contactmeRound_Robin_Assigned_Alert |  |
| Round Robin assigned webinar | false | onCreateOrTriggeringUpdate | Contact.Contact_Status__c equals "Assigned"; Contact.Update_Picklist__c equals "Assigned" | Alert: Round_Robin_Assigned_Alert |  |
| Unqualified - Change owner | true (migration failed) | onCreateOrTriggeringUpdate | Contact.Contact_Status__c equals "Unqualified,Do Not Call,No Longer There" |  |  |

### Field updates (2)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Contact_Me_Checkbox_date | Contact_Me_Checkbox_date__c | Formula: `TODAY ()` | false | false |
| Home_Page_contact_me_date | Home_Page_Contact_Me_Date__c | Formula: `TODAY ()` | false | false |

### Email alerts (7)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| BDR_Main_View_Alert_Contact | BDR Main View Contact | Sales_Strategy_Ops/Main_View_Contact | user [named user], userLookup (BDR_Main_View__c) |  | DefaultWorkflowUser |
| Contact_Me_not_Scheduled_on_Instant_Book_calender_of_the_BDR | Contact Me not Scheduled on Instant Book calender of the BDR | Sales_Strategy_Ops/Ringlead_meeting_not_schedul | owner |  | DefaultWorkflowUser |
| LCS_Alert_Contact | LCS Alert Contact | Sales_Available_Emails/LCS_Alert | user [named user] | [1 email(s) set] | DefaultWorkflowUser |
| Low_Fill_Rate_Email_alert_To_be_Sent_to_Clients_For_AGP | Low Fill Rate Email alert - To be Sent to Clients For AGP | unfiled$public/Low_Fill_Rate_Email_Template_To_be_Sent_to_Clients_For_AGP | user [named user] |  | OrgWideEmailAddress |
| Low_Fill_Rate_Email_alert_To_be_Sent_to_Clients_For_Core_Starter | Low Fill Rate Email alert - To be Sent to Clients For Core / Starter | unfiled$public/Low_Fill_Rate_Email_Template_To_be_Sent_to_Clients_For_Core_Starter | user [named user] |  | OrgWideEmailAddress |
| Round_Robin_Assigned_Alert | Round Robin Assigned Alert | Sales_Available_Emails/Contact_Round_Robin_Assigned | owner |  | DefaultWorkflowUser |
| contactmeRound_Robin_Assigned_Alert | Round Robin Assigned Alert contact me | unfiled$public/Contact_Round_Robin_Assignedcontactme | owner |  | DefaultWorkflowUser |

### Outbound messages (3)

| Outbound message | Endpoint URL | Fields sent | Include session ID | Integration user |
|---|---|---|---|---|
| CSAT_Starter_Team_Delighted_Outbound | `https://delighted.com/integrations/salesforce/notification/custom/tEML...[token masked]` | Id | false | [user set] |
| LCS_Survey | `https://delighted.com/integrations/salesforce/notification/custom/H0hq...[token masked]` | Id | false | [user set] |
| LCS_Survey_2 | `https://delighted.com/integrations/salesforce/notification/custom/H0hq...[token masked]` | Id | false | [user set] |

## Customer_Success__c

### Rules (8)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Core First Monthly Completed | false | onCreateOrTriggeringUpdate | Customer_Success__c.First_Monthly_Call_Finalized__c equals "True"; Customer_Success__c.RecordTypeId equals "Core Onboarding" | FieldUpdate: Core_Monthly_review_completed |  |
| First Monthly Completed | false | onCreateOrTriggeringUpdate | Customer_Success__c.First_Monthly_Call_Finalized__c equals "True"; Customer_Success__c.RecordTypeId equals "AGP Onboarding" | FieldUpdate: SecondMonth |  |
| Intro Completed | false | onCreateOrTriggeringUpdate | Customer_Success__c.Intro_Call_Finalized__c equals "True" (logic: 1) | FieldUpdate: Intro_Call_Finalized_Date<br>FieldUpdate: Update_Stage_to_Training |  |
| Onboarding Complete Date | false | onCreateOrTriggeringUpdate | Customer_Success__c.Onboarding_complete__c equals "True" | FieldUpdate: Onboarding_Complete_Date |  |
| Second Monthly Completed | false | onCreateOrTriggeringUpdate | Customer_Success__c.Second_Monthly_Call_Finalized__c equals "True"; Customer_Success__c.RecordTypeId equals "AGP Onboarding" | FieldUpdate: qbr |  |
| Third Monthly Completed | false | onCreateOrTriggeringUpdate | Customer_Success__c.Onboarding_complete__c equals "True" | FieldUpdate: Closed_Won |  |
| Training Completed | false | onCreateOrTriggeringUpdate | Customer_Success__c.Training_Finalized__c equals "True"; Customer_Success__c.RecordTypeId equals "AGP Onboarding" | FieldUpdate: First_Monthly_Review_Stage |  |
| Training Completed Core | false | onCreateOrTriggeringUpdate | Customer_Success__c.Training_Finalized__c equals "True"; Customer_Success__c.RecordTypeId equals "Core Onboarding" | FieldUpdate: Core_TrainingCompleted |  |

### Field updates (9)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Closed_Won | Stage__c | Literal: Closed Won | false | false |
| Core_Monthly_review_completed | Stage__c | Literal: Quarterly Review | false | false |
| Core_TrainingCompleted | Stage__c | Literal: 30 Day Check-In | false | false |
| First_Monthly_Review_Stage | Stage__c | Literal: 1st Monthly Review | false | false |
| Intro_Call_Finalized_Date | Intro_Call_Finalized_Date__c | Formula: `TODAY ()` | false | false |
| Onboarding_Complete_Date | Onboarding_Complete_Date__c | Formula: `TODAY ()` | false | false |
| SecondMonth | Stage__c | Literal: 2nd Monthly Review | false | false |
| Update_Stage_to_Training | Stage__c | Literal: Agency Training | false | false |
| qbr | Stage__c | Literal: 3rd Monthly Review | false | false |

## EmailMessage

### Rules (1)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Reopen Closed Case on New Email | true (migration failed) | onCreateOrTriggeringUpdate | EmailMessage.Incoming equals "True"; Case.IsClosed equals "True" | FieldUpdate: Reopen_Closed_Case_on_New_Email |  |

### Field updates (1)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Reopen_Closed_Case_on_New_Email | ParentId.Status (cross-object) | Literal: Open | false | false |

## Event

### Rules (1)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| BDR Meeting Event | false | onCreateOrTriggeringUpdate | Event.Meeting_Purpose__c equals "BDR Meeting"; Event.Meeting_Result__c equals "No Show" | Alert: BDR_Meeting_on_event |  |

### Email alerts (1)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| BDR_Meeting_on_event | BDR Meeting on event | Agency_Sales/BDR_Meeting_Event | creator |  | CurrentUser |

## File_a_Ticket__c

### Rules (4)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| ODA Notify Request | false | onCreateOrTriggeringUpdate | File_a_Ticket__c.Category__c equals "Referred Case Status Request,Post-Issue Policy Request" | Alert: Notify_[name] |  |
| ODA Notify SF Support Users | false | onCreateOrTriggeringUpdate | File_a_Ticket__c.Category__c equals "Salesforce issue" | Alert: Notify_Support_Contacts_of_new_ticket |  |
| ODA Notify Sales or Lumico Support Users | false | onCreateOrTriggeringUpdate | File_a_Ticket__c.Category__c equals "Customer or Sales process issue,Lumico e-app issue" | Alert: Notify_[name]_when_Customer_or_Sales_process_or_Lumico_e_app_issue |  |
| ODA Notify Twilio Support Users | false | onCreateOrTriggeringUpdate | File_a_Ticket__c.Category__c equals "Twilio issue,Other issue" | Alert: Notify_Twilio_Support_Contacts_of_new_ticket |  |

### Email alerts (4)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| Notify_[name]_when_Customer_or_Sales_process_or_Lumico_e_app_issue | Notify [name] when Customer or Sales process or Lumico e-app issue | unfiled$public/ODA_Ticket_Notification | user [named user] |  | CurrentUser |
| Notify_[name] | Notify [name] | unfiled$public/ODA_Ticket_Notification | user [named user] |  | CurrentUser |
| Notify_Support_Contacts_of_new_ticket | Notify Support Contacts of new ticket | unfiled$public/ODA_Ticket_Notification | user [named user] |  | CurrentUser |
| Notify_Twilio_Support_Contacts_of_new_ticket | Notify Twilio Support Contacts of new ticket | unfiled$public/ODA_Ticket_Notification | user [named user] |  | CurrentUser |

## Lead

### Rules (31)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Contact Me Checkbox date | false | onCreateOrTriggeringUpdate | Lead.Contact_Me_checkbox__c equals "True" | FieldUpdate: Contact_Me_Checkbox_date |  |
| Date Added to Waitlist | false | onCreateOrTriggeringUpdate | Lead.Status equals "Waitlist" | FieldUpdate: Date_Added_to_Waitlist |  |
| Delete Company from Life Leads | false | onAllChanges | Lead.RecordTypeId equals "Life Leads"; Lead.Company notEqual "" | FieldUpdate: Delete_Company |  |
| Email test | false | onCreateOrTriggeringUpdate | Lead.Campaign__c equals "test" | Alert: email_test |  |
| Home Page Contact Me Date | false | onCreateOrTriggeringUpdate | Lead.Home_Page_Checkbox__c equals "True" | FieldUpdate: Home_Page_Contact_Me_Date |  |
| Lead Agency Update | false | onAllChanges | Formula: `OR( Company = "agency", Company ="agency-", Company ="Agency", Company ="Agency-", Company ="Unknown-", Company ="Unknown", Company ="unknown-", Company ="unknown", Company =Account1__r.Carrier__r.Name )` | FieldUpdate: Lead_Agency_Update |  |
| Lead Assigned Send Round Robin webinar | false | onCreateOrTriggeringUpdate | Lead.Status equals "Assigned"; Lead.Update_Picklist__c equals "Dummy" | Alert: Round_Robin_Assigned_Alert |  |
| Lead Carrier Update | false | onAllChanges | Formula: `OR(Company = Carrier__r.Name, Company = "SF")` | FieldUpdate: Carrier_Update |  |
| Lead Lost Date%2FTime | false | onAllChanges | Lead.Status equals "Lost" | FieldUpdate: Lead_Lost_Date_Time |  |
| Lead Source Email | false | onCreateOrTriggeringUpdate | Lead.Lead_Source_Update__c equals "Email"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_Email |  |
| Lead Source List Import | false | onCreateOrTriggeringUpdate | Lead.Lead_Source_Update__c equals "List Import"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_List_Import |  |
| Lead Source Live Event | false | onAllChanges | Lead.Lead_Source_Update__c equals "Live Event"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_Live_Event |  |
| Lead Source Outbound Call | false | onCreateOrTriggeringUpdate | Lead.Lead_Source_Update__c equals "Outbound Call"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_Outbound_Call |  |
| Lead Source Referral | false | onCreateOrTriggeringUpdate | Lead.Lead_Source_Update__c equals "Referral"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_Referral |  |
| Lead Source Search | false | onCreateOrTriggeringUpdate | Lead.Lead_Source_Update__c equals "Search"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_Search |  |
| Lead Source Webinar | false | onCreateOrTriggeringUpdate | Lead.Lead_Source_Update__c equals "Webinar"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_Webinar |  |
| Lead Source ZoomInfo | false | onCreateOrTriggeringUpdate | Lead.Lead_Source_Update__c equals "ZoomInfo"; Lead.LeadSource equals "" | FieldUpdate: Lead_Source_ZoomInfo |  |
| Lead Status to Sales Available | false | onAllChanges | Formula: `AND( ISCHANGED( OwnerId ),  LEFT( OwnerId, 3) = '005',  ISPICKVAL(Status, 'Lost'))` | FieldUpdate: Lost_Reason_to_Blank<br>FieldUpdate: Lost_to_Sales_Available<br>FieldUpdate: Reset_Call_Count |  |
| Lead%3A Duplicate Queue | true (migration failed) | onAllChanges | Lead.Status equals "Duplicate"; Lead.IsConverted equals "False" | FieldUpdate: Owner_Duplicate_Queue |  |
| No Show Lead to True | true (migration failed) | onCreateOrTriggeringUpdate | Lead.Lead_owner_changed__c equals "True" |  | [1 Hours from ] |
| Recycle Lost Leads | true (migration failed) | onCreateOrTriggeringUpdate | Lead.Status equals "Lost"; Lead.RecordTypeId notEqual "Life Leads" | FieldUpdate: Change_Owner_to_RLQ<br>FieldUpdate: Recycle_Lost_Date_Update |  |
| Referral Rock Email Notification | false | onCreateOrTriggeringUpdate | Lead.Referral_Rock_Lead__c equals "True" | Alert: Referral_ROckt |  |
| Revert Back Do Not Call Leads | true (migration failed) | onCreateOrTriggeringUpdate | Lead.DoNotCall equals "False"; Lead.RecordTypeId equals "Do Not Call" | FieldUpdate: Set_Lead_Record_Type_to_Default |  |
| Set Lead Status Closed | false | onCreateOrTriggeringUpdate | Lead.Lead_Outcome__c equals "Outbound Call - Bad Data,Knock Out - US Citizen,Do Not Call,Call Dropped,Lead Not Qualified" | FieldUpdate: Set_Lead_Status_to_Closed |  |
| Set Lead Status Follow-up | false | onCreateOrTriggeringUpdate | Lead.Lead_Outcome__c equals "App. Complete - Referred,App. Complete - Payment Issue" | FieldUpdate: ODA_Set_Lead_to_Follow_up |  |
| Set Lead Status Nurture | false | onCreateOrTriggeringUpdate | Lead.Lead_Outcome__c equals "Not In Market - High Face Amount,Not In Market - Term Insurance,Not In Market - Other,Knock Out - Replacement,Knock Out - Health,Quote Given - Not Interested,App. Complete - Declined,App. Complete - Other Non-Sale,No Sale - Ineligible,Lead Not Qualified" | FieldUpdate: ODA_Set_Lead_to_Nurture |  |
| Set Lead Status Won | false | onCreateOrTriggeringUpdate | Lead.Lead_Outcome__c equals "App. Complete - SALE" | FieldUpdate: Set_Lead_Status_Won |  |
| Unqualified%3A Commercial Agents | true (migration failed) | onCreateOrTriggeringUpdate | Lead.IsConverted equals "False"; Lead.Status equals "Unqualified"; Lead.Unqualified_Reason__c equals "Commercial Agent" | FieldUpdate: Owner_Commercial_Agents |  |
| Unqualified%3A Consumer | true (migration failed) | onCreateOrTriggeringUpdate | Lead.IsConverted equals "False"; Lead.Status equals "Unqualified"; Lead.Unqualified_Reason__c equals "Consumer" | FieldUpdate: Owner_Cosumer |  |
| Unqualified%3A Invalid Contact Info | true (migration failed) | onCreateOrTriggeringUpdate | Lead.IsConverted equals "False"; Lead.Status equals "Unqualified"; Lead.Unqualified_Reason__c equals "Invalid Contact Info" | FieldUpdate: Owner_Invalid_Contact_Info |  |
| Unqualified%3A Unqualified | true (migration failed) | onCreateOrTriggeringUpdate | Lead.IsConverted equals "False"; Lead.Status equals "Unqualified"; Lead.Unqualified_Reason__c equals "Language Barrier,Business Closed,Non-PNC,Retiring" | FieldUpdate: Owner_Unqualified_Queue |  |

### Field updates (31)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Carrier_Update | Company | Formula: `FirstName &" "&  LastName &" "&  Carrier__r.Name` | false | false |
| Change_Owner_to_RLQ | OwnerId | Lookup: Queue Recycled_Leads_Queue | false | false |
| Contact_Me_Checkbox_date | Contact_Me_Checkbox_date__c | Formula: `TODAy()` | false | false |
| Date_Added_to_Waitlist | Added_to_Waitlist_Date__c | Formula: `TODAY()` | false | false |
| Delete_Company | Company | Null (blank) | false | false |
| Home_Page_Contact_Me_Date | Home_Page_Contact_Me_Date__c | Formula: `TODAY ()` | false | false |
| Lead_Agency_Update | Company | Formula: `FirstName&" "& LastName&" "&"Agency"` | true | false |
| Lead_Lost_Date_Time | Lead_Lost__c | Formula: `Now()` | false | false |
| Lead_Source_Email | LeadSource | Literal: Email | false | false |
| Lead_Source_List_Import | LeadSource | Literal: List Import | false | false |
| Lead_Source_Live_Event | LeadSource | Literal: Live Event | false | false |
| Lead_Source_Outbound_Call | LeadSource | Literal: Outbound Call | false | false |
| Lead_Source_Referral | LeadSource | Literal: Referral | false | false |
| Lead_Source_Search | LeadSource | Literal: Search | false | false |
| Lead_Source_Webinar | LeadSource | Literal: Webinar | false | false |
| Lead_Source_ZoomInfo | LeadSource | Literal: Zoominfo | false | false |
| Lost_Reason_to_Blank | Lost_Reason__c | Literal: | false | false |
| Lost_to_Sales_Available | Status | Literal: Sales Available | false | false |
| ODA_Set_Lead_to_Follow_up | Status | Literal: Follow-up | false | false |
| ODA_Set_Lead_to_Nurture | Status | Literal: Nurture | false | false |
| Owner_Commercial_Agents | OwnerId | Lookup: Queue Commercial_Agents | false | false |
| Owner_Cosumer | OwnerId | Lookup: Queue Consumer | false | false |
| Owner_Duplicate_Queue | OwnerId | Lookup: Queue Duplicates | false | false |
| Owner_Invalid_Contact_Info | OwnerId | Lookup: Queue Invalid_Contact_Info | false | false |
| Owner_Unqualified_Queue | OwnerId | Lookup: Queue Unqualified | false | false |
| Recycle_Lost_Date_Update | Recycled_Date__c | Formula: `Now ()` | false | false |
| Reset_Call_Count | Call_Count__c | Formula: `0` | false | false |
| Set_Lead_Record_Type_to_Default | RecordTypeId | Lookup: RecordType Default | true | false |
| Set_Lead_Status_Won | Status | Literal: Won | false | false |
| Set_Lead_Status_to_Closed | Status | Literal: Closed | false | false |
| change_to_DNC_record_type | RecordTypeId | Lookup: RecordType Do_Not_Call | false | false |

### Email alerts (9)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| BDR_Main_View_Alert_Lead | BDR Main View Lead | Sales_Strategy_Ops/Lead_Main_View | user [named user], userLookup (BDR_Main_View__c) |  | DefaultWorkflowUser |
| BDR_Main_View_Lead2 | BDR Main View Lead 2 | Sales_Strategy_Ops/Lead_Main_View | user [named user], userLookup (BDR_Main_View__c) |  | DefaultWorkflowUser |
| Referral_ROck | Referral ROck | unfiled$public/Referral_Notification | user [named user] |  | DefaultWorkflowUser |
| Referral_ROckt | Test Referral ROck | unfiled$public/Referral_Notification | user [named user] |  | DefaultWorkflowUser |
| Referral_from_BDR_or_CSM_[name] | Referral from BDR or CSM- [name] | unfiled$public/Referral_from_AM | user [named user] |  | DefaultWorkflowUser |
| Referral_from_BDR_or_CSM_[name] | Referral from BDR or CSM- [name] | unfiled$public/Referral_from_AM | user [named user] |  | DefaultWorkflowUser |
| Referral_from_BDR_or_CSM_[name] | Referral from BDR or CSM- [name] | unfiled$public/Referral_from_AM | user [named user] |  | DefaultWorkflowUser |
| Round_Robin_Assigned_Alert | Round Robin Assigned Alert | Sales_Available_Emails/Lead_Round_Robin_Assigned | owner |  | DefaultWorkflowUser |
| email_test | email test | Sales_Strategy_Ops/proLead_Round_Robin_Assigned | user [named user] |  | DefaultWorkflowUser |

### Tasks (1)

| Task action | Subject | Assigned to type | Due (days offset) | Status | Priority |
|---|---|---|---|---|---|
| Lead_On_Pro_Please_Contact | Lead On Pro. Please Contact! | owner | 0 | Not Started | Normal |

## Opportunity

### Rules (19)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| AGP IO Notification | false | onCreateOrTriggeringUpdate | Opportunity.RecordTypeId equals "Accelerated-AGP"; Opportunity.Insertion_Order_Attached__c equals "True"; Opportunity.Support_Rep__c equals "" | Alert: AGP_IO_attached_email_alert |  |
| Anchor | false | onCreateOnly | Formula: `AND( NOT(ISBLANK(Name)), OR(RecordTypeId = '0121a000000EqqS', RecordTypeId = '0121a000000RNO1', RecordTypeId = '012290000004YWz') )` | FieldUpdate: Opportunity_Name_Update |  |
| Close date is 14 days after creation | false | onCreateOnly | Opportunity.Name notEqual ""; Opportunity.CreatedById notContain "[name]"; Opportunity.RecordTypeId equals "Agency" | FieldUpdate: Closed_Date_to_2_weeks_from_created_date |  |
| Closed Won | true (migration failed) | onAllChanges | Opportunity.StageName equals "Closed Won"; Opportunity.Notes_for_CSM__c notEqual "" | FieldUpdate: Notes_from_Sales |  |
| Core IO Win | true (migration failed) | onCreateOrTriggeringUpdate | Opportunity.StageName equals "Closed Won"; Opportunity.RecordTypeId equals "Agency"; Opportunity.Core_IO__c equals "True" | Alert: Core_IO_Win_Alert<br>FieldUpdate: Core_IO_Win_Date_f |  |
| Exhaust Upsell | false | onCreateOrTriggeringUpdate | Opportunity.Call_Count__c greaterOrEqual "10"; Opportunity.RecordTypeId equals "Upsell" | FieldUpdate: Closed_Lost_Date_Updated<br>FieldUpdate: Lost_Reason_Exhausted<br>FieldUpdate: Stage_to_Lost |  |
| ISR Referral AGP Closed Won | false | onCreateOrTriggeringUpdate | Opportunity.ISR_Owner__c notContain ""; Opportunity.StageName equals "Closed Won"; Opportunity.RecordTypeId equals "Accelerated" | Alert: ISR_Opportunity_Referral_Closed_Won_by_AGP |  |
| Mark CORE IO Win | true (migration failed) | onCreateOrTriggeringUpdate | Opportunity.StageName equals "Closed Won"; Opportunity.Core_IO__c equals "True" | FieldUpdate: Core_IO_Win<br>FieldUpdate: Core_IO_Win_Date |  |
| Opp Current State is Not Blank | true | onCreateOrTriggeringUpdate | Formula: `NOT ISBLANK(   CurrentState__c  )` | FieldUpdate: Current_State_has_text_now |  |
| Opp Current is Blank | true | onAllChanges | Formula: `ISBLANK(   CurrentState__c  )` | FieldUpdate: Current_State_is_Blank |  |
| Opp Future State is Blank | true | onAllChanges | Formula: `ISBLANK(   FutureState__c  )` | FieldUpdate: Future_State_is_Blank |  |
| Opp Future State is Not Blank | true | onCreateOrTriggeringUpdate | Formula: `NOT ISBLANK(   FutureState__c  )` | FieldUpdate: Future_State_now_has_text |  |
| Opp Gap is Blank | true | onAllChanges | Formula: `ISBLANK(  Gap__c )` | FieldUpdate: Opp_Gap_is_Blank |  |
| Opp Gap is Not Blank | true | onCreateOrTriggeringUpdate | Formula: `NOT ISBLANK(  Gap__c )` | FieldUpdate: Opp_Gap_Now_Has_Text |  |
| Push Counter | false | onAllChanges | Formula: `IF(  CloseDate > PRIORVALUE( CloseDate ),  IF (MONTH(CloseDate) <> MONTH(PRIORVALUE( CloseDate )) ,  TRUE,  FALSE),  FALSE)` | FieldUpdate: Increment_Push_Counter_Field |  |
| Referral Rock Integration - Agency | true (migration failed) | onCreateOrTriggeringUpdate | Opportunity.StageName equals "Closed Won"; Opportunity.RecordTypeId equals "Agency"; Account.AGP_Pass_up_Closed_Won__c notEqual "True" |  |  |
| Update Amount | false | onAllChanges | Formula: `OR( Not( Amount =  Account.Carrier__r.ARPA_Enrolled__c   ), ISBLANK(Amount))` | FieldUpdate: Amount_of_Opportunity |  |
| Update Closed Lost date | false | onCreateOrTriggeringUpdate | Opportunity.StageName equals "Closed Lost" | FieldUpdate: Closed_Lost_Date_Updated |  |
| Update stage to Pending | true (migration failed) | onCreateOrTriggeringUpdate | Opportunity.RecordTypeId equals "Upsell"; Opportunity.next_due_date__c greaterThan "TODAY"; Opportunity.StageName notEqual "Closed Won,Closed Lost" | FieldUpdate: Stage_to_Pending |  |

### Field updates (27)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| AGP_Closed | AccountId.AGP_Pass_up_Closed_Won__c (cross-object) | Literal: 1 | false | false |
| AGP_Closed_Won | AGP_Closed_Won__c | Literal: Yes | false | false |
| AGP_Passup_to_closed_won | AccountId.AGP_Pass_up_Closed_Won__c (cross-object) | Literal: 1 | false | false |
| Advertiser_Opp_Name_Update | Name | Formula: `Account.Name &"-"& IF(ISPICKVAL( Category__c , 'Pilot'),'Pilot',IF(ISPICKVAL(Category__c, 'Perpetual'),'Perpetual','')) &"-"&  IF(ISPICKVAL( Product__c , 'Calls'),'Calls',IF(ISPICKVAL( Product__c , 'Leads'),'Leads', IF(ISPICKVAL( Product__c , 'Clicks'),'Clicks','')))&"-"& IF(ISPICKVAL(Prod ... | false | false |
| Amount_of_Opportunity | Amount | Formula: `Account.Carrier__r.ARPA_Enrolled__c` | false | false |
| Closed_Date_to_2_weeks_from_created_date | CloseDate | Formula: `CreatedDate + 14` | false | false |
| Closed_Lost_Date_Updated | CloseDate | Formula: `TODAY()` | false | false |
| Core_IO_Win | AccountId.Update__c (cross-object) | Literal: Core IO Win | false | false |
| Core_IO_Win_Date | AccountId.Core_IO_Win_Date__c (cross-object) | Formula: `TODAY ()` | false | false |
| Core_IO_Win_Date_f | AccountId.Core_IO_Win_Date__c (cross-object) | Formula: `TODAY ()` | false | false |
| Current_State_has_text_now | Opp_Current_State_is_blank__c | Literal: 0 | false | false |
| Current_State_is_Blank | Opp_Current_State_is_blank__c | Literal: 1 | false | false |
| Everlife_Add_phone_number_to_oppty | Customer_Phone_Number__c | Formula: `Account.PersonContact.Phone` | false | false |
| Everlife_Set_Close_Date_45_Days_Out | CloseDate | Formula: `CreatedDate +45` | false | false |
| Future_State_is_Blank | Opp_Future_State_is_Blank__c | Literal: 1 | false | false |
| Future_State_now_has_text | Opp_Future_State_is_Blank__c | Literal: 0 | false | false |
| Increment_Push_Counter_Field | Push_Counter__c | Formula: `IF(  ISNULL( Push_Counter__c ),  1,  Push_Counter__c + 1  )` | false | false |
| Lost_Reason_Exhausted | Lost_Reason__c | Literal: Exhausted | false | false |
| Notes_from_Sales | AccountId.Notes_from_Sales__c (cross-object) | Formula: `Notes_for_CSM__c` | false | false |
| Opp_Gap_Now_Has_Text | Opp_Gap_is_blank__c | Literal: 0 | false | false |
| Opp_Gap_is_Blank | Opp_Gap_is_blank__c | Literal: 1 | false | false |
| Opportunity_Name_Update | Name | Formula: `Account.Name &"- "& Account.Carrier__r.Name &" -"&Text(DATEVALUE(CreatedDate))` | false | false |
| Set_Opportunity_Name_for_Everlife | Name | Formula: `Account.FirstName&" "& Account.LastName&"- "& Account.Carrier__r.Name &" -"&Text(DATEVALUE(CreatedDate))` | false | false |
| Stage_to_Lost | StageName | Literal: Closed Lost | false | false |
| Stage_to_Pending | StageName | Literal: Pending | false | false |
| TICA_to_account | AccountId.TICA__c (cross-object) | Literal: Yes | false | false |
| test | Campaign__c | Formula: `"Test"` | false | false |

### Email alerts (12)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| AGP_IO_attached_email_alert | AGP IO attached email alert | AM_CS_Email_Templates/AGP_IO_Notification | user [named user] |  | DefaultWorkflowUser |
| BC_notification_of_assigned_account_after_AGP_opp_closed_wo | BC notification of assigned account after AGP opp closed wo | Sales_Strategy_Ops/Support_Rep_Notify_Assigned | userLookup (Business_Consultant__c), userLookup (Support_Rep__c) |  | DefaultWorkflowUser |
| Closed_Won_Primary_Campaign_Class_List_Referral_Fields_Not_Completed | Closed Won Primary Campaign Class List Referral Fields Not Completed | [name]/Referrals_for_Class_Lists_Not_Populated | owner, user [named user] |  | DefaultWorkflowUser |
| Core_IO_Support_rep_assignment | Core IO Support rep assignment | Sales_Strategy_Ops/Core_IO_notification_to_CSM_assigned | owner, user [named user], userLookup (Support_Rep__c) |  | CurrentUser |
| Core_IO_Win_Alert | Core IO Win Alert | Onboarding_Emails/Core_IO_Win_Alert |  | [1 email(s) set] | DefaultWorkflowUser |
| ISR_Opportunity_Referral_Closed_Won_by_AGP | ISR Opportunity Referral Closed Won by AGP | Agency_Sales/ISR_Referral_AGP_Closed_Won | user [named user] |  | DefaultWorkflowUser |
| New_IO_Ready_for_CSM_Alert_via_Oppty | New IO Ready for CSM Alert via Oppty | Onboarding_Emails/New_IO_Ready_for_CSM | user [named user] |  | DefaultWorkflowUser |
| New_Onboarding_Record_Alert | New Onboarding Record Alert | unfiled$public/New_Onboarding_Record | userLookup (Onboarding_Owner__c) |  | DefaultWorkflowUser |
| Partnerstack_referral_alert | Partnerstack referral alert | Sales_Strategy_Ops/Partnerstack_Referral_Notication | owner |  | DefaultWorkflowUser |
| State_Farm_AGP_alert | State Farm AGP alert | [name]/[name]Close | user [named user] |  | DefaultWorkflowUser |
| Tier_Mvmt_BC_Assigned_BC_Sales | Tier Mvmt: BC Assigned (BC, Sales) | Segmentation/Tier_Mvmt_BC_Assigned | owner, userLookup (Business_Consultant__c) | [1 email(s) set] | DefaultWorkflowUser |
| allstateClosed_Won_Primary_Campaign_Class_List_Referral_Fields_Not_Completed | Closed Won Primary Campaign Allstate Class List Referral Fields Not Completed | [name]/Referrals_for_Class_Lists_Not_Populated | owner, user [named user] |  | DefaultWorkflowUser |

## OpportunityLineItem

### Rules (2)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Opportunity Product Update | false | onCreateOrTriggeringUpdate | OpportunityLineItem.LCS__c equals "True" | FieldUpdate: Opportunity_Product_Update |  |
| Product%3A update date | false | onCreateOrTriggeringUpdate | Formula: `ServiceDate <>  Opportunity.CloseDate` | FieldUpdate: Product_Update_Date |  |

### Field updates (2)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Opportunity_Product_Update | Product__c | Formula: `Product2.Name` | false | false |
| Product_Update_Date | ServiceDate | Formula: `Opportunity.CloseDate` | false | false |

## SocialPost

### Rules (1)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Manager notification | false | onCreateOrTriggeringUpdate | SocialPost.KeywordGroupName contains "question" | Alert: Notify_Chatter_Group_Question |  |

### Email alerts (1)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| Notify_Chatter_Group_Question | Notify Chatter Group Question | unfiled$public/Chatter_Group_Email_Notificaiton | user [named user] |  | CurrentUser |

## Survey_Response_Customer_Support_Survey__c

### Email alerts (1)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| email_alert_for_task_creation_on_csat_survey_response_of_2 | email alert for task creation on csat survey response of 2 | AM_CS_Email_Templates/CSAT_email_alert_for_rating_of_2 | userLookup (Case_Owner_ID__c) |  | CurrentUser |

## Task

### Rules (6)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Callback Follow-up | true (migration failed) | onCreateOrTriggeringUpdate | Task.Call_Outcome__c equals ""Callback scheduled, still in market"" | Task: Follow_up_with_Lead |  |
| Update Contact Field on Activity | true (migration failed) | onCreateOrTriggeringUpdate | Task.CallDisposition equals "Spoke to Decision Maker"; Task.CallDisposition equals "Spoke to Non Decision Maker"; Task.CallDisposition equals "Live Message" (logic: 1 OR 2 OR 3) |  |  |
| Update Correct Contact | true (migration failed) | onCreateOrTriggeringUpdate | Task.CallDisposition equals "Spoke to Decision Maker" |  |  |
| Update IsLead for activity on lead | false | onCreateOnly | Formula: `BEGINS(WhoId , "00Q")` | FieldUpdate: isLead_field_update |  |
| Update type to Email | false | onCreateOrTriggeringUpdate | Formula: `BEGINS( Subject  , "Email:")` | FieldUpdate: Update_type_to_Email |  |
| task type for calls | false | onCreateOnly | Task.Subject equals "Outbound Call,Inbound Call" | FieldUpdate: task_type_for_calls |  |

### Field updates (3)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Update_type_to_Email | Type | Literal: Email | false | false |
| isLead_field_update | isLead__c | Literal: 1 | false | false |
| task_type_for_calls | Type | Literal: Call | false | false |

### Email alerts (8)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| Case_Follow_up_after_10_days_Alert | Case Follow up after 10 days	Alert | unfiled$public/Case_Follow_up_after_10_days | owner |  | OrgWideEmailAddress |
| Case_Follow_up_after_14_days_Alert | Case Follow up after 14 days	Alert | unfiled$public/Case_Follow_up_after_14_days | owner |  | CurrentUser |
| No_show_alert | No show alert | Sales_Strategy_Ops/No_show_alert | creator |  | DefaultWorkflowUser |
| Notify_fresh_hot_task_assigned | Notify fresh/hot task assigned | unfiled$public/Task_Fresh_Hot_Lead | owner |  | CurrentUser |
| Notify_new_task_was_assigned | Notify new task was assigned | unfiled$public/New_Task_Assigned_v2 | owner |  | CurrentUser |
| Notify_users_when_an_existing_task_was_assigned_to_them | Notify users when an existing task was assigned to them | unfiled$public/Existing_Task_assigned | owner |  | CurrentUser |
| ODA_call_requires_your_attention | ODA call requires your attention | unfiled$public/ODA_Notification |  | [2 email(s) set] | CurrentUser |
| Task_Assigned | Task Assigned | unfiled$public/New_Task_Assigned | owner |  | CurrentUser |

### Tasks (1)

| Task action | Subject | Assigned to type | Due (days offset) | Status | Priority |
|---|---|---|---|---|---|
| Follow_up_with_Lead | Follow up with Lead | owner | 2 | Not Started | Normal |

## Team_Member__c

### Rules (1)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| Update Team Member Information | false | onAllChanges | Formula: `1=1` | FieldUpdate: Update_Team_Member_Role<br>FieldUpdate: Update_Team_Members_ID |  |

### Field updates (2)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Update_Team_Member_Role | Team_Member_Role__c | Formula: `Team_Member_Name__r.UserRole.Name` | false | false |
| Update_Team_Members_ID | Name | Formula: `Team_Member_Name__r.Id` | false | false |

## Time_Off_Request__c

### Field updates (2)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Rejected | Rejected__c | Literal: 1 | false | false |
| Time_Off_Approved | Approved__c | Literal: 1 | false | false |

### Email alerts (2)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| Time_off_Request_Denied | Time off Request Denied | unfiled$public/Time_Off_Denied | owner |  | CurrentUser |
| Time_off_Request_approved | Time off Request approved | unfiled$public/Time_Off_Approved | owner |  | CurrentUser |

## User

### Rules (1)

| Rule | Active | Evaluation | Criteria | Immediate actions | Time-based actions |
|---|---|---|---|---|---|
| User%3A Check box to update team member when role changed | false | onAllChanges | Formula: `ISCHANGED( UserRoleId )` | FieldUpdate: Check_box_to_update_the_member_s_role |  |

### Field updates (1)

| Field update | Field | New value | Re-evaluate rules | Notify assignee |
|---|---|---|---|---|
| Check_box_to_update_the_member_s_role | Update_User_s_Team_Member_Role__c | Literal: 1 | false | false |

### Email alerts (2)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| ODA_Alert | ODA Alert | unfiled$public/ODA_Manager_changed_a_role | user [named user] |  | CurrentUser |
| ODA_manager_changed_role | ODA manager changed role | unfiled$public/ODA_Manager_changed_a_role | user [named user] |  | CurrentUser |

## VoiceCall

### Email alerts (2)

| Alert | Description | Template | Recipient types | Additional emails | Sender type |
|---|---|---|---|---|---|
| Missed_Call_Email_Alert | Missed Call Email Alert | unfiled$public/Send_Missed_Call_Template | owner |  | OrgWideEmailAddress |
| Send_Email_without_Contact_on_MissedCall | Send Email without Contact on MissedCall | unfiled$public/Send_Missed_Call_Template_Without_Contact | owner |  | OrgWideEmailAddress |

