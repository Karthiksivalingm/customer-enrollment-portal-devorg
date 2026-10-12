# Flows

_Generated 2026-10-12 from `force-app/main/default/flows`._

| Flow (API name) | Label | Type | Object | Trigger | Status | Description |
|---|---|---|---|---|---|---|
| `Account_Auto_Populate_Offboarding_Date_and_User` | Account - Auto-Populate Offboarding Date and User | AutoLaunchedFlow | Account | RecordAfterSave / Update | **Obsolete** | Account - Auto-Populate Offboarding Date and User |
| `Account_Cluster_Automation` | Account Cluster Automation | AutoLaunchedFlow | Account | RecordAfterSave / CreateAndUpdate | **InvalidDraft** |  |
| `Auto_Assign_Pricebook_Based_on_Account_Country` | Auto Assign Pricebook Based on Account Country | AutoLaunchedFlow | Opportunity | RecordBeforeSave / CreateAndUpdate | **Active** |  |
| `Campaign_member_creation` | Campaign member creation | AutoLaunchedFlow | Contact | RecordAfterSave / CreateAndUpdate | **Draft** |  |
| `Case_Team_Assignment_based_on_the_Email_to_case` | Case Team Assignment based on the Email to case | AutoLaunchedFlow | Case | RecordAfterSave / CreateAndUpdate | **Draft** |  |
| `Copy_Routing_Email_to_Case` | Copy Routing Email to Case | AutoLaunchedFlow | EmailMessage | RecordAfterSave / Create | **Active** |  |
| `Copy_the_Field_values_from_Lead_to_Store` | Copy the Field values from Lead to Store | AutoLaunchedFlow | Lead | RecordAfterSave / CreateAndUpdate | **Active** | Update Store records to automatically copy Parent Vertical, Vertical, and Sport Category values from the related Lead. |
| `Create_At_Risk_Task_for_Account_Owner` | Create At Risk Task for Account Owner | AutoLaunchedFlow | Account | RecordAfterSave / CreateAndUpdate | **Active** |  |
| `csat` | CSAT | Survey |  |  | **Active** |  |
| `customer_satisfaction` | Customer Satisfaction | Survey |  |  | **Active** |  |
| `Email_Activity_Update_Campaign_Member_Status` | Email Activity â†’ Update Campaign Member Status | AutoLaunchedFlow | EmailMessage | RecordAfterSave / CreateAndUpdate | **Draft** |  |
| `Get_1st_2nd_Response_Time` | Get 1st & 2nd Response Time via Email | AutoLaunchedFlow | EmailMessage | RecordAfterSave / Create | **Obsolete** |  |
| `Lead_From_US_Retailer_Form_Assignment_And_Email` | Lead From TypeForm Form Assignment And Email | AutoLaunchedFlow | Lead | RecordAfterSave / Create | **Active** | Updated the sender email to "company wide org" email instead of "curent user". |
| `Map_Lead_Source_to_Account_on_Conversion` | Map Lead Source to Account on Conversion | AutoLaunchedFlow | Lead | RecordAfterSave / Update | **InvalidDraft** |  |
| `net_promoter_score` | Net Promoter Score | Survey |  |  | **Active** |  |
| `Opportunity_field_update_from_Account` | Opportunity field update from Account | AutoLaunchedFlow | Opportunity | RecordBeforeSave / Create | **Active** | Cluster, Sales channel and sector field mirror from the account |
| `Send_Approval_Rejection_email_based_on_US_And_Canada_Retailer` | Send Approval email based on US And Canada Retailer | AutoLaunchedFlow | Lead | RecordAfterSave / Update | **Active** | Send Approval email based on US And Canada Retailer |
| `Send_Approval_Rejection_emails_when_lead_status_changes` | Send Approval/Rejection emails when lead status changes | AutoLaunchedFlow | Lead | RecordAfterSave / Update | **Obsolete** | To send auto-responses when leads are manually rejected or approved |
| `Send_Approve_Email_After_Lead_Conversion` | Send Approve Email After Lead Conversion | AutoLaunchedFlow | Lead | RecordAfterSave / Update | **Draft** |  |
| `Send_Contact_to_Shopify` | Send Contact to Shopify | Flow |  |  | **Draft** |  |
| `Send_Email_To_Account_When_the_account_is_Inactive` | Send Email To Account When the account is Inactive | AutoLaunchedFlow | Account | RecordAfterSave / Update | **Obsolete** | Send Email To Account When the account is Inactive based on the company or store location |
| `Send_Rejection_Email_on_account_rejection` | Send Rejection Email on account rejection | AutoLaunchedFlow | Lead | RecordAfterSave / Update | **Active** | A temporary flow just to send the rejection email, since the acceptance email needs updating |
| `Send_Shopify_At_Risk_Notice` | Send Shopify At Risk Notice | AutoLaunchedFlow | Shopify_At_Risk_Notice__c | RecordAfterSave / Create | **Active** | Sends the email for a newly created Shopify At Risk Notice. The template is chosen by the notice Stage (Month 12, Month 15, Month 17, 15-Day Reminder, Deactivation) inside the SendWarmOffEmail Apex action; legacy notices with no Stage still receive the Shopify At Risk Notice template. The email is logged to the activity timeline on both the contact and the notice. On success the notice is marked Notice Sent and stamped with the send date and template subject; on failure it is marked Send Failed. The send date drives the warm-off series, so this flow is the only thing that should populate Notice Date. |
| `Set_At_Risk_Dates_on_Store_Location` | Set At Risk Dates on Store Location | AutoLaunchedFlow | Account | RecordBeforeSave / CreateAndUpdate | **Active** | Records when a store location is first flagged as at risk on Shopify, and clears that date when the location starts ordering again. Runs before save whenever the R12 sales calculation updates the account. The At Risk Since date tells the notice batch which contacts have already been notified, so a location that recovers and later stops ordering again is correctly treated as a new occasion. |
| `SLA_Calculation` | SLA Calculation | AutoLaunchedFlow | Case | RecordAfterSave / CreateAndUpdate | **Draft** |  |
| `Store_Copy_Values_From_Lead` | Store - Copy Values From Lead | AutoLaunchedFlow | Store__c | RecordBeforeSave / CreateAndUpdate | **Active** |  |
| `Typeform_Case_Routing` | Typeform Case Routing | AutoLaunchedFlow | Case | RecordAfterSave / Create | **Active** | To get the various typeforms routed to the correct Queues |
| `Update_Contact_in_Case` | Update Contact in Case | AutoLaunchedFlow | Case | RecordBeforeSave / Create | **Active** |  |
| `Update_the_campaign_member_status` | Update the campaign member status | AutoLaunchedFlow | EmailMessage | RecordAfterSave / Create | **Draft** |  |
