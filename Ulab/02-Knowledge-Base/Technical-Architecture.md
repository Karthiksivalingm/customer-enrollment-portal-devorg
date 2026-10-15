# Technical Architecture

This page covers the data model, the automation on each object, the Apex design and the known technical risks for the in-scope components.

- All paths are relative to [`force-app/main/default/`](../force-app/main/default/).
- Status values (Active, Inactive, Draft, Obsolete) were queried from the org on 2026-10-15.
- The business view is in [Business-Process.md](Business-Process.md).

## 1. Data model

```
                         ┌───────────────────────┐
                         │ Account ("Company")   │
                         └──┬──────┬──────┬──────┘
          master-detail     │      │      │ lookup                       lookup
   ┌────────────────────────┘      │      └───────────────┐      ┌──────────────────────┐
   ▼                               ▼                      ▼      │                      │
Marketing_Reward_Association__c  Credit_Request__c   New_Feature_Association__c ──► uLab_Feature__c
   │ lookup Marketing_Program__c     │ lookup Order__c
   ▼                                 ▼
Marketing_Reward__c ◄── Program_Bundle_Associations__c ──► ProductBundles__c
                                     uLab_Order__c ──► uLab_Case__c (Case__c)
                                        │  └─ Orignal_Order_ID__c (self, replacement orders)
                                        └─► ULab_Order_Status_KPI__c (status history rows)

Notification Center:  User ─┬─ User_Account_Notification__c ──► Account
                            ├─ User_Notification_Preference__c (Object/Field/Value rule)
                            └─ Contact_Notification__c ──► Contact (Suppressed_Folders__c)
                      Unused: Contact_Notification_Preference__c, Contact_Account_Notification__c
Custom metadata:      Ulab_Order_Notification__mdt (status → Email Alert + Template)
Platform events:      sfdc_order_statusChanged__e, sfdc_bundle_updated__e (High Volume, Publish Immediately)
```

| Object | Records | Fields in source | Notes |
|---|---|---|---|
| `uLab_Order__c` | 60,280 | 285 | 8 record types, 24 team validation rules (18 active), history tracked on uAssist status |
| `uLab_Case__c` | 70,479 | 16 (team) | 5 workflow rules, all inactive |
| `Credit_Request__c` | 96 | 90 | Record types Customer_Adjustment (current), Initial / Submitted / Approved (legacy) |
| `Marketing_Reward__c` | 109 | 198 | Price list per program or promotion |
| `Marketing_Reward_Association__c` | 2,477 | 72 | Record types Program_Association and Promotion_Association |
| `Program_Bundle_Associations__c` | 87 | 17 | NetSuite `custrecord_*` mirror fields |
| `New_Feature_Association__c` | 201 | 10 | |
| Notification objects (5) | 0–2 each | 3–5 each | Created Apr–May 2026, all lookups, sharing ReadWrite |

## 2. Automation per object

### 2.1 `uLab_Order__c`

| Order | Component | Type | Status | Purpose |
|---|---|---|---|---|
| Before save | `Cloud_uAssist_Order_Notification` | Record-triggered flow, no entry filter | **Active** | VIP flag, related emails, `Send_to_NetSuite__c`, `Send_to_WebApp__c` |
| Before save | `Flag_Send_to_NetSuite` | Record-triggered flow | **Active** | `Send_to_NetSuite__c` for In Progress / CRTR. Filters on a **hard-coded record type Id** |
| Before save | `Update_Cancellation_Comments_to_Message_for_Cloud_UAssist` | Record-triggered flow | **Active** | Copies cancellation comments to `On_Hold_Message__c` |
| Validation | 18 active rules | | | Status transitions (see Business-Process §1.3) |
| After save | `OrderChangeTrigger` → `ULabOrderStatusKPIHandler`, `OrderChangeHandler` | Apex trigger | **Active** | KPI rows. Publishes `sfdc_order_statusChanged__e` |
| After save | `uLabOrderTriggers` | Apex trigger | **Active, empty body** | No logic. Remove |
| After save | `AWS_All_uAssist_Notifications` | Record-triggered flow | **Active** | Cloud customer emails after the AWS acknowledgement |
| After save | `NonCloud_uD_uA_Order_Customer_Notification` | Record-triggered flow | **Active** | Non-Cloud customer emails |
| Workflow | "Update Order status changed value" | Workflow rule | **Active** | Sets `Order_Status_changed__c` when shipped |
| UI | `Cancel_a_Order_Button` via quick action `Cancel_uAssist_Order` | Screen flow | **Active** | Cancellation wizard |
| Inactive | `ULabOrderTrigger`, `ULabOrderStatusKPITriggers` | Apex trigger | Inactive | Old price roll-up and an empty KPI trigger |
| Inactive | `Send_to_WebApp`, `uAssist_Order_Flag_Updates`, `uAssist_Status_Fast_Field_update`, `uAssist_Order_Customer_Notification_1`, `Email_Alert_for_order_Cancellation`, `Auto_Revert_Rejected_Status_to_Cancel_API_Update`, `uLab_Order_Actions_And_Related_Records`, `Test_notification_center`, `Replacement_order_Copy_values_from_original_order` (Draft; its content is an old notification process, not a replacement copy) | Flows | Inactive / Obsolete / Draft | Superseded |

