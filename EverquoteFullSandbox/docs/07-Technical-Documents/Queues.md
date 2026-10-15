# Queues

Source: `force-app/main/default/queues` (103 queues).

- Individual user members are shown as a **count only**. Public groups and roles are shown by API name. A queue email address is shown as `[email set]`.
- "Routing config" is the Omni-Channel `queueRoutingConfig`.
- "Email members" is `doesSendEmailToMembers`.
- Every queue has `doesIncludeBosses = true/false` in the XML; this is not shown in the table.

## Summary by supported object

| Supported object | Queues |
|---|---|
| Lead | 46 |
| Case | 29 (2 of them also VoiceCall) |
| VoiceCall | 23 (incl. the 2 shared with Case) |
| MessagingSession | 4 |
| LiveChatTranscript | 2 |
| Influencer__c | 1 |

56 queues list no members in source. Some may receive work only through Omni-Channel routing or automation, but in the org their membership could have been set outside this retrieve.

## Queues referenced by automation in this repo

| Queue (DeveloperName) | Referenced by |
|---|---|
| Smart_Campaign | Case workflow field update `Owner_Change_to_Smart_Campaign_Queue`; flow `Case_Move_to_Smart_Campaign_Queue` (looked up by DeveloperName) |
| Inbound_Life_Queue | `TaskHandler.assignLeadOwnerOnFirstCall` (by DeveloperName); inactive `TaskLead` trigger (hard-coded ID `00G2g000000HbBiEAK`) |
| Recycled_Leads_Queue | Lead workflow field update `Change_Owner_to_RLQ` (rule "Recycle Lost Leads", active) |
| Duplicates | Lead workflow field update `Owner_Duplicate_Queue` (active) |
| Commercial_Agents, Consumer, Invalid_Contact_Info, Unqualified | Lead workflow field updates `Owner_*` (rules "Unqualified: ...", active) |
| "Unassigned" (by **Name**) | `etcd8_RRLeadAssignment` queries `Queue.Name = 'Unassigned'`. **No queue with that label exists in source.** |
| `00GVm000000alG9MAM`, `00GVm000001CG3dMAG` | Hard-coded queue IDs in flow `Case_Update_Case_Owner_to_Account_Support_Rep_1`. Which queues these are cannot be determined from metadata. |

## All queues

