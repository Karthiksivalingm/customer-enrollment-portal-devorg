# Integrations

Salesforce exchanges data with five external systems. Each one uses one of these patterns:

1. **Flag fields** that middleware (Boomi) picks up.
2. **Platform events** relayed to AWS EventBridge.
3. **Apex callouts.**
4. **An inbound API user.**

No outbound messages were found in scope. Statements marked *Inferred:* are drawn from field names and descriptions; the integration owners must confirm them.

```
                   ┌──────────────── Salesforce (Ulab Sandbox) ────────────────┐
                   │                                                           │
 uDesign WebApp ◄──┤ sfdc_order_statusChanged__e ──► SFDC_AWS_Event_Channel ───┼──► AWS EventBridge (Named Credential AWS_QA)
   (via AWS)       │ sfdc_bundle_updated__e     ──►        (Event Relay)       │        │
                   │ AWS_EventBridge_Status__c ◄───────────── Success/Failed ──┼────────┘
                   │                                                           │
 Boomi ◄──(query)──┤ Send_to_Boomi__c      (MRA, Credit Request, Custom Pkg)   │
   │               │ Send_to_NetSuite__c   (uLab Order, Credit Request, Acct)  │
   ▼               │ NetSuite IDs / sync dates ◄── written back by ApiUser     │
 NetSuite          │                                                           │
                   │ Showme.cls ──► Okta CIAM token ──► AlignerOEM messages API│
 Okta ────────────►│ Connected App "Okta" (user provisioning, Api scope)       │
                   └───────────────────────────────────────────────────────────┘
```

## 1. AWS EventBridge / uDesign WebApp

| Item | Detail |
|---|---|
| Direction | Salesforce → AWS (events). AWS → Salesforce (status write-back) |
| Mechanism | High-volume platform events published by Apex, delivered by the custom channel `SFDC_AWS_Event_Channel__chn`. *Inferred:* an Event Relay sends them to EventBridge through the Named Credential `AWS_QA` (ARN endpoint, us-west-2, no authentication). The Event Relay configuration is not in source (**TO BE CONFIRMED**) |
| Channel members | `sfdc_order_statusChanged__e`, `sfdc_bundle_updated__e`, plus `sfdc_account_updated__e`, `accountuser_createdSuccess__e`, `accountuser_createdFailed__e`, `user_updated__e` (the last four are outside the team scope) |

### 1.1 Order status changes

| Item | Detail |
|---|---|
| Event | `sfdc_order_statusChanged__e` |
| Publisher | `OrderChangeHandler` (from `OrderChangeTrigger`, after update) |
| When | `Send_to_WebApp__c = true` and `uAssist_Status__c` changed, or `Generate_PE_Manually__c` switched to true (manual re-send) |
| Gate | The before-save flow `Cloud_uAssist_Order_Notification` sets `Send_to_WebApp__c` only for changes **not** made by `ApiUser` or `Jarvis`. This stops changes that came from the WebApp being sent back to it |
| Payload | `eventType__c` = `sfdc.order.statusChanged`, `uLab_Acct_Number__c`, `order_id__c`, `RecordTypeId__c`, `uassist_status__c`, `uAssist_Status_Old__c`, `Number_of_Plans__c`, `Plan_1__c`–`Plan_3__c`, `On_Hold_Message__c` (carries the cancellation or rejection comments), `Order_Cancellation_Comments__c`, `uAssistant_First_Name__c`, `uAssistant_Last_Name__c`, `Event_Processing_Sequence__c` |
| Acknowledgement | The external side writes `uLab_Order__c.AWS_EventBridge_Status__c` = Success or Failed. On Success the notification flows send the customer email and reset the flags. On Failed they only reset `Send_to_WebApp__c` |
| Error handling | Publish errors are written to `System.debug` only. **TO BE CONFIRMED:** whether anyone monitors Failed statuses |

### 1.2 Program bundle updates