### 2.2 `Credit_Request__c`

| Component | Type | Status | Purpose |
|---|---|---|---|
| `Credit_Request_update_ASD` | Process Builder | **Active** | Stamps ASD and ASD manager. Sets `Send_to_NetSuite__c` when the NetSuite amount is entered |
| `Credit_Request_Below_250_Approval` | After-save flow | **Active** | Auto-approves amounts of $250 or less. **Hard-coded record type Id** `012RK00000BXa4nYAD` |
| `Credit_Request_Update_flag_on_Approval` | After-save flow | **Active** | `Send_to_Boomi__c` when Approved and a credit memo Id exists |
| `Credit_Request_Approval_A` | Approval process | **Active** | More than $250: one step, approver is a named user in the sandbox |
| `Credit_Request_Approval`, `_1`, `_V2`, `Approval1`, `_New` | Approval processes | Inactive | Legacy tiered model |
| "Credit request update Account Email field" | Workflow rule | **Active** | Copies the Company account email |
| `Approved_Amount_validation_for_Approver`, `Record_Lock_after_approved` | Validation rules | **Active** | Approver must enter an amount. Record lock |
| `Credit_Request_Status_Change` | Process Builder | Obsolete | |
| `CreditRequestController` + LWC `approvedCreditRequests` | Apex + LWC | | Home-page list of approved requests |

### 2.3 `Marketing_Reward_Association__c`

| Component | Type | Status | Purpose |
|---|---|---|---|
| `MarketingRewardAssociationTrigger` → `MarketingRewardAssociationHandler`, `MRASendToBoomi` | Apex trigger (before insert/update) | **Active** | Futures overlap shift. Send-to-Boomi guard rules |
| `RewardAssociationTrigger` (inline logic + `MRAActiveStartDateHelper`) | Apex trigger (before and after, all events) | **Active** | One active program per company, Active Start Date sequencing, Company program fields. **Hard-coded record type Id** `0126g000000bOBUAA2` |
| `Record_Trigger_Copy_pricing_fields_on_MRA_record_from_MR_record_on_Effective_dat` | After-save flow (create) | **Active** | Copies prices when Effective Date is today. Boomi flag. AAOCOMPTRIO email |
| `Copy_pricing_fields_on_MRA_record_from_MR_record_on_Effective_date` | Scheduled flow, daily 05:30 UTC | **Active** | Copies prices on the Effective Date |
| `Marketing_Reward_Assoc_Send_to_Boomi_when_End_Date_is_changed` | After-save flow | **Active** | Re-flags for Boomi after an End Date change |
| `Create_MRA_send_to_Boomi` | Process Builder (time-based, Effective + 1h) | **Active** | Boomi flag |
| `Update_Account_when_Specific_Rewards_are_Associated` | Process Builder | **Active** | Mari's List and Click n Go fields on the Company |
| "Mrktg Reward Promotion Update Boomi Checkbox" | Workflow rule | **Active** | Boomi flag for Promotion Associations |
| `Marketing_Reward_Association_Effective_date_update` | After-save flow | Obsolete | Replaced by the handler |
| `MraEffectiveDateBatch` + `MraEffectiveDateScheduler` | Batch (scope 200) + Schedulable | | Daily Boomi flag on the Effective Date. **TO BE CONFIRMED:** the cron schedule in the org |
| `MarketingRewardProcessor` | Batch, one-off | | 2026-03-31 → 2026-04-01 program rollover (hard-coded dates) |
| `CompanyTotalPriceBatch` / `CompanyTotalPriceHelper` + Aura `CompanyTotalPriceCount` | Batch + Schedulable + button | | Company Matrix roll-up from orders |

