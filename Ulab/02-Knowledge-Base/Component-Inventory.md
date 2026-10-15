# Component Inventory

Salesforce components in the **Ulab Sandbox** (`ulab--staging`, Org ID `00D5200000001UeEAI`) that were **created or last modified** by Meshak Michel, Kaviya Natarajan, Ankit Singh or Sandip Patel. Objects and fields are listed only when one of them **created** the component.

Source: `sf org list metadata` (CreatedBy / LastModifiedBy), run 2026-10-15. Dates are UTC. Managed-package components are excluded. "Last modified by" is the last person to save the component, so a component can appear here because a team member edited it after someone else created it.

| Type | Count |
|---|---|
| ApexClass | 32 |
| ApexTrigger | 8 |
| ApprovalProcess | 6 |
| AuraDefinitionBundle | 3 |
| ConnectedApp | 1 |
| CustomField | 241 |
| CustomObject | 7 |
| CustomPermission | 2 |
| CustomTab | 6 |
| FlexiPage | 12 |
| Flow | 34 |
| GlobalValueSet | 1 |
| Layout | 57 |
| LightningComponentBundle | 3 |
| ListView | 12 |
| PermissionSet | 46 |
| QuickAction | 4 |
| RecordType | 17 |
| RemoteSiteSetting | 6 |
| SharingRules | 6 |
| StaticResource | 12 |
| ValidationRule | 54 |
| WorkflowAlert | 25 |
| WorkflowFieldUpdate | 23 |
| WorkflowRule | 13 |
| **Total** | **631** |

## Count by person

| Person | Created | Last modified |
|---|---|---|
| Ankit Singh | 67 | 73 |
| Kaviya Natarajan | 53 | 65 |
| Meshak Michel | 156 | 229 |
| Sandip Patel | 254 | 187 |

## ApexClass (32)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `CompanyPriceTotalBatch_test` | Sandip Patel | 2022-02-15 | Madhuri Kamble | 2022-12-16 |
| `CompanyTotalPriceBatch` | Sandip Patel | 2022-02-15 | Madhuri Kamble | 2022-12-28 |
| `CompanyTotalPriceHelper` | Sandip Patel | 2022-02-17 | Sandip Patel | 2022-04-12 |
| `CreditRequestController` | Ankit Singh | 2026-02-04 | Ankit Singh | 2026-02-04 |
| `EmailAlertReaderQueueable` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-05-07 |
| `MarketingRewardAssociationHandler` | Ankit Singh | 2026-02-18 | Meshak Michel | 2026-07-08 |
| `MarketingRewardAssociationTest` | Ankit Singh | 2026-02-20 | Sandip Patel | 2026-07-01 |
| `MarketingRewardProcessor` | Ankit Singh | 2026-02-23 | Kaviya Natarajan | 2026-03-31 |
| `MarketingRewardProcessorTest` | Kaviya Natarajan | 2026-02-25 | Kaviya Natarajan | 2026-03-31 |
| `MRAActiveStartDateHelper` | Meshak Michel | 2026-09-30 | Meshak Michel | 2026-09-30 |
| `MraEffectiveDateBatch` | Meshak Michel | 2026-09-18 | Meshak Michel | 2026-09-18 |
| `MraEffectiveDateBatchTest` | Meshak Michel | 2026-09-28 | Meshak Michel | 2026-09-29 |
| `MraEffectiveDateScheduler` | Meshak Michel | 2026-09-18 | Meshak Michel | 2026-09-18 |
| `MRASendToBoomi` | Meshak Michel | 2026-09-16 | Meshak Michel | 2026-09-18 |
| `NFATriggerTest` | Sandip Patel | 2022-10-11 | Sandip Patel | 2022-10-28 |
| `NotificationController` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-05-07 |
| `NotificationDebugAction` | Meshak Michel | 2026-04-22 | Meshak Michel | 2026-04-22 |
| `NotificationFilterAction` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-27 |
| `OrderChangeHandler` | Meshak Michel | 2026-03-11 | Meshak Michel | 2026-05-12 |
| `OrderChangeTriggerTest` | Kumar Albert | 2025-11-20 | Meshak Michel | 2026-03-11 |
| `ProgramBundleAssociationTriggerHandler` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-28 |
| `ProgramBundleAssocTriggerHandlerTest` | Meshak Michel | 2026-07-28 | Meshak Michel | 2026-07-28 |
| `RewardAssociationTrigger_Test` | Sandip Patel | 2022-03-29 | Madhuri Kamble | 2022-12-16 |
| `Showme` | Ankit Singh | 2024-10-01 | Ankit Singh | 2025-01-15 |
| `showmemockclass` | Ankit Singh | 2024-11-28 | Ankit Singh | 2025-01-15 |
| `showmetestclass` | Ankit Singh | 2024-11-28 | Ankit Singh | 2025-01-11 |
| `TechReviewController` | Kaviya Natarajan | 2026-02-10 | Kaviya Natarajan | 2026-02-10 |
| `TriggerBypass` | Kaviya Natarajan | 2026-02-25 | Kaviya Natarajan | 2026-02-25 |
| `ULabOrderStatusKPIHandler` | Meshak Michel | 2026-03-11 | Alberto Cordero | 2026-10-05 |
| `uLabOrderTrigger_Test` | Ruben Smith | 2021-03-23 | Sandip Patel | 2022-02-17 |
| `uLabOrderTriggerHandler` | Meshak Michel | 2026-04-22 | Meshak Michel | 2026-04-27 |
| `ULabOrderTriggerTest` | Meshak Michel | 2026-03-11 | Alberto Cordero | 2026-10-05 |

## ApexTrigger (8)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `MarketingRewardAssociationTrigger` | Ankit Singh | 2026-02-18 | Meshak Michel | 2026-09-16 |
| `NFATrigger` | Sandip Patel | 2022-10-11 | Sandip Patel | 2022-10-11 |
| `OrderChangeTrigger` | Kumar Albert | 2025-11-20 | Meshak Michel | 2026-05-12 |
| `ProgramBundleAssociationTrigger` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-22 |
| `RewardAssociationTrigger` | Sandip Patel | 2022-02-22 | Meshak Michel | 2026-09-30 |
| `ULabOrderStatusKPITriggers` | Ankit Singh | 2026-02-18 | Meshak Michel | 2026-05-12 |
| `ULabOrderTrigger` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-16 |
| `uLabOrderTriggers` | Meshak Michel | 2026-04-22 | Meshak Michel | 2026-04-27 |

## ApprovalProcess (6)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Credit_Request__c.Credit_Request_Approval` | Sandip Patel | 2022-03-09 | Sandip Patel | 2022-12-16 |
| `Credit_Request__c.Credit_Request_Approval_1` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-04 |
| `Credit_Request__c.Credit_Request_Approval_A` | Ankit Singh | 2026-02-04 | Meshak Michel | 2026-05-08 |
| `Credit_Request__c.Credit_Request_Approval_New` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Credit_Request_Approval_V2` | Sandip Patel | 2022-12-21 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Credit_Request_Approval1` | Sandip Patel | 2022-12-16 | Sandip Patel | 2022-12-21 |

## AuraDefinitionBundle (3)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `CanandaMapImage` | Sandip Patel | 2022-04-08 | Sandip Patel | 2022-04-08 |
| `CompanyTotalPriceCount` | Sandip Patel | 2022-02-17 | Sandip Patel | 2022-02-22 |
| `Recordpage` | Ankit Singh | 2024-10-01 | Ankit Singh | 2025-08-03 |

## ConnectedApp (1)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Okta` | Sandip Patel | 2022-10-31 | Sandip Patel | 2022-10-31 |