| API name | Label | Supported objects | Members (from source) | Routing config | Queue email | Email members | Description |
|---|---|---|---|---|---|---|---|
| Acc_BC_Required | Acc BC Required | Case | 6 user(s) |  |  | false |  |
| Accelerated_Customer_Success | Accelerated Customer Success | Case | groups: Accelerated |  |  | false |  |
| Account_Closures | Account Closures | Case | (none listed) |  |  | false |  |
| Account_Management | Account Management | Case | (none listed) |  |  | false |  |
| Agency_Duplicates | Agency Duplicates | Lead | (none listed) |  |  | false |  |
| AGP_Support | AGP Support | Case | 2 user(s) | Queue_Based_Routing |  | false |  |
| AGP_Support_Queue | AGP Support Queue | Case | (none listed) |  |  | false |  |
| AGP_Webinar_Leads | AGP Webinar Leads | Lead | 1 user(s) |  |  | false |  |
| allstate_agp_isr_voice | allstate_agp_isr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| allstate_bdr_voice_queue | allstate_bdr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| allstate_isr_voice_queue | allstate_isr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Allstate_Team | Allstate Team | Lead | 10 user(s) |  |  | false |  |
| BC_Sales_Handoff | BC Sales Handoff | VoiceCall | (none listed) | BC_Sales_Handoff |  | false |  |
| BDR_Inbound_Call | BDR Inbound Call | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| BDR_Queue | BDR Queue | Lead | 1 user(s); groups: BDR |  |  | false |  |
| BDR_Voicemail | BDR Voicemail | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Choice_Lead_Delivery_Failures | Choice Lead Delivery Failures | Case | 2 user(s) | Choice_Lead_Failures |  | false |  |
| Commercial_Agents | Commercial Agents | Lead | (none listed) |  |  | false |  |
| Consumer | Consumer | Lead | (none listed) |  |  | false |  |
| Core_IO_to_assign | Core IO to assign | Case | 3 user(s) |  |  | false |  |
| Core_Support | Core Support | Case | 3 user(s) | Support_email |  | false |  |
| cos_onboarding | cos_onboarding | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| csa_support | csa_support | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| csm | csm | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| CSM_Required | CSM Required | Case | 2 user(s) |  |  | false |  |
| Customer_Support | Customer Support (Email) | Case | groups: Customer_Support | Case_Routing_Configuration |  | false |  |
| DNC_Carrier_Queue | DNC Carrier Queue | Lead | (none listed) |  |  | false |  |
| DNC_Request_Queue | DNC Request Queue | Case | 5 user(s) |  |  | false |  |
| Do_Not_Call | Do Not Call | Lead | (none listed) |  |  | false |  |
| Duplicates | Duplicates | Lead | (none listed) |  |  | false |  |
| eBook_Queue | eBook Queue | Lead | groups: Inbound_Queue |  |  | false |  |
| EverLife_Lead_Queue | EverLife Lead Queue | Lead | 5 user(s) |  | [email set] | false |  |
| farmers_agp_isr_voice_queue | farmers_agp_isr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| farmers_bdr_voice_queue | farmers_bdr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Farmers_Pilot_Queue | Farmers Pilot Queue | Lead | groups: BDR |  |  | false |  |
| Farmers_Team | Farmers Team | Lead | 6 user(s) |  |  | false |  |
| Farmers_Voice_Calls | Farmers Voice Calls | VoiceCall | 1 user(s) | Default_For_Voice |  | false |  |
| Folio_Dispute_Queue | Folio Dispute Queue | Case | (none listed) |  |  | false |  |
| Georgia_Leads | Georgia Leads | Lead | 1 user(s) |  |  | false |  |
| Gone_Inactive | Gone Inactive | Case | (none listed) |  |  | false |  |
| Home_Agents | Home Agents | Lead | (none listed) |  |  | false |  |
| IA_and_Growth_Team | IA and Growth Team | Lead | 1 user(s) |  |  | false |  |
| iagrowth_bdr_voice_queue | iagrowth_bdr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| iagrowth_isr_voice_queue | iagrowth_isr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Inbound | Inbound | Lead | (none listed) |  |  | false |  |
| Inbound_Life_Queue | Inbound Life Queue | Lead | roles: ADMIN |  |  | false |  |
| Inbound_Queue | Inbound Queue | Lead | 5 user(s) |  |  | false |  |
| Invalid_Contact_Info | Invalid Contact Info | Lead | (none listed) |  |  | false |  |
| Key_Account_Support | Key Account Support | Case | 5 user(s) |  |  | true |  |
| LCS_BDR_s | LCS BDR's | Lead | 3 user(s) |  |  | true |  |
| LCS_Queue | LCS Queue | Lead | 4 user(s) |  |  | true |  |
| Lead_Failure_Customer_Support | Lead Failure Customer Support | Case | groups: Customer_Support |  |  | false |  |
| Lead_Pool | Lead Pool | Lead | (none listed) |  |  | false |  |
| Life_Agents | Life Agents | Lead | 1 user(s) |  |  | true |  |
| Life_Team | Life Team | Lead | 6 user(s) |  |  | false |  |
| Mega_Agent_Account_Management | Mega Agent Account Management | Case | (none listed) |  |  | false |  |
| No_Contact_Queue | No Contact Queue | Case | (none listed) |  |  | false |  |
| No_Recycle_Queue | No Recycle Queue | Lead | 5 user(s) |  |  | false |  |
| [name]_Opp_Case (API name contains personal names) | Starter IA CSA Outreach | Case | 1 user(s) |  |  | false |  |
| ODA_Reassignment_Queue | ODA Reassignment Queue | Lead | roles: ADMIN |  |  | false |  |
| Pro_help_center | Pro help center | LiveChatTranscript | 2 user(s); groups: Customer_Success, Customer_Support | Pro_help_center |  | false |  |
| QA | QA | Case | (none listed) |  |  | false |  |
| Recycled_Leads_Queue | Recycled Leads Queue | Lead | 2 user(s) |  |  | false |  |
| Referal_Case_Queue | Referal Case Queue | Case | 1 user(s); groups: Customer_Success_Managers, Customer_Support | Case_Routing_Configuration |  | false |  |
| Referral | Referral | Lead | 6 user(s) |  |  | false |  |
| RM1_Email_Queue | RM1 Email Queue | Lead | 5 user(s) |  |  | false |  |
| SCV_Basic_Queue_CCQ_04v4z000000oLl3 | SCV Basic Queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Senior_CSA | Senior CSA | Case | 2 user(s) |  |  | false |  |
| Service_Case | Service Case | Case | (none listed) |  |  | false |  |
| Service_Chat | Service Chat | LiveChatTranscript | (none listed) | Service_Routing_Chat |  | false |  |
| Service_Messaging | Service Messaging with In-App and Web | MessagingSession | (none listed) | Service_Routing_Messaging |  | false |  |
| Smart_Campaign | Smart Campaign | Case | 2 user(s) |  |  | false |  |
| SMS_Holding | SMS Holding | MessagingSession | 2 user(s) | SMS |  | false |  |
| SMS_Inbound_Sales | SMS Inbound Sales | MessagingSession | (none listed) | SMS |  | false |  |
| SMS_Inbound_Support | SMS Inbound Support | MessagingSession | 4 user(s) | SMS |  | false |  |
| Starter | Starter Evergreen | Case | groups: Customer_Support | Low_Priority_Case_Routing_Configuration |  | false | Used to assign Evergreen Account Management cases that are related to Starter accounts. Cases should be assigned to CSAs via the Low Priority case routing config. S3P-1355 |
| State_Farm_DNC | State Farm DNC | Lead | (none listed) |  |  | false |  |
| State_Farm_Team | State Farm Team | Lead | 5 user(s) |  |  | false |  |
| statefarm_agp_isr_voice_call | statefarm_agp_isr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| statefarm_bdr_voice_queue | statefarm_bdr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| statefarm_isr_voice_queue | statefarm_isr_voice_queue | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Support_Case_Queue | Support Case Queue | Case | 5 user(s) | Case_Routing_Configuration |  | false |  |
| Support_Inbound | Support Inbound | Case | 1 user(s) | Support_voice_inbound |  | false |  |
| Support_Level_1_Inbound | Support Level 1 Inbound | Case, VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Unassigned_Allstate_High_Scoring | Unassigned Allstate High Scoring | Lead | (none listed) |  |  | false |  |
| Unassigned_Farmers_High_Scoring | Unassigned Farmers High Scoring | Lead | (none listed) |  |  | false |  |
| Unassigned_IA_Highly_Scored | Unassigned IA Highly Scored | Lead | (none listed) |  |  | false |  |
| Unassigned_IA_Small_Captive | Unassigned IA Small Captive | Lead | (none listed) |  |  | false |  |
| Unassigned_IAs | Unassigned IAs | Lead | 2 user(s); groups: IA_and_Growth_Team |  |  | true |  |
| Unassigned_Influencer_Queue | Unassigned Influencer Queue | Influencer__c | 6 user(s) |  |  | false |  |
| Unassigned_Queue_Complete_Lead | Unassigned Queue - Complete Lead | Lead | (none listed) |  |  | false |  |
| Unassigned_Queue_No_email | Unassigned Queue - No email | Lead | (none listed) |  |  | false |  |
| Unassigned_Queue_No_Name | Unassigned Queue - No Name | Lead | (none listed) |  |  | false |  |
| Unassigned_Queue_No_Name_No_Email | Unassigned Queue - No Name, No Email | Lead | (none listed) |  |  | false |  |
| Unassigned_Sales_Available | Unassigned Sales Available | Lead | (none listed) |  |  | false |  |
| Unassigned_Sales_Available_Woburn | Unassigned Sales Available - Woburn | Lead | (none listed) |  |  | false |  |
| Unassigned_State_Farm_High_Scoring | Unassigned State Farm High Scoring | Lead | (none listed) |  |  | false |  |
| Unqualified | Unqualified | Lead | (none listed) |  |  | false |  |
| vm_test | vm_test | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| Waitlist | Waitlist | Lead | groups: Accelerated, Inbound_Queue, Sales_Strategy_and_Ops, State_Farm_Team |  |  | false |  |
| X3P_CSM_Inbound | 3P CSM Inbound | VoiceCall | (none listed) | Default_For_Voice |  | false |  |
| X3PA_Inbound_Callbacks | 3PA Voicemail | VoiceCall | 1 user(s) | Scheduled_Callbacks |  | false |  |
| X3PA_Inbound_Support | 3PA Inbound | Case, VoiceCall | (none listed) |  |  | false |  |