| Item | Detail |
|---|---|
| Event | `sfdc_bundle_updated__e` |
| Publisher | `ProgramBundleAssociationTriggerHandler` |
| When | `Program_Bundle_Associations__c.NetSuite_Bundle_Association_ID__c` is set or changed by a user with alias `ApiUser`, **and** the parent `ProductBundles__c.Event_Trigger__c = true` (or it is the bundle's only association). The handler then resets `Event_Trigger__c` |
| Payload | `Record_Id`, `Marketing_Reward_Id`, `Program_Name`, `Bundle_Id`, `Bundle_Type`, `Effective_Date`, `End_Date`, `Active`, `NetSuite_Item_ID`, `NetSuite_Bundle_Association_ID` |
| Flow of data | *Inferred:* NetSuite → Boomi → Salesforce (ID written) → AWS → WebApp |

### 1.3 Feature flags to the WebApp

`New_Feature_Association__c.Send_to_WebApp__c` is set by the Process Builder `New_Customer_Feature_Flag_Update_NFA`. The source contains no event or callout for it. *Inferred:* the WebApp or middleware polls this flag. **TO BE CONFIRMED.**

## 2. Boomi → NetSuite

| Item | Detail |
|---|---|
| Direction | Salesforce → NetSuite through Boomi, with IDs and dates written back |
| Mechanism | Checkbox flags. No callout, outbound message or Boomi credential exists in source. *Inferred:* Boomi queries flagged records using the `ApiUser` integration user, then clears the flags |

**Flags Boomi reads:**

| Object | Flag | Set by | Write-back fields |
|---|---|---|---|
| Marketing Reward Association | `Send_to_Boomi__c` | Scheduled/record flows on the Effective Date, `MraEffectiveDateBatch`, End-Date-change flow, STAFF50 flow, Promotion workflow rule, `Create_MRA_send_to_Boomi` PB. Guarded by `MRASendToBoomi` (one flagged Program per company, only while active) | `NetSuite_Sync_Date__c`, `NSPL_Sync__c`, `NetSuite_Promo_Code__c` |
| Credit Request | `Send_to_NetSuite__c` | `Credit_Request_update_ASD` when the NetSuite amount is entered | `NS_Credit_Memo_ID__c` |
| Credit Request | `Send_to_Boomi__c` | `Credit_Request_Update_flag_on_Approval` (Approved and a credit memo Id exists) | |
| uLab Order | `Send_to_NetSuite__c` | `Flag_Send_to_NetSuite`, `Cloud_uAssist_Order_Notification` (In Progress, CRTR, Cancel, Rejected) | `NetSuite_SO_Internal_ID__c`, `Billing_System_Inv_Number__c` |
| Account (Company) | `Send_to_NetSuite__c` | Obsolete flows only, in scope. **TO BE CONFIRMED:** the current mechanism | `NS_Customer_Internal_ID__c` |
| Custom Packaging Artwork | `Send_to_Boomi__c` | No automation in scope | |
| Program Bundle Association | (inbound) | | `NetSuite_Bundle_Association_ID__c`, `custrecord_*` fields |

**Risk:** six automations can set the MRA flag. If Boomi does not clear it, records may be re-sent. Confirm the Boomi process's selection query and reset logic with the integration owner.

## 3. AlignerOEM messages API, through an Okta CIAM token

| Item | Detail |
|---|---|
| Purpose | Shows the uAssist communication thread (doctor ↔ uAssistant messages) on the order page |
| Component | `Showme.cls` (`@AuraEnabled getmessagesfromapi`), Aura `Recordpage`, quick action `uLab_Order__c.test` |
| Flow | 1) POST to the Okta CIAM token URL (Custom Label `tokenapi`) with `grant_type=client_credentials&scope=m2m` and a Basic `Authorization` header (Custom Label `Authkey`). 2) GET `https://apis.qa.aligneroem.com/shared/v1/org/{account}/patients/{patient}/txplans/{case}/messages` with the bearer token |
| Remote sites | Okta CIAM QA and prod, AlignerOEM QA and prod |
| Issues | The QA host is hard-coded. The credential is stored in a Custom Label. There is a test backdoor (`test__c = 'test123'`). The test class has no asserts |
| Recommendation | Use a Named Credential plus an External Credential (OAuth client credentials) for each environment, and remove the labels |

## 4. Okta (identity)

| Item | Detail |
|---|---|
| Connected app | `Okta`. OAuth scopes Basic, Api, RefreshToken. Callback is the Okta admin generic OAuth redirect. *Inferred:* used by Okta to **provision Users** through the API, not for end-user SSO |
| Automation | The Process Builder `Okta_User_created_notificaiton` emails two administrators when a user with profile `AA_Okta` is created |
| Licences | Identity licence: 1 of 100 used |
| Issues | Refresh token policy is "infinite" and the app is not admin-approved. Review these settings |

## 5. Salesforce self-callout (Metadata API)

`EmailAlertReaderQueueable` calls the org's own Metadata SOAP API (`/services/Soap/m/59.0`) using `UserInfo.getSessionId()` and the remote site `SalesforceOrgDomain`. It does this to read each email alert's recipient list at run time, for the Notification Center. This is an internal integration, but it depends on the org URL and on session behaviour in async context. See [Technical-Architecture.md §5](Technical-Architecture.md#5-technical-risks-and-recommendations).

## 6. Open questions for the integration owners

1. Is Event Relay configured for `SFDC_AWS_Event_Channel__chn`, and which EventBridge bus does it target in production?
2. What does Boomi select and reset for each `Send_to_Boomi__c` / `Send_to_NetSuite__c` flag, and on what schedule?
3. Who monitors `AWS_EventBridge_Status__c = Failed`, and how are those events re-sent? (`Generate_PE_Manually__c` exists for manual re-sends.)
4. What is the production equivalent of `AWS_QA`, the Okta token URL and the AlignerOEM host?
5. How does the WebApp consume `New_Feature_Association__c.Send_to_WebApp__c`?

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from Ulab Sandbox metadata. |