## CustomField (241)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Account.Aligner_WF_Task_Completed__c` | Sandip Patel | 2022-10-04 | Sandip Patel | 2022-10-04 |
| `Account.Aligner_WF_Task_Completed_Date__c` | Sandip Patel | 2022-10-03 | Sandip Patel | 2022-10-06 |
| `Account.Billing_Group__c` | Sandip Patel | 2026-04-03 | Sandip Patel | 2026-04-03 |
| `Account.Click_n_Go_Promo_Effective_Date__c` | Sandip Patel | 2022-11-18 | Sandip Patel | 2022-11-30 |
| `Account.Converted__c` | Sandip Patel | 2022-03-07 | Sandip Patel | 2022-03-07 |
| `Account.IsCustomer__c` | Sandip Patel | 2022-04-14 | Sandip Patel | 2022-04-14 |
| `Account.Kai_Customer__c` | Meshak Michel | 2026-08-10 | Meshak Michel | 2026-08-10 |
| `Account.New_Total_Aligner_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.New_Total_Custom_Box_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.New_Total_Retainer_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.Premier_Total_Aligner_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.Premier_Total_Custom_Box_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.Premier_Total_Retainer_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.Primary_VIP_Technician__c` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `Account.Program_Name__c` | Sandip Patel | 2022-02-28 | Sandip Patel | 2022-02-28 |
| `Account.Prorated_Goal__c` | Sandip Patel | 2022-03-16 | Sandip Patel | 2022-04-15 |
| `Account.Secondary_VIP_Technician__c` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `Account.uAssist_Ready_Date__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `Account.uD7_1_Reg_Date__c` | Sandip Patel | 2022-07-12 | Ruben Smith | 2024-01-05 |
| `Account.uD7_MRA_CA_exist__c` | Sandip Patel | 2022-06-17 | Sandip Patel | 2022-06-17 |
| `Account.uD7_MRA_uAssist_Promo_exist__c` | Sandip Patel | 2022-06-17 | Sandip Patel | 2022-06-17 |
| `Account.uD7_MRA_USA_exist__c` | Sandip Patel | 2022-06-17 | Sandip Patel | 2022-06-17 |
| `Account.Udesign_Customer__c` | Meshak Michel | 2026-08-17 | Meshak Michel | 2026-08-17 |
| `Account.uPP_Total_Aligner_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.uPP_Total_Custom_Box_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.uPP_Total_Retainer_Price__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `Account.VIP_Status__c` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `Activity.Aligner_Lab__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Activity.Annual_Aligner_Starts__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Activity.Annual_Bracket_Case_Starts__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Activity.Currently_Printing_Aligners__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Activity.Currently_Printing_Retainers__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Activity.Percent_of_Aligners_Made_In_House__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Activity.Status__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Activity.Tooth_Movement_Software__c` | Sandip Patel | 2022-12-29 | Sandip Patel | 2022-12-29 |
| `Activity.Traditional_Aligner_Company__c` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Backstop__c.Active__c` | Ankit Singh | 2026-02-20 | Ankit Singh | 2026-02-20 |
| `Contact.Agreement_Effective_Date__c` | Sandip Patel | 2023-02-17 | Sandip Patel | 2023-02-17 |
| `Contact.Agreement_End_Date__c` | Sandip Patel | 2023-02-17 | Sandip Patel | 2023-02-17 |
| `Contact.Company_Name_Picklist__c` | Sandip Patel | 2022-03-21 | Sandip Patel | 2022-03-21 |
| `Contact.Premier_Additional_Terms__c` | Sandip Patel | 2023-02-15 | Andrew Blair | 2023-07-17 |
| `Contact.Premier_Type__c` | Sandip Patel | 2023-02-15 | Sandip Patel | 2023-02-15 |
| `Contact_Account_Notification__c.Company__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Account_Notification__c.Contact__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Account_Notification__c.Disable_Email__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c.Contact__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c.Disable_Email__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c.Suppressed_Folders__c` | Meshak Michel | 2026-05-07 | Meshak Michel | 2026-05-07 |
| `Contact_Notification__c.User__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c.Contact__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c.Field_Name__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c.Field_Value__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c.Object_Name__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Credit_Request__c.Account_Email__c` | Sandip Patel | 2022-03-21 | Sandip Patel | 2022-03-21 |
| `Credit_Request__c.Actual_Amount_Entered_In_Netsuite__c` | Sandip Patel | 2022-09-14 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.ASD_for_approval_process__c` | Sandip Patel | 2022-03-09 | Sandip Patel | 2022-03-09 |
| `Credit_Request__c.ASD_Manager__c` | Sandip Patel | 2022-03-09 | Sandip Patel | 2022-03-09 |
| `Credit_Request__c.Case_Number__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-03-11 |
| `Credit_Request__c.Company_Lookup__c` | Sandip Patel | 2022-10-06 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Company_Name__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-10-06 |
| `Credit_Request__c.Company_Number__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-10-06 |
| `Credit_Request__c.Company_Owner__c` | Kaviya Natarajan | 2026-02-04 | Kaviya Natarajan | 2026-02-04 |
| `Credit_Request__c.Customer_Currency__c` | Sandip Patel | 2022-03-11 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Denial_Email_Sent_Date__c` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Denial_Reason__c` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Email_Sent__c` | Kaviya Natarajan | 2026-02-04 | Kaviya Natarajan | 2026-02-04 |
| `Credit_Request__c.Financial_User__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-03-11 |
| `Credit_Request__c.Invoice_Numbers__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-03-11 |
| `Credit_Request__c.NS_Credit_Memo_ID__c` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Order__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-03-11 |
| `Credit_Request__c.Order_Number__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-03-11 |
| `Credit_Request__c.Order_Type__c` | Kaviya Natarajan | 2026-02-04 | Kaviya Natarajan | 2026-02-04 |
| `Credit_Request__c.Patient_Name__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Person_requesting_from_account__c` | Sandip Patel | 2022-03-15 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Price_of_Aligner__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Price_of_Custom_Box_Artwork__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Price_of_Customer_Box__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Price_of_Retainer__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Price_of_Shipping__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Price_of_STL__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Product_Type__c` | Sandip Patel | 2022-03-11 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Quantity_of_Aligner__c` | Sandip Patel | 2022-03-11 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Quantity_of_Custom_Box_Artwork__c` | Sandip Patel | 2022-03-11 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Quantity_of_Customer_Box__c` | Sandip Patel | 2022-03-11 | Sandip Patel | 2022-03-11 |
| `Credit_Request__c.Quantity_of_Retainer__c` | Sandip Patel | 2022-03-11 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Quantity_of_Shipping__c` | Sandip Patel | 2022-03-11 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Quantity_of_STL__c` | Sandip Patel | 2022-03-11 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.RSM__c` | Ankit Singh | 2026-02-17 | Ankit Singh | 2026-02-17 |
| `Credit_Request__c.RSM_Email__c` | Ankit Singh | 2026-02-17 | Ankit Singh | 2026-02-17 |
| `Credit_Request__c.Send_to_Boomi__c` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Send_to_NetSuite__c` | Sandip Patel | 2022-09-20 | Sandip Patel | 2022-09-20 |
| `Credit_Request__c.Total_amount_confirmed_by_finance__c` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-14 |
| `Credit_Request__c.Total_Amount_Requested__c` | Sandip Patel | 2022-03-14 | Andrew Blair | 2023-11-07 |
| `Credit_Request__c.Total_Amounts__c` | Sandip Patel | 2022-03-21 | Madhuri Kamble | 2022-10-14 |
| `Custom_Packaging_Artwork__c.Send_to_Boomi__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `Lead.Converted__c` | Sandip Patel | 2022-03-07 | Andrew Blair | 2023-07-25 |
| `Marketing_Reward__c.Bundle_Type__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `Marketing_Reward__c.OrthoPulse_Unlimited__c` | Kaviya Natarajan | 2026-02-20 | Kaviya Natarajan | 2026-02-20 |
| `Marketing_Reward__c.Quick_Finish_Bundle__c` | Meshak Michel | 2026-06-11 | Meshak Michel | 2026-06-11 |
| `Marketing_Reward__c.X8_Retainer_Bundle__c` | Sandip Patel | 2026-03-14 | Sandip Patel | 2026-03-14 |
| `Marketing_Reward_Association__c.Active__c` | Sandip Patel | 2022-02-22 | Meshak Michel | 2026-09-30 |
| `Marketing_Reward_Association__c.Active_Start_Date__c` | Meshak Michel | 2026-09-30 | Meshak Michel | 2026-09-30 |
| `Marketing_Reward_Association__c.Aligner_Price__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Bundle_Type__c` | Meshak Michel | 2026-05-08 | Meshak Michel | 2026-05-08 |
| `Marketing_Reward_Association__c.Bundle_Types__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `Marketing_Reward_Association__c.Calculated_Number__c` | Sandip Patel | 2022-03-22 | Sandip Patel | 2022-03-23 |
| `Marketing_Reward_Association__c.Case_Backstop__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Case_Fee_Ceiling__c` | Ankit Singh | 2026-02-23 | Ankit Singh | 2026-02-23 |
| `Marketing_Reward_Association__c.Company_Email__c` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `Marketing_Reward_Association__c.Comprehensive_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Custom_Packaging_Discount__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Custom_Packaging_Price__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Custom_Packaging_Setup_Discount__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Custom_Packaging_Setup_Price__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Customer_Billing_Country__c` | Sandip Patel | 2022-05-27 | Sandip Patel | 2022-05-27 |
| `Marketing_Reward_Association__c.Days__c` | Sandip Patel | 2022-03-16 | Sandip Patel | 2022-03-16 |
| `Marketing_Reward_Association__c.Direct_Print_Aligner__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Effective_Date_Today__c` | Kaviya Natarajan | 2026-06-01 | Kaviya Natarajan | 2026-06-01 |
| `Marketing_Reward_Association__c.EffectiveDate_Month__c` | Sandip Patel | 2022-03-17 | Sandip Patel | 2022-03-22 |
| `Marketing_Reward_Association__c.Finishing_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.IDB_Tray__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Is_Leap_Year__c` | Sandip Patel | 2022-03-16 | Sandip Patel | 2022-03-16 |
| `Marketing_Reward_Association__c.Marketing_Reward_Record__c` | Sandip Patel | 2022-03-08 | Sandip Patel | 2022-03-08 |
| `Marketing_Reward_Association__c.Mild_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Moderate_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Ortho_Pulse_Comp_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.OrthoPulse_Unlimited__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.Prorated_Goal__c` | Sandip Patel | 2022-03-16 | Sandip Patel | 2022-03-22 |
| `Marketing_Reward_Association__c.Quick_Finish_Bundle__c` | Meshak Michel | 2026-06-11 | Meshak Michel | 2026-06-11 |
| `Marketing_Reward_Association__c.Retainer_Price__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.STL_Price__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.uAdjust_10_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.uAssist_Bracket_Removal_Pricing__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.uAssist_Initial_Pricing__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.uAssist_Refinement_Pricing__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.uAssist_Retainer_Pricing__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.X2_Retainer_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.X4_Retainer_Bundle__c` | Kaviya Natarajan | 2026-02-19 | Kaviya Natarajan | 2026-02-19 |
| `Marketing_Reward_Association__c.X8_Retainer_Bundle__c` | Kaviya Natarajan | 2026-03-18 | Kaviya Natarajan | 2026-03-18 |
| `New_Feature_Association__c.Active__c` | Sandip Patel | 2022-09-19 | Sandip Patel | 2022-09-19 |
| `ProductBundles__c.Event_Trigger__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `Program_Bundle_Associations__c.custrecord_included_in_kai__c` | Meshak Michel | 2026-08-19 | Meshak Michel | 2026-08-19 |
| `Program_Bundle_Associations__c.custrecord_included_in_ud_9_1__c` | Kaviya Natarajan | 2026-02-11 | Kaviya Natarajan | 2026-02-11 |
| `Program_Bundle_Associations__c.custrecord_included_in_udesign_cloud__c` | Kaviya Natarajan | 2026-02-11 | Kaviya Natarajan | 2026-02-11 |
| `Program_Bundle_Associations__c.custrecord_udesign_cloud_bundle_label__c` | Kaviya Natarajan | 2026-02-11 | Kaviya Natarajan | 2026-02-11 |
| `Program_Bundle_Associations__c.custrecord_udesign_cloud_bundle_type__c` | Kaviya Natarajan | 2026-02-11 | Kaviya Natarajan | 2026-02-11 |
| `sfdc_bundle_updated__e.Active__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.Bundle_Id__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.Bundle_Type__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.Effective_Date__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.End_Date__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.Marketing_Reward_Id__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.NetSuite_Bundle_Association_ID__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.NetSuite_Item_ID__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.Program_Name__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_bundle_updated__e.Record_Id__c` | Meshak Michel | 2026-07-13 | Meshak Michel | 2026-07-13 |
| `sfdc_order_statusChanged__e.Order_Cancellation_Comments__c` | Kaviya Natarajan | 2026-03-26 | Kaviya Natarajan | 2026-03-26 |
| `uLab_Banner__c.Banner_theme_example__c` | Sandip Patel | 2022-05-17 | Sandip Patel | 2022-05-17 |
| `uLab_Banner__c.Month__c` | Sandip Patel | 2022-05-04 | Sandip Patel | 2022-05-04 |
| `uLab_Banner__c.Year__c` | Sandip Patel | 2022-05-04 | Sandip Patel | 2022-05-04 |
| `uLab_Case__c.Click_n_Go_Eligible__c` | Sandip Patel | 2022-11-18 | Sandip Patel | 2022-11-30 |
| `uLab_Case__c.Contact__c` | Sandip Patel | 2022-04-22 | Sandip Patel | 2022-04-22 |
| `uLab_Case__c.Date_entered_Complete_Status__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Date_entered_Declined_Status__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Date_entered_Delayed_Status__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Date_entered_In_Progress_after_Delayed__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Date_entered_In_Progress_Status__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Diff_Created_to_In_Progress__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-04-01 |
| `uLab_Case__c.Diff_In_Progress_to_Completed__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-04-01 |
| `uLab_Case__c.Diff_In_Progress_to_Declined__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-04-01 |
| `uLab_Case__c.Kai_Case__c` | Meshak Michel | 2026-08-11 | Meshak Michel | 2026-08-11 |
| `uLab_Case__c.Notes_Attachments__c` | Sandip Patel | 2022-03-24 | Sandip Patel | 2022-03-24 |
| `uLab_Case__c.Time_Spent_in_Delayed__c` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-04-01 |
| `uLab_Case__c.uAssist_Comments__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Case__c.uAssist_Notification_Sent__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Case__c.uDesign_Version__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.AccountId__c` | Sandip Patel | 2022-02-15 | Sandip Patel | 2022-02-15 |
| `uLab_Order__c.AWS_EventBridge_Status__c` | Sandip Patel | 2026-02-10 | Sandip Patel | 2026-02-10 |
| `uLab_Order__c.Custom_Box__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Date_entered_Case_Ready_to_Review_Status__c` | Sandip Patel | 2022-06-15 | Sandip Patel | 2022-06-15 |
| `uLab_Order__c.Date_entered_Completed_Status__c` | Sandip Patel | 2022-06-15 | Sandip Patel | 2022-06-15 |
| `uLab_Order__c.Date_entered_In_Progress_Status__c` | Sandip Patel | 2022-06-15 | Sandip Patel | 2022-06-15 |
| `uLab_Order__c.Date_entered_Model_Prep_Status__c` | Sandip Patel | 2022-06-15 | Sandip Patel | 2022-06-15 |
| `uLab_Order__c.Date_entered_Modification_Request_Status__c` | Sandip Patel | 2022-06-15 | Madhuri Kamble | 2022-10-16 |
| `uLab_Order__c.Date_entered_On_Hold_Status__c` | Sandip Patel | 2022-06-15 | Sandip Patel | 2022-06-15 |
| `uLab_Order__c.Date_entered_Rejected_Status__c` | Sandip Patel | 2022-06-15 | Sandip Patel | 2022-06-15 |
| `uLab_Order__c.Defect_Type__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Diff_In_Progress_to_Rejected__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Diff_Ready_for_Review_to_Completed__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Diff_uAssist_Started_to_Ready_for_Review__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Generate_PE_Manually__c` | Meshak Michel | 2026-03-23 | Meshak Michel | 2026-03-23 |
| `uLab_Order__c.Hybrid_Order__c` | Kaviya Natarajan | 2026-03-27 | Kaviya Natarajan | 2026-03-27 |
| `uLab_Order__c.Kai_Order__c` | Meshak Michel | 2026-08-11 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c.Modification_Requested_Counter__c` | Sandip Patel | 2022-06-23 | Sandip Patel | 2022-06-23 |
| `uLab_Order__c.Order_Rejection_Comments__c` | Meshak Michel | 2026-05-12 | Meshak Michel | 2026-05-12 |
| `uLab_Order__c.Order_Status_changed__c` | Sandip Patel | 2022-05-19 | Sandip Patel | 2022-05-19 |
| `uLab_Order__c.Orig_Order_Date__c` | Sandip Patel | 2022-12-06 | Sandip Patel | 2022-12-19 |
| `uLab_Order__c.Orig_Order_ID__c` | Sandip Patel | 2022-12-19 | Sandip Patel | 2022-12-19 |
| `uLab_Order__c.Orig_Order_No__c` | Sandip Patel | 2022-12-06 | Sandip Patel | 2022-12-19 |
| `uLab_Order__c.Orig_Order_No_2__c` | Sandip Patel | 2022-12-06 | Sandip Patel | 2022-12-19 |
| `uLab_Order__c.Orig_Ship_Date__c` | Sandip Patel | 2022-12-06 | Sandip Patel | 2022-12-19 |
| `uLab_Order__c.Orignal_Order_ID__c` | Sandip Patel | 2022-12-06 | Sandip Patel | 2022-12-19 |
| `uLab_Order__c.Primary_VIP_Technician__c` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.Priority__c` | Sandip Patel | 2022-05-19 | Laya Nallavelli | 2023-01-31 |
| `uLab_Order__c.Related_Case_Number__c` | Sandip Patel | 2022-12-06 | Ruben Smith | 2024-11-26 |
| `uLab_Order__c.Secondary_VIP_Technician__c` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.SendEmail__c` | Ankit Singh | 2026-02-12 | Ankit Singh | 2026-02-12 |
| `uLab_Order__c.Ship_To_City__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Ship_To_Country__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Ship_To_State__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Ship_To_Street__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Ship_To_Zip__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Shipping_State__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Staff_Order__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.test__c` | Ankit Singh | 2025-01-10 | Ankit Singh | 2025-01-10 |
| `uLab_Order__c.Time_Spent_in_Model_Prep__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Time_Spent_in_Modification_Requested__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Time_Spent_in_On_Hold__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.Total_Price__c` | Sandip Patel | 2022-02-17 | Sandip Patel | 2022-03-29 |
| `uLab_Order__c.uA_Modificaion_Complete_Sent__c` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `uLab_Order__c.uAssist_Ready_to_Review__c` | Sandip Patel | 2022-06-14 | Ruben Smith | 2022-07-01 |
| `uLab_Order__c.uAssist_Started__c` | Sandip Patel | 2022-06-14 | Sandip Patel | 2022-07-07 |
| `uLab_Order__c.uAssist_VIP_Date__c` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.uAssistant_Notification_Sent__c` | Sandip Patel | 2022-06-16 | Ruben Smith | 2022-07-01 |
| `uLab_Order__c.uLab_Aligner_Order_Created_Date__c` | Sandip Patel | 2022-11-17 | Sandip Patel | 2022-11-17 |
| `uLab_Order__c.uSmile_overdue__c` | Sandip Patel | 2022-11-17 | Sandip Patel | 2022-11-17 |
| `uLab_Order__c.VIP_Status__c` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.Voided__c` | Sandip Patel | 2026-04-02 | Sandip Patel | 2026-04-02 |
| `Ulab_Order_Notification__mdt.Email_Alert_Name__c` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `Ulab_Order_Notification__mdt.Email_Template_Name__c` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `User.Disable_All_Emails__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User.Full_Name__c` | Sandip Patel | 2022-07-13 | Sandip Patel | 2022-07-13 |
| `User.Profile_Name__c` | Meshak Michel | 2026-03-19 | Meshak Michel | 2026-03-19 |
| `User_Account_Notification__c.Company__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Account_Notification__c.Disable_Email__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Account_Notification__c.User__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c.Disable_Email__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c.Field_Name__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c.Field_Value__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c.Object_Name__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c.User__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |

## CustomObject (7)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Contact_Account_Notification__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `sfdc_bundle_updated__e` | Meshak Michel | 2026-06-04 | Meshak Michel | 2026-07-22 |
| `Ulab_Order_Notification__mdt` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `User_Account_Notification__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |

## CustomPermission (2)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Block_InProgress_Update` | Meshak Michel | 2026-03-17 | Meshak Michel | 2026-03-17 |
| `Bypass_uAssist_Status_Validation` | Kaviya Natarajan | 2026-02-13 | Kaviya Natarajan | 2026-02-13 |

## CustomTab (6)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Contact_Account_Notification__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Notification_Center_Home` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Account_Notification__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |

## FlexiPage (12)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Backstop_Record_Page` | Ankit Singh | 2026-02-17 | Ankit Singh | 2026-02-17 |
| `Contact_Record_Page2` | Sandip Patel | 2022-05-13 | Sandip Patel | 2022-05-13 |
| `Credit_Request_Record_Page` | Ruben Smith | 2020-04-27 | Ankit Singh | 2026-02-04 |
| `Home_Page_Default3` | Ruben Smith | 2021-04-15 | Ankit Singh | 2026-02-05 |
| `Marketing_Reward_Association_Record_Page1` | Meshak Michel | 2026-05-08 | Alberto Cordero | 2026-09-18 |
| `Marketing_Reward_Record_Page` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-06-25 |
| `Marketing_Reward_Record_Page1` | Meshak Michel | 2026-06-09 | Meshak Michel | 2026-06-11 |
| `Notification_Center_Home` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `Notification_Center_UtilityBar` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `Program_Bundle_Association_Record_Page` | Sandip Patel | 2026-02-26 | Sandip Patel | 2026-02-26 |
| `Sales_Mobile_UtilityBar` | Sandip Patel | 2022-05-13 | Sandip Patel | 2022-05-13 |
| `uLab_Case_Record_Page` | Ruben Smith | 2020-03-12 | Meshak Michel | 2026-08-11 |