### 2.4 Other objects

| Object | Component | Type | Status |
|---|---|---|---|
| Account | `Assign_STAFF50_Promo_to_new_customer` | After-save flow | **Active** |
| Account | `Send_to_NetSuite`, `Send_to_NetSuite_V1` | Process Builder / flow | Obsolete |
| Account | 7 address validation rules | Validation | **Active** |
| Contact | `Copy_Account_Owner_Email_to_Company_Email` | Process Builder | Obsolete |
| Contact | Premier agreement and address validation rules | Validation | Active (1 inactive) |
| Program_Bundle_Associations__c | `ProgramBundleAssociationTrigger` → handler | Apex trigger (after insert/update) | **Active**: publishes `sfdc_bundle_updated__e` |
| New_Feature_Association__c | `NFATrigger` | Apex trigger (before insert) | **Active**: duplicate guard |
| New_Feature_Association__c | `New_Customer_Feature_Flag_Update_NFA` | Process Builder | **Active**: `Send_to_WebApp__c` |
| Lead | `Email_Alert_for_the_lead_assignment_rules` | After-save flow (create) | **Active** |
| Task | `Task_to_complete_for_Sales_Rep` | Process Builder | **Active** |
| User | `Okta_User_created_notificaiton` | Process Builder (create) | **Active** |

## 3. Apex design

| Class | Pattern | Sharing | Called by | Test class |
|---|---|---|---|---|
| `OrderChangeHandler` | Trigger handler, publishes a platform event | with sharing | `OrderChangeTrigger` | `OrderChangeTriggerTest` (one trivial assert) |
| `ULabOrderStatusKPIHandler` | Trigger handler | | `OrderChangeTrigger` | `ULabOrderTriggerTest` (thorough) |
| `uLabOrderTriggerHandler` | `@InvocableMethod` (not a trigger handler, despite its name) | with sharing | Flow `AWS_All_uAssist_Notifications` | **None** |
| `EmailAlertReaderQueueable` | Queueable + callouts. Metadata SOAP self-callout using the session Id | *none declared* | `uLabOrderTriggerHandler` | **None** |
| `NotificationController` | `@AuraEnabled` service for the LWC | with sharing | LWC `notificationcenter` | **None** |
| `NotificationFilterAction`, `NotificationDebugAction` | `@InvocableMethod` | with sharing | Draft test flow only | **None** |
| `MarketingRewardAssociationHandler`, `MRASendToBoomi`, `MRAActiveStartDateHelper` | Trigger handlers / helpers | with sharing (helper) | MRA triggers | `MarketingRewardAssociationTest` (some asserts commented out), `MraEffectiveDateBatchTest` |
| `MraEffectiveDateBatch`, `MraEffectiveDateScheduler` | Batch / Schedulable | | Scheduler | `MraEffectiveDateBatchTest` |
| `MarketingRewardProcessor` | Batch | | Manual | `MarketingRewardProcessorTest` |
| `ProgramBundleAssociationTriggerHandler` | Trigger handler, publishes a platform event | | Trigger | `ProgramBundleAssocTriggerHandlerTest` |
| `CompanyTotalPriceBatch`, `CompanyTotalPriceHelper` | Batch / Schedulable / `@AuraEnabled` | | Aura button, schedule | `CompanyPriceTotalBatch_test` |
| `CreditRequestController` | `@AuraEnabled(cacheable)` | with sharing | LWC `approvedCreditRequests` | **None** |
| `Showme` | `@AuraEnabled` callout to the AlignerOEM messages API | *none declared* | Aura `Recordpage`, quick action `test` | `showmetestclass` (no asserts) |
| `TechReviewController` | `@AuraEnabled` | | LWC `uAssistCommentPopup` | **None**. The method the LWC imports is commented out |
| `TriggerBypass` | Static flag | | Not referenced | n/a |

There is no common trigger framework. Each trigger calls its own handler or contains inline logic, and two objects have more than one trigger.

## 4. Order of execution: points to know

- **`uLab_Order__c` save:**
  1. Three before-save flows run. Their order is not defined.
  2. Validation rules run.
  3. Two active after triggers run (`OrderChangeTrigger` and the empty `uLabOrderTriggers`).
  4. Two after-save notification flows run.
  5. The workflow rule runs.

  `OrderChangeHandler` performs a **self-update** to reset `Generate_PE_Manually__c`, which runs the whole chain again.
