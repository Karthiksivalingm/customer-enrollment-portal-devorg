# Data Model and Relationships

Built from `force-app/main/default/objects/` (retrieved 2026-10-14).

- **Coverage:** 133 objects. These are the unmanaged custom objects, custom settings, custom metadata types and Knowledge, plus the 22 standard objects
  that carry unmanaged fields. Managed-package fields are excluded.
- **Grouping:** functional areas are an INFERENCE from object names and relationships.
- **Field lists:** per object in [Metadata-Inventory/Objects](../07-Technical-Documents/Metadata-Inventory/Objects-and-Fields.md).

Legend: MD = master-detail, L = lookup. OWD: RW = Public Read/Write, CBP = Controlled by Parent.

## Core standard objects
Account is the hub of the data model. About 20 custom objects are master-detail children of Account.

| Object | Custom fields | Record types | Notes |
|---|---|---|---|
| Account (OWD RW, external Private) | 778 | Dealership, Foundation_Dealership, FNDN_Hybrid_TVM_Billed, FNDN_TVM_Hybrid | Dealership accounts. Lookups to Client_Team, OEM_Team, OEM_Program, OEM_Dealer, Onboarding_Team, Auto_Group (x2), Size_Template, Vendor_OEM_Rep (x6), External_User |
| Opportunity | 802 | Active, Inactive, Prospect, Historical, Try_Buy, New_Buy_Sell, Direct_Enrollment, Parent_MSA, Child_MSA, Foundation_Opportunity, FNDN_Hybrid, Ford_Lincoln_Active/Inactive/Prospect, GM_Canada | L→Onboarding__c, Lead_Sources__c, Vendor__c (loss to competitor), parent/related Opportunity. 17 business processes |
| Case (OWD ReadWriteTransfer) | 465 | Master_Record_Type, TVM, Foundation_Client_Services, Foundation_Measurement, Foundation_OEM, Foundation_Performance_Review | L→Vendor__c, Vendor_OEM_Rep__c, External_User__c (x2), Related_Case_1–3 |
| Contact (OWD RW) | 224 | — | L→Auto_Group, Cancellation_Request, Email_Contact |
| OpportunityLineItem | 216 | — | Target of Discount_Request lookups |
| User, VoiceCall | 77, 77 | — | VoiceCall L→Case, Account, Contact, Auto_Group, Vendor_OEM_Rep |
| Campaign (OWD Private) | 60 | BDC, Pardot_Connected_Campaign | |
| Others | ContractLineItem 52, CampaignMember 40, Activity 34, Product2 34, EmailMessage 32, Lead 31, ServiceContract 30, PricebookEntry, OrderItem, Pricebook2, AccountContactRelation, OpportunityContactRole, SurveyInvitation | | |

"Foundation" / "FNDN" prefixes run through records, record types, automation and permission sets. INFERENCE: they mark a separate
Foundation business line, the "Foundation Direct" dealer program, handled in the same org.

## Custom objects by functional area (INFERENCE grouping)