## Flow (34)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Assign_STAFF50_Promo_to_new_customer` | Ankit Singh | 2026-02-23 | Ankit Singh | 2026-02-23 |
| `Auto_Revert_Rejected_Status_to_Cancel_API_Update` | Meshak Michel | 2026-03-12 | Meshak Michel | 2026-03-12 |
| `AWS_All_uAssist_Notifications` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `Cancel_a_Order_Button` | Meshak Michel | 2026-04-08 | Meshak Michel | 2026-04-08 |
| `Cloud_uAssist_Order_Notification` | Meshak Michel | 2026-05-08 | Meshak Michel | 2026-05-08 |
| `Copy_Account_Owner_Email_to_Company_Email` | Sandip Patel | 2022-07-21 | Alberto Cordero | 2026-07-09 |
| `Copy_pricing_fields_on_MRA_record_from_MR_record_on_Effective_date` | Meshak Michel | 2026-09-24 | Meshak Michel | 2026-09-24 |
| `Create_MRA_send_to_Boomi` | Sandip Patel | 2022-04-01 | Sandip Patel | 2022-04-01 |
| `Credit_Request_Below_250_Approval` | Ankit Singh | 2026-02-04 | Ankit Singh | 2026-02-04 |
| `Credit_Request_Status_Change` | Sandip Patel | 2022-10-06 | Sandip Patel | 2022-12-16 |
| `Credit_Request_update_ASD` | Sandip Patel | 2022-10-06 | Sandip Patel | 2022-10-06 |
| `Credit_Request_Update_flag_on_Approval` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Email_Alert_for_order_Cancellation` | Meshak Michel | 2026-03-24 | Kaviya Natarajan | 2026-04-07 |
| `Email_Alert_for_the_lead_assignment_rules` | Kaviya Natarajan | 2026-03-09 | Kaviya Natarajan | 2026-03-09 |
| `Flag_Send_to_NetSuite` | Sandip Patel | 2026-03-30 | Sandip Patel | 2026-03-30 |
| `Marketing_Reward_Assoc_Send_to_Boomi_when_End_Date_is_changed` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `Marketing_Reward_Association_Effective_date_update` | Ankit Singh | 2026-02-13 | Ankit Singh | 2026-02-18 |
| `New_Customer_Feature_Flag_Update_NFA` | Sandip Patel | 2022-10-11 | Sandip Patel | 2022-10-11 |
| `NonCloud_uD_uA_Order_Customer_Notification` | Meshak Michel | 2026-04-20 | Meshak Michel | 2026-04-20 |
| `Okta_User_created_notificaiton` | Sandip Patel | 2023-02-10 | Sandip Patel | 2023-02-10 |
| `Record_Trigger_Copy_pricing_fields_on_MRA_record_from_MR_record_on_Effective_dat` | Meshak Michel | 2026-06-11 | Meshak Michel | 2026-06-11 |
| `Replacement_order_Copy_values_from_original_order` | Sandip Patel | 2026-03-16 | Sandip Patel | 2026-03-16 |
| `Send_to_NetSuite` | Kaviya Natarajan | 2026-04-15 | Meshak Michel | 2026-04-20 |
| `Send_to_NetSuite_V1` | Meshak Michel | 2026-05-21 | Meshak Michel | 2026-05-21 |
| `Send_to_WebApp` | Sandip Patel | 2026-02-12 | Meshak Michel | 2026-03-19 |
| `Task_to_complete_for_Sales_Rep` | Sandip Patel | 2022-10-04 | Sandip Patel | 2022-10-04 |
| `Test_notification_center` | Meshak Michel | 2026-04-22 | Meshak Michel | 2026-04-22 |
| `uAssist_comments_updated` | Kaviya Natarajan | 2026-02-10 | Kaviya Natarajan | 2026-02-10 |
| `uAssist_Order_Customer_Notification_1` | Andrew Blair | 2024-01-25 | Kaviya Natarajan | 2026-03-03 |
| `uAssist_Order_Flag_Updates` | Kaviya Natarajan | 2026-03-27 | Sandip Patel | 2026-03-27 |
| `uAssist_Status_Fast_Field_update` | Ankit Singh | 2026-02-26 | Sandip Patel | 2026-03-30 |
| `uLab_Order_Actions_And_Related_Records` | Ankit Singh | 2026-02-18 | Meshak Michel | 2026-05-12 |
| `Update_Account_when_Specific_Rewards_are_Associated` | Sandip Patel | 2022-11-30 | Sandip Patel | 2022-11-30 |
| `Update_Cancellation_Comments_to_Message_for_Cloud_UAssist` | Meshak Michel | 2026-04-09 | Meshak Michel | 2026-04-10 |

## GlobalValueSet (1)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Billing_Group` | Sandip Patel | 2026-04-03 | Sandip Patel | 2026-04-03 |