- **MRA save:** two active triggers (`MarketingRewardAssociationTrigger` and `RewardAssociationTrigger`) both run before-insert/update logic, and Salesforce does not guarantee their order. Process Builders, a workflow rule and three flows also run. Six different automations can set `Send_to_Boomi__c`. `MRAActiveStartDateHelper` updates sibling MRAs, which re-fires both triggers. There is no recursion guard; the chain stops only because the dates do not change again.
- **Credit Request ≤ $250:** the after-save auto-approval flow sets Approved, and then `Record_Lock_after_approved` evaluates in the same save. **TO BE CONFIRMED:** test whether a non-admin creator gets blocked.

## 5. Technical risks and recommendations

| # | Risk | Where | Recommendation |
|---|---|---|---|
| 1 | Hard-coded record type, user and template Ids | `Flag_Send_to_NetSuite` (`01252000001on56AAA`), `Credit_Request_Below_250_Approval` (`012RK00000BXa4nYAD`), `RewardAssociationTrigger`, scheduled pricing flow, STAFF50 flow (`0126g000000bOB*`), `Test_notification_center` | Use DeveloperName lookups. Ids differ between sandboxes and production |
| 2 | **Missing test coverage** | `EmailAlertReaderQueueable`, `uLabOrderTriggerHandler`, `NotificationController`, `NotificationFilterAction`, `NotificationDebugAction`, `CreditRequestController`, `TechReviewController` | Write tests before any production deployment (75% rule). Weak tests (`OrderChangeTriggerTest`, `RewardAssociationTrigger_Test`, `NFATriggerTest`, `showmetestclass`) need real asserts |
| 3 | Session-Id self-callout in a Queueable | `EmailAlertReaderQueueable` (Metadata API v59, remote site `SalesforceOrgDomain`, staging URL) | Use a Named Credential with OAuth, or store the alert recipients in custom metadata. Failures are only written to `System.debug` |
| 4 | Credentials in metadata | Custom Label `Authkey`, `showmemockclass`, Okta connected app | See [Salesforce-Environment.md §6](Salesforce-Environment.md#6-security-findings) |
| 5 | Duplicate triggers on one object | `uLab_Order__c` (1 active empty + 2 inactive), MRA (2 active) | One trigger per object with a handler and a bypass. `TriggerBypass` exists but is unused |
| 6 | Legacy automation | 6 active Process Builders, 3 active workflow rules, ~15 obsolete or draft flows | Migrate to record-triggered flows. Delete obsolete versions |
| 7 | Bugs found in the code | `NFATrigger` blocks the whole batch on any match, not on the exact company/feature pair. `RewardAssociationTrigger` uses `currentAcc[0]` for every record, can throw a null pointer on `Program_Name__c`, and can overflow Text(32). Notification "Contact rule 3" compares Contact Ids to a User lookup | Fix, and add tests |
| 8 | SOQL injection | `NotificationDebugAction` concatenates `recordId` into the query | Use bind variables, or remove the debug class |
| 9 | Performance | Scheduled pricing flow does a Get Records inside a loop and re-queries the whole set. `EmailAlertReaderQueueable` renders and sends inside a loop | Bulkify |
| 10 | Possible duplicate email | The In Progress branch of `AWS_All_uAssist_Notifications` does not stamp `uA_In_Progress_Sent__c` | Stamp the field after sending |
| 11 | Broken references | LWC `uAssistCommentPopup` imports a commented-out method. Obsolete flow `uAssist_comments_updated` references a missing Apex action. `uLabOrderTrigger_Test` calls `uLabOrder_Batch` (not in scope; **TO BE CONFIRMED** in the org) | Fix or delete |
| 12 | Test logic in production code | `Showme` returns canned JSON when `test__c = 'test123'`. Quick action `test`. Alert `Test_Email_Alert_for_notitifcation_center` | Remove |
| 13 | Unused metadata | `Contact_Notification_Preference__c`, `Contact_Account_Notification__c`, empty utility-bar flexipage, ~7 unused Credit Request alerts | Delete or finish |
| 14 | Mixed API versions | 49.0 to 67.0 | Raise old components when they are touched |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from Ulab Sandbox metadata. |