| Area | Objects | Key relationships |
|---|---|---|
| Onboarding | Onboarding__c, Onboarding_Package__c, Onboarding_Team__c, Foundation_Onboarding__c, Previous_Sales_Result__c ("Onboarding Build Document"), Digital_Build_Request__c, Checklist__c, Checklist_Task__c, Open_Item__c, Google_Verification_Record__c, X90_Day_Website_Review__c | Onboarding_Package MD→Onboarding__c. Onboarding__c L→Account, Opportunity, Monthly_Budget, Vendor (x3), Contact. Checklist MD→Account, Checklist_Task MD→Checklist |
| Creative requests | Creative_Request__c (451 fields, 37 record types, e.g. Web_Banner, Email_Blast, Video, Landing_Page, OTT, Print_Ad), Full_Service_Creative_Request__c, Creative_Request_Change__c, Creative_Request_Log__c, Creative_Size__c, Size_Template__c, Creative_Theme_Template__c, Rush_Request__c, Offer__c, Status__c, Brand_Standard__c, Brand_Standard_2__c | Creative_Request MD→Account; L→Case, Auto_Group, Rush_Request, Status. Change and Size MD→Creative_Request |
| Compliance | Compliance_Request__c, Compliance_Task__c, Compliance_Task_Note__c, Compliance_Creative_Note__c | Request MD→Account. Task MD→Request. Note MD→Task. Creative_Note MD→Request and Creative_Request |
| OEM programs | OEM_Program__c, OEM_Enrollment__c, OEM_Enrollment_Product__c, OEM_Enrollment_Change__c, OEM_Allocation__c, OEM_Dealer__c, OEM_Team__c, OEM_Notes__c | Enrollment MD→Account. Enrollment_Change MD→Enrollment. Account L→Program, Dealer, Team |
| Sales, budgets, financials | Sales_Data__c, Monthly_Budget__c, Monthly_Goal__c, Sales_Activity__c, Measurement__c, Foundation_Measurement_Change_History__c, FNDN_Financials__c, Product_History__c, Discount_Request__c, Addendum_Request__c, Cancellation_Request__c, Credit_Request__c, Foundation_Credit_Request__c, Lead_Sources__c, DMA_Name__c, Core_Vitals__c, Meeting_Recap__c | Sales_Data, Monthly_Budget, Cancellation and Credit requests MD→Account. Discount_Request L→Opportunity + 9 OpportunityLineItem lookups |
| Client service and communication | Auto_Group__c ("Group"), Client_Team__c, ClientInteractions__c, Follow_Up__c, Case_Transfer__c, Agent_Transfer_Summary__c, Intergroup_Communication__c, Internal_External_Note__c, File_Attachment__c, Comment__c, Touch__c, External_User__c, BDC_Campaign__c, Email_Campaign__c, Email_Contact__c, Broker__c, Property__c, Salesforce_Updates__c, Monthly_HR_Reporting__c, OOO_Calendar__c | Intergroup_Communication and Internal_External_Note MD→Case. Touch L→Account, Case, Opportunity, Onboarding, Creative_Request, Project_Task |
| Project and development tracking | Project_Task__c, Project_Task_Group__c, Project_Task_Size__c, Project_Task_Log__c, Project_Hours__c, User_Story__c ("User Ticket"), Sprint__c, Test_Case__c, Defect__c, Dev_Task__c | Task_Group MD→Onboarding_Package. Task MD→Task_Group. Test_Case and Dev_Task MD→User_Story. Defect MD→Test_Case |
| Surveys | Survey_Schedule__c, Survey_Deployment__c, Survey_Deployment_Link__c, Survey_Response__c | Deployment MD→Schedule. Link MD→Deployment and Contact |
| Training | Training_Program__c, Training_Course__c, Quiz__c, Quiz_Template__c, Question__c | Course MD→Program. Quiz MD→Course |
| Vendors | Vendor__c, Vendor_OEM_Rep__c, Account_Vendor__c (junction) | Account_Vendor MD→Account and Vendor |
| Logging and integration | Audit_Log__c, Event_Log__c, SF2SF_Sharing_Queue__c, FlowPersonalConfiguration__c, FlowTableViewDefinition__c | — |

## Configuration objects
| Object | Kind | Fields / purpose |
|---|---|---|
| Process_Switches__c | Hierarchy setting | `*_Integration_Bypass__c`: bypass the TouchPoint callout triggers |
| SLA_Time_Calculation__c | List setting | CaseType__c, SLA_Estimated_Time__c: SLA hours per case type |
| Email_Service_Case_Assignment__c | Hierarchy setting | Default Account, assignee and owner for email-service cases |
| Opportunity_Attachment_Email_Content__c | Hierarchy setting | Subject, body and recipient for Opportunity attachment emails |
| Media_Budgets_Loaded1__c | Hierarchy setting | Toggles for budget-load emails, events and tasks |
| In_App_Checklist_Settings__c | Hierarchy setting (protected) | In-app checklist |
| Global__c | Hierarchy setting | No fields in source |
| Case_Routing_Config__mdt | Custom metadata (12 fields, ~105 records) | Case routing. See [Case-Routing-and-Omni-Channel.md](Case-Routing-and-Omni-Channel.md) |
| TouchPoint_Callout__mdt | Custom metadata | TouchPoint endpoint and tokens. **Records excluded from source** |
| SF2SF_Automation_Setting__mdt, SharingStatusMapping__mdt | Custom metadata | Salesforce-to-Salesforce sharing |
| Reports_To_External_User__mdt, Account_Recordtype_Name__mdt | Custom metadata | Report distribution; record-type names |

There are no platform events. `Knowledge__kav` has one record type, FAQ.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Created from analysis of the baseline retrieval. |