## Layout (57)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Account-Absorb-only Account Page` | Laya Nallavelli | 2023-02-20 | Meshak Michel | 2026-08-17 |
| `Account-Admin Account Layout` | Andrew Blair | 2023-06-02 | Meshak Michel | 2026-08-17 |
| `Account-Aligner OEM` | Laya Nallavelli | 2022-12-08 | Meshak Michel | 2026-08-17 |
| `Account-Sales Account Layout` | Andrew Blair | 2023-06-02 | Meshak Michel | 2026-08-17 |
| `Account-Supplier Account Layout` | Ruben Smith | 2021-06-03 | Meshak Michel | 2026-08-17 |
| `Backstop__c-Case Backstop Layout` | Ruben Smith | 2023-06-16 | Ankit Singh | 2026-02-20 |
| `CommunityMemberLayout-Community Member Layout` | Dot Compliance | 2021-08-30 | Meshak Michel | 2026-04-21 |
| `Contact_Account_Notification__c-Contact Account Notification Layout` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c-Contact Notification Layout` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-07 |
| `Contact_Notification_Preference__c-Contact Notification Preference Layout` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact-Absorb-only Contact Page Layout` | Laya Nallavelli | 2023-02-20 | Meshak Michel | 2026-05-05 |
| `Contact-Aligner OEM Layout` | Laya Nallavelli | 2022-12-07 | Meshak Michel | 2026-05-05 |
| `Contact-Mrkg Contact Layout` | Ruben Smith | 2020-11-04 | Meshak Michel | 2026-05-05 |
| `Credit_Request__c-CR Approved` | Sandip Patel | 2022-09-06 | Ankit Singh | 2026-02-04 |
| `Credit_Request__c-CR Initial` | Sandip Patel | 2022-09-06 | Kaviya Natarajan | 2026-02-04 |
| `Credit_Request__c-CR Submitted` | Sandip Patel | 2022-09-06 | Ankit Singh | 2026-02-04 |
| `Credit_Request__c-CR Submitted - Approver` | Sandip Patel | 2022-09-14 | Ankit Singh | 2026-02-04 |
| `Credit_Request__c-Credit Request Layout` | Ruben Smith | 2020-04-17 | Kaviya Natarajan | 2026-02-04 |
| `Credit_Request__c-Customer Adjustment` | Ruben Smith | 2025-11-25 | Ankit Singh | 2026-02-18 |
| `Event-Event Layout` | Ruben Smith | 2020-01-17 | Sandip Patel | 2023-02-02 |
| `Event-Practice Metrics Layout` | Sandip Patel | 2023-01-06 | Madhuri Kamble | 2023-02-17 |
| `Global-Global Layout` | Ruben Smith | 2020-01-17 | Sandip Patel | 2022-04-08 |
| `Lead-Lead Layout` | Ruben Smith | 2020-01-17 | Kaviya Natarajan | 2026-03-17 |
| `Marketing_Reward_Association__c-Promotion Record Layout` | Ruben Smith | 2022-01-03 | Meshak Michel | 2026-06-11 |
| `ProductBundles__c-Product Bundle Layout` | Ruben Smith | 2022-08-23 | Meshak Michel | 2026-07-13 |
| `Program_Bundle_Associations__c-Program Bundle Association Layout` | Ruben Smith | 2023-03-03 | Meshak Michel | 2026-08-19 |
| `Task-Accounting%2FBilling Follow Up` | Ruben Smith | 2020-09-01 | Sandip Patel | 2023-01-03 |
| `Task-Advanced Case Review` | Ruben Smith | 2020-10-05 | Sandip Patel | 2023-01-03 |
| `Task-Advanced Training` | Ruben Smith | 2020-06-23 | Sandip Patel | 2023-01-03 |
| `Task-Aligner Workflow Plan` | Sandip Patel | 2022-10-03 | Sandip Patel | 2023-01-03 |
| `Task-Compass Tool Activity` | Ruben Smith | 2021-10-01 | Sandip Patel | 2023-01-03 |
| `Task-Demo Layout` | Ruben Smith | 2020-06-23 | Sandip Patel | 2023-01-03 |
| `Task-Initial Training` | Ruben Smith | 2020-06-23 | Sandip Patel | 2023-01-03 |
| `Task-Interaction` | Ruben Smith | 2020-06-23 | Sandip Patel | 2023-01-03 |
| `Task-New Feature` | Ruben Smith | 2021-07-27 | Sandip Patel | 2023-01-03 |
| `Task-Order Cancellation` | Ruben Smith | 2020-10-29 | Sandip Patel | 2023-01-03 |
| `Task-RSM Account Setup` | Ruben Smith | 2020-06-23 | Sandip Patel | 2023-01-03 |
| `Task-Task Layout` | Ruben Smith | 2020-01-17 | Sandip Patel | 2023-01-03 |
| `Task-Team Education` | Ruben Smith | 2021-07-27 | Sandip Patel | 2023-01-03 |
| `uLab_Case__c-Aligner OEM Case Layout` | Laya Nallavelli | 2022-12-08 | Meshak Michel | 2026-08-11 |
| `uLab_Case__c-uLab Case Layout` | Ruben Smith | 2020-03-07 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-Admin uLab Order` | Ruben Smith | 2022-08-09 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-Aligner OEM Layout` | Laya Nallavelli | 2022-12-08 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-Clinical Review Layout` | Laya Nallavelli | 2023-03-08 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-Cloud uA Order Layout` | Ruben Smith | 2024-10-25 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-Internal uLab Order` | Ruben Smith | 2021-08-06 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-Replacement Order Layout` | Sandip Patel | 2022-12-14 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-uAssist Order Layout` | Ruben Smith | 2022-05-17 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-uLab DPA Order` | Ruben Smith | 2022-09-22 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-uLab IDB Order` | Ruben Smith | 2022-09-22 | Meshak Michel | 2026-08-11 |
| `uLab_Order__c-uLab Order Layout` | Ruben Smith | 2020-03-07 | Meshak Michel | 2026-08-11 |
| `Ulab_Order_Notification__mdt-Ulab Order Notification Layout` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `User_Account_Notification__c-User Account Notification Layout` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c-User Notification Preference Layout` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `UserAlt-User Profile Layout` | Salesforce, Inc. | 2020-01-17 | Meshak Michel | 2026-04-21 |
| `User-User Layout` | Andrew Blair | 2023-06-02 | Meshak Michel | 2026-04-21 |
| `User-User Layout-current` | Ruben Smith | 2020-01-17 | Meshak Michel | 2026-04-21 |

## LightningComponentBundle (3)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `approvedCreditRequests` | Ankit Singh | 2026-02-04 | Ankit Singh | 2026-02-04 |
| `notificationcenter` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-05-07 |
| `uAssistCommentPopup` | Kaviya Natarajan | 2026-02-10 | Kaviya Natarajan | 2026-02-10 |

## ListView (12)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Account.Companies_with_Program_Name` | Sandip Patel | 2022-03-04 | Sandip Patel | 2022-03-04 |
| `Contact_Account_Notification__c.All` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c.All` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c.All` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Futures_Program__c.All` | Ruben Smith | 2026-01-02 | Meshak Michel | 2026-05-20 |
| `Idea.Ideas_Last_7_Days` | Meshak Michel | 2020-01-17 | Meshak Michel | 2020-01-17 |
| `uLab_Order__c.All` | Ruben Smith | 2020-03-07 | Ankit Singh | 2025-01-14 |
| `uLab_Order__c.Cloud_uAssist_Orders` | Sandip Patel | 2026-04-10 | Sandip Patel | 2026-04-10 |
| `User.ActiveUsers` | Ruben Smith | 2020-01-17 | Meshak Michel | 2026-09-18 |
| `User.AllUsers` | Ruben Smith | 2020-01-17 | Meshak Michel | 2026-04-07 |
| `User_Account_Notification__c.All` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c.All` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |

## PermissionSet (46)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Absorb_LMS_Standard_User_Complete` | Laya Nallavelli | 2022-07-26 | Meshak Michel | 2026-05-11 |
| `Access_to_Marketing_Team` | Laya Nallavelli | 2022-09-06 | Meshak Michel | 2026-05-11 |
| `Access_to_uAssist` | Kaviya Natarajan | 2026-04-28 | Meshak Michel | 2026-05-11 |
| `Access_to_uAssist_workflow_and_Metrics` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `Account_Contact_Management` | Dot Compliance | 2020-04-22 | Meshak Michel | 2026-05-11 |
| `Accounts_Read` | Sandip Patel | 2022-05-04 | Laya Nallavelli | 2023-01-20 |
| `Accounts_Read_Edit` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `Accounts_Read_Edit_Create` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `ASD_Permissions` | Ankit Singh | 2026-02-05 | Ankit Singh | 2026-02-05 |
| `Block_InProgress_Update` | Meshak Michel | 2026-03-17 | Meshak Michel | 2026-03-17 |
| `Cases_Read` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `Chat_Functionality_Access` | Ankit Singh | 2024-10-16 | Ankit Singh | 2024-10-16 |
| `Contacts_Edit_Phone_and_Email_only` | Sandip Patel | 2022-05-04 | Laya Nallavelli | 2023-01-20 |
| `Contacts_Read` | Sandip Patel | 2022-05-04 | Laya Nallavelli | 2023-01-20 |
| `Contacts_Read_Edit` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `Contacts_Read_Edit_Create` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `CRB_Permission` | Ruben Smith | 2021-02-24 | Meshak Michel | 2026-05-11 |
| `Credit_Requests_Read_Create_Edit_Delete` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `Custom_Boxes_Read` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `Developer_Console_Access` | Ankit Singh | 2026-02-19 | Ankit Singh | 2026-02-19 |
| `Dot_Basic_Permission` | Dot Compliance | 2020-04-22 | Meshak Michel | 2026-05-11 |
| `Dot_Compliance_Document_Contributor` | Dot Compliance | 2020-04-22 | Meshak Michel | 2026-05-11 |
| `Dot_Compliance_Standard` | Dot Compliance | 2020-04-23 | Meshak Michel | 2026-05-11 |
| `Edit_access_on_New_Feature_Associations` | Kaviya Natarajan | 2026-04-28 | Kaviya Natarajan | 2026-04-28 |
| `Edit_Approved_Credit_Request` | Ankit Singh | 2026-02-05 | Ankit Singh | 2026-02-05 |
| `Encrypted_Field_Access` | Meshak Michel | 2026-05-08 | Meshak Michel | 2026-05-08 |
| `Flow_User_Permission` | Meshak Michel | 2026-04-07 | Meshak Michel | 2026-04-07 |
| `Leads_Read` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `MR_Read` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `MRA_Read` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `Patient_Name_Mask` | Ruben Smith | 2020-04-03 | Kaviya Natarajan | 2026-04-28 |
| `Patients_Read` | Sandip Patel | 2022-05-05 | Andrew Blair | 2024-02-16 |
| `Read_access_on_New_Feature_Associations` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `RSM_Permissions` | Ankit Singh | 2026-02-05 | Ankit Singh | 2026-02-05 |
| `Set_uAssist_VIP_Status_on_Company` | Andrew Blair | 2023-07-28 | Meshak Michel | 2026-05-11 |
| `Support_Case_Access` | Meshak Michel | 2026-05-11 | Meshak Michel | 2026-05-11 |
| `System_Admin_Bypass` | Ankit Singh | 2026-02-05 | Ankit Singh | 2026-02-05 |
| `Tasks_Events_Read_Create_Edit` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `uAssist_Services` | Kaviya Natarajan | 2026-04-28 | Meshak Michel | 2026-05-11 |
| `uAssist_Staus_Api_User` | Kaviya Natarajan | 2026-02-13 | Meshak Michel | 2026-07-22 |
| `uAssistant_Assignment` | Kaviya Natarajan | 2026-04-28 | Kaviya Natarajan | 2026-04-28 |
| `uLab_Cases_Read` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `uLab_Cases_Read_Edit` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `ulab_order_cloud_uassist_order_records_access` | Ankit Singh | 2025-01-14 | Ankit Singh | 2025-01-14 |
| `uLab_Orders_Read` | Sandip Patel | 2022-05-05 | Laya Nallavelli | 2023-01-20 |
| `View_and_Edit_Accounts_Contacts_and_Leads` | Kaviya Natarajan | 2026-04-28 | Kaviya Natarajan | 2026-04-28 |

## QuickAction (4)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Marketing_Rewards` | Sandip Patel | 2022-04-08 | Sandip Patel | 2022-04-08 |
| `uLab_Case__c.Create_Replacement_Order` | Sandip Patel | 2022-12-07 | Sandip Patel | 2022-12-07 |
| `uLab_Order__c.Cancel_uAssist_Order` | Meshak Michel | 2026-03-24 | Kaviya Natarajan | 2026-03-25 |
| `uLab_Order__c.test` | Ankit Singh | 2024-10-01 | Ankit Singh | 2024-10-01 |

## RecordType (17)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Credit_Request__c.Approved` | Sandip Patel | 2022-08-25 | Ankit Singh | 2026-02-05 |
| `Credit_Request__c.Customer_Adjustment` | Ruben Smith | 2025-11-25 | Ankit Singh | 2026-02-12 |
| `Credit_Request__c.Initial` | Sandip Patel | 2022-08-25 | Ankit Singh | 2026-02-05 |
| `Credit_Request__c.Submitted` | Sandip Patel | 2022-08-25 | Ankit Singh | 2026-02-05 |
| `Event.Events` | Sandip Patel | 2023-01-12 | Automated Process | 2026-07-18 |
| `Event.Practice_Metrics` | Sandip Patel | 2022-12-29 | Automated Process | 2026-07-18 |
| `Marketing_Reward_Association__c.Program_Association` | Ruben Smith | 2022-01-03 | Meshak Michel | 2026-05-08 |
| `Marketing_Reward_Association__c.Promotion_Association` | Ruben Smith | 2022-01-03 | Meshak Michel | 2026-05-08 |
| `Task.Aligner_Workflow_Plan` | Sandip Patel | 2022-10-03 | Automated Process | 2026-07-18 |
| `uLab_Order__c.Aligner_OEM` | Laya Nallavelli | 2022-12-08 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.Aligner_Order` | Ruben Smith | 2020-08-19 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.Cloud_uAssist_Order` | Ruben Smith | 2024-10-25 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.DPA_Order` | Ruben Smith | 2022-09-22 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.IDB_Order` | Ruben Smith | 2022-09-22 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.Internal_uLab_Order` | Ruben Smith | 2021-08-16 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.Replacement_Order` | Ruben Smith | 2020-03-15 | Meshak Michel | 2026-05-21 |
| `uLab_Order__c.uAssist_Order` | Ruben Smith | 2022-05-17 | Meshak Michel | 2026-05-21 |

## RemoteSiteSetting (6)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Chatfunction` | Ankit Singh | 2025-01-11 | Ankit Singh | 2025-01-11 |
| `chatfunction1` | Ankit Singh | 2025-01-11 | Ankit Singh | 2025-01-11 |
| `getmessageapinew` | Ankit Singh | 2024-10-03 | Ankit Singh | 2025-01-11 |
| `getmessageapinew1` | Ankit Singh | 2025-01-11 | Ankit Singh | 2025-01-11 |
| `SalesforceOrgDomain` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `ulabmessage` | Ankit Singh | 2024-10-03 | Ankit Singh | 2024-10-03 |

## SharingRules (6)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Contact_Account_Notification__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Contact_Notification_Preference__c` | Meshak Michel | 2026-05-05 | Meshak Michel | 2026-05-05 |
| `Marketing_Reward__c` | Ruben Smith | 2021-12-21 | Meshak Michel | 2026-06-11 |
| `User_Account_Notification__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |
| `User_Notification_Preference__c` | Meshak Michel | 2026-04-21 | Meshak Michel | 2026-04-21 |

## StaticResource (12)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Banner_Marketing` | Sandip Patel | 2022-05-17 | Sandip Patel | 2022-05-17 |
| `Banner_System` | Sandip Patel | 2022-05-17 | Sandip Patel | 2022-05-17 |
| `Canada_Map` | Sandip Patel | 2022-04-08 | Sandip Patel | 2022-04-21 |
| `facebook` | Ankit Singh | 2026-02-19 | Ankit Singh | 2026-02-19 |
| `Footer` | Ankit Singh | 2026-02-20 | Ankit Singh | 2026-02-20 |
| `instagram` | Ankit Singh | 2026-02-19 | Alberto Cordero | 2026-07-13 |
| `jquery` | Ankit Singh | 2024-10-01 | Ankit Singh | 2024-10-01 |
| `linkedin` | Ankit Singh | 2026-02-19 | Ankit Singh | 2026-02-19 |
| `logoA` | Ankit Singh | 2026-02-16 | Ankit Singh | 2026-02-16 |
| `twitter` | Ankit Singh | 2026-02-19 | Ankit Singh | 2026-02-19 |
| `ulablogo` | Ankit Singh | 2024-10-11 | Ankit Singh | 2024-10-11 |
| `youtube` | Ankit Singh | 2026-02-19 | Alberto Cordero | 2026-07-13 |

## ValidationRule (54)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Account.Billing_State_2_Character` | Sandip Patel | 2022-06-09 | Laya Nallavelli | 2022-12-28 |
| `Account.Billing_State_3_Character` | Sandip Patel | 2022-06-09 | Laya Nallavelli | 2022-12-28 |
| `Account.No_commas_or_periods_in_billing_address` | Ruben Smith | 2021-12-01 | Sandip Patel | 2022-08-11 |
| `Account.No_commas_or_periods_in_Shippingaddress` | Sandip Patel | 2022-03-04 | Sandip Patel | 2022-08-11 |
| `Account.Shipping_Country_2_Character` | Sandip Patel | 2022-03-04 | Laya Nallavelli | 2022-12-28 |
| `Account.Shipping_State_2_Character` | Sandip Patel | 2022-06-09 | Laya Nallavelli | 2022-12-28 |
| `Account.Shipping_State_3_Character` | Sandip Patel | 2022-06-09 | Laya Nallavelli | 2022-12-28 |
| `Contact.Company_Name_Lookup_and_Picklist` | Sandip Patel | 2022-03-21 | Ruben Smith | 2022-03-22 |
| `Contact.Effective_and_End_date_cannot_be_blank` | Sandip Patel | 2023-02-24 | Sandip Patel | 2023-02-24 |
| `Contact.Effective_date_cannot_be_in_the_past` | Sandip Patel | 2023-02-17 | Sandip Patel | 2023-02-27 |
| `Contact.End_date_cannot_exceed_12_months` | Sandip Patel | 2023-02-17 | Sandip Patel | 2023-02-17 |
| `Contact.Mailing_Country_2_Character` | Sandip Patel | 2022-10-26 | Laya Nallavelli | 2022-12-28 |
| `Contact.Mailing_State_2_Character` | Sandip Patel | 2022-10-26 | Laya Nallavelli | 2022-12-28 |
| `Contact.Mailing_State_3_Character` | Sandip Patel | 2022-10-26 | Laya Nallavelli | 2022-12-28 |
| `Contact.No_commas_or_periods_in_address` | Sandip Patel | 2022-08-11 | Sandip Patel | 2022-08-11 |
| `Contact.No_commas_or_periods_in_mailing_address` | Sandip Patel | 2022-10-26 | Sandip Patel | 2022-10-26 |
| `Credit_Request__c.Approved_Amount_validation_for_Approver` | Sandip Patel | 2022-10-26 | Kaviya Natarajan | 2026-02-04 |
| `Credit_Request__c.Record_Lock_after_approved` | Ankit Singh | 2026-02-05 | Kaviya Natarajan | 2026-03-02 |
| `Event.Aligner_Lab_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Event.Annual_Aligner_Starts_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Event.Annual_Bracket_Starts_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Event.Currently_Printing_Aligners_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Event.Currently_Printing_Retainers_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Event.Percent_of_Aligner_Made_Inhouse_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Event.Tooth_Movement_Software_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Event.Traditional_Aligner_Company_Required` | Sandip Patel | 2023-01-03 | Sandip Patel | 2023-01-03 |
| `Marketing_Reward_Association__c.Cannot_Create_MRA_for_inactive_account` | Andrew Blair | 2023-12-14 | Ankit Singh | 2026-02-23 |
| `Marketing_Reward_Association__c.Effective_Date_must_be_earlier_than_end` | Ankit Singh | 2026-02-13 | Ankit Singh | 2026-02-13 |
| `Marketing_Reward_Association__c.Marketing_Reward_mapping` | Sandip Patel | 2022-03-08 | Sandip Patel | 2022-03-08 |
| `uLab_Case__c.Corresponding_Record_Type` | Laya Nallavelli | 2023-02-03 | Ankit Singh | 2024-11-28 |
| `uLab_Order__c.Block_InProgress_From_QC_API_User` | Meshak Michel | 2026-03-17 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.Cancel_cant_be_changed` | Andrew Blair | 2023-10-04 | Meshak Michel | 2026-03-12 |
| `uLab_Order__c.Cancel_Status_validation` | Andrew Blair | 2023-07-27 | Meshak Michel | 2026-04-21 |
| `uLab_Order__c.Cant_cancel_after_shipped` | Ruben Smith | 2025-04-29 | Kaviya Natarajan | 2026-02-13 |
| `uLab_Order__c.Case_Ready_Must_enter_text_for_all_plans` | Andrew Blair | 2023-12-12 | Kaviya Natarajan | 2026-03-31 |
| `uLab_Order__c.On_Hold_Status_validation` | Sandip Patel | 2022-09-07 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.Only_API_User_Can_Edit_Voided` | Kaviya Natarajan | 2026-04-10 | Kaviya Natarajan | 2026-04-10 |
| `uLab_Order__c.Plan_1_Required_When_CRTR` | Meshak Michel | 2026-04-22 | Meshak Michel | 2026-04-22 |
| `uLab_Order__c.Plan_2_Required_When_CRTR` | Meshak Michel | 2026-04-22 | Meshak Michel | 2026-04-22 |
| `uLab_Order__c.Require_Plan_1` | Ruben Smith | 2025-06-26 | Meshak Michel | 2026-03-30 |
| `uLab_Order__c.Require_Plan_2` | Ruben Smith | 2025-06-26 | Meshak Michel | 2026-04-22 |
| `uLab_Order__c.uAssist_Order_From_Completed` | Andrew Blair | 2023-12-06 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.uAssist_Order_To_Completed` | Andrew Blair | 2023-12-06 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.uAssist_Order_Validation` | Laya Nallavelli | 2022-08-09 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.uAssist_status_must_remain_Rejected` | Andrew Blair | 2023-11-02 | Kaviya Natarajan | 2026-02-13 |
| `uLab_Order__c.uAssist_Status_onhold_to_tech_review` | Kaviya Natarajan | 2026-02-10 | Kaviya Natarajan | 2026-02-10 |
| `uLab_Order__c.uAssist_Status_VR_Cancel` | Ruben Smith | 2024-11-21 | Kaviya Natarajan | 2026-02-13 |
| `uLab_Order__c.uAssist_Status_VR_Completed` | Ruben Smith | 2024-11-21 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.uAssist_Status_VR_CRTR` | Ruben Smith | 2024-11-21 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.uAssist_Status_VR_Mod_Complete` | Ruben Smith | 2024-11-21 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.uAssist_Status_VR_Mod_in_Progress` | Ruben Smith | 2024-11-21 | Meshak Michel | 2026-04-15 |
| `uLab_Order__c.uAssist_Status_VR_Mod_Requested` | Ruben Smith | 2024-11-21 | Kaviya Natarajan | 2026-05-05 |
| `uLab_Order__c.uAssist_Status_VR_On_Hold` | Ruben Smith | 2024-11-21 | Ankit Singh | 2026-02-06 |
| `uLab_Order__c.uAssist_Status_VR_Rejected` | Ruben Smith | 2024-11-21 | Kaviya Natarajan | 2026-02-13 |

## WorkflowAlert (25)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Credit_Request__c.Approval_Denied_Email` | Ankit Singh | 2026-02-03 | Kaviya Natarajan | 2026-03-02 |
| `Credit_Request__c.Aprroved_Email` | Ankit Singh | 2026-02-17 | Ankit Singh | 2026-02-17 |
| `Credit_Request__c.CR_Email` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-17 |
| `Credit_Request__c.Credit_request_Approval_req_2` | Sandip Patel | 2022-03-21 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Credit_request_approval_req_3` | Sandip Patel | 2022-03-21 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Credit_request_approval_req_4` | Sandip Patel | 2022-03-21 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Credit_Request_Approval_Request1` | Sandip Patel | 2022-03-14 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Credit_Request_Approved` | Sandip Patel | 2022-03-14 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Credit_Request_Email` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Credit_Request_Rejected` | Sandip Patel | 2022-03-14 | Madhuri Kamble | 2022-12-12 |
| `Credit_Request__c.Email_Alert_For_Approval_Request` | Sandip Patel | 2022-03-14 | Sandip Patel | 2022-03-22 |
| `Credit_Request__c.Email_Alert_for_Approval_to_ASD_and_RSM` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Lead.Lead_New_Customer_Notification` | Kaviya Natarajan | 2026-03-09 | Kaviya Natarajan | 2026-03-09 |
| `Marketing_Reward_Association__c.Promo_Code_Offer_Email` | Meshak Michel | 2026-04-27 | Meshak Michel | 2026-04-27 |
| `uLab_Order__c.Cloud_uA_On_Hold_TX_Plan` | Ruben Smith | 2024-11-05 | Meshak Michel | 2026-04-08 |
| `uLab_Order__c.New_uAssist_Order_Notification` | Sandip Patel | 2022-06-16 | Ruben Smith | 2024-12-31 |
| `uLab_Order__c.Notify_RSM_if_a_uSmile_order_isn_t_placed` | Sandip Patel | 2022-11-18 | Madhuri Kamble | 2023-02-20 |
| `uLab_Order__c.Order_Cancellation_Notification` | Meshak Michel | 2026-03-24 | Meshak Michel | 2026-03-24 |
| `uLab_Order__c.Test_Email_Alert_for_notitifcation_center` | Meshak Michel | 2026-04-24 | Meshak Michel | 2026-04-24 |
| `uLab_Order__c.uAssist_Order_Customer_Notification_Completed` | Sandip Patel | 2022-06-15 | Sandip Patel | 2022-06-15 |
| `uLab_Order__c.uAssist_Order_Customer_Notification_In_Progress` | Sandip Patel | 2022-06-15 | Andrew Blair | 2024-02-15 |
| `uLab_Order__c.uAssist_Order_Customer_Notification_On_Hold` | Sandip Patel | 2022-06-15 | Ankit Singh | 2026-02-16 |
| `uLab_Order__c.uAssist_Order_Customer_Notification_Ready_to_Review` | Sandip Patel | 2022-06-15 | Andrew Blair | 2024-01-25 |
| `uLab_Order__c.uAssist_Order_Customer_Notification_Rejected` | Sandip Patel | 2022-06-15 | Andrew Blair | 2024-01-25 |
| `User.Okta_New_user_created_notification` | Sandip Patel | 2023-02-10 | Sandip Patel | 2023-02-10 |

## WorkflowFieldUpdate (23)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Account.Converted_flag_to_False` | Sandip Patel | 2022-03-07 | Sandip Patel | 2022-03-07 |
| `Credit_Request__c.Account_Email` | Sandip Patel | 2022-03-22 | Sandip Patel | 2022-10-06 |
| `Credit_Request__c.Denial_Email_Sent_Date` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Denial_Reason` | Ankit Singh | 2026-02-16 | Ankit Singh | 2026-02-16 |
| `Credit_Request__c.Field_Update` | Ankit Singh | 2026-02-12 | Ankit Singh | 2026-02-12 |
| `Credit_Request__c.Status_change_to_Submitted1` | Sandip Patel | 2022-03-09 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Update_Record_Type_to_Approved` | Sandip Patel | 2022-09-09 | Sandip Patel | 2022-09-09 |
| `Credit_Request__c.Update_Record_Type_to_Initial` | Sandip Patel | 2022-09-09 | Sandip Patel | 2022-09-09 |
| `Credit_Request__c.Update_Record_Type_to_Submitted` | Sandip Patel | 2022-09-09 | Sandip Patel | 2022-09-09 |
| `Credit_Request__c.Update_Status_to_Approved` | Sandip Patel | 2022-03-09 | Sandip Patel | 2022-12-16 |
| `Credit_Request__c.Update_status_to_approved1` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Update_status_to_deny` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Update_status_to_submitted` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Update_to_Approved` | Ankit Singh | 2026-02-03 | Ankit Singh | 2026-02-03 |
| `Credit_Request__c.Update_to_denied` | Sandip Patel | 2022-03-09 | Sandip Patel | 2022-03-09 |
| `Lead.Update_Converted_on_Lead` | Sandip Patel | 2022-03-15 | Sandip Patel | 2022-03-15 |
| `uLab_Case__c.Update_Date_entered_Complete` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Update_Date_entered_Declined` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Update_Date_entered_Delayed` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Update_Date_entered_In_Progress` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Case__c.Update_Date_entered_In_Progress_Delayed` | Sandip Patel | 2022-03-31 | Sandip Patel | 2022-03-31 |
| `uLab_Order__c.Update_Modification_Requested_Counter` | Sandip Patel | 2022-06-24 | Sandip Patel | 2022-06-24 |
| `uLab_Order__c.Update_Order_status_changed_flag` | Sandip Patel | 2022-05-19 | Sandip Patel | 2022-05-19 |

## WorkflowRule (13)

| Component | Created by | Created | Last modified by | Last modified |
|---|---|---|---|---|
| `Account.Check flag for Billing Address Change` | Laya Nallavelli | 2022-08-03 | Sandip Patel | 2022-08-04 |
| `Account.Check flag for Shipping Address Change` | Laya Nallavelli | 2022-08-03 | Sandip Patel | 2022-08-04 |
| `Account.Uncheck converted flag` | Sandip Patel | 2022-03-07 | Sandip Patel | 2022-03-07 |
| `Credit_Request__c.Credit request update Account Email field` | Sandip Patel | 2022-03-22 | Sandip Patel | 2022-03-22 |
| `Lead.Lead Converted checkbox` | Sandip Patel | 2022-03-15 | Andrew Blair | 2023-07-25 |
| `Marketing_Reward_Association__c.Mrktg Reward Promotion Update Boomi Checkbox` | Ruben Smith | 2022-01-05 | Sandip Patel | 2022-03-01 |
| `uLab_Case__c.uAssist - Date entered Complete status` | Sandip Patel | 2022-03-31 | Laya Nallavelli | 2022-07-14 |
| `uLab_Case__c.uAssist - Date entered Delayed status` | Sandip Patel | 2022-03-31 | Laya Nallavelli | 2022-07-14 |
| `uLab_Case__c.uAssist - Date entered In Progress status` | Sandip Patel | 2022-03-31 | Laya Nallavelli | 2022-07-14 |
| `uLab_Case__c.uAssist - Date entered In Progress status after Delayed` | Sandip Patel | 2022-03-31 | Laya Nallavelli | 2022-07-14 |
| `uLab_Case__c.Update Bundle` | Sandip Patel | 2022-03-31 | Andrew Blair | 2023-08-21 |
| `uLab_Order__c.Update Modification Requested Counter when uAssist Status change` | Sandip Patel | 2022-06-24 | Meshak Michel | 2026-06-03 |
| `uLab_Order__c.Update Order status changed value` | Sandip Patel | 2022-05-19 | Sandip Patel | 2022-05-26 |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Inventory generated from Ulab Sandbox metadata. |
