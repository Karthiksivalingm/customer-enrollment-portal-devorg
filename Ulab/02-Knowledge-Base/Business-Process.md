# Business Processes

This page describes how the business processes in scope work in the Ulab Sandbox, step by step.

- **Sources:** retrieved metadata in [`force-app/main/default/`](../force-app/main/default/).
- **Technical detail:** [Technical-Architecture.md](Technical-Architecture.md).
- **External systems:** [Integrations.md](Integrations.md).

In this org, Account is labelled **Company**.

---

## 1. uLab Order and uAssist lifecycle

### 1.1 Order types

`uLab_Order__c` has 8 active record types:

| Record type | Use |
|---|---|
| `Aligner_Order` | Standard aligner order |
| `Aligner_OEM` | OEM aligner order |
| `uAssist_Order` | uAssist treatment-planning order ("Non-Cloud" in the flow names) |
| `Cloud_uAssist_Order` | uAssist order from uDesign Cloud ("Cloud") |
| `DPA_Order` | Direct Print Aligner order |
| `IDB_Order` | Indirect bonding tray order |
| `Replacement_Order` | Replacement of an earlier order (`Orignal_Order_ID__c` points to the original) |
| `Internal_uLab_Order` | Internal orders |

There are two separate status fields:

- **`uAssist_Status__c`** tracks the treatment-planning work. It has 29 values.
- **`Order_Status__c`** tracks manufacturing and shipping: Processed → Shipped → Delivered, or Cancelled.

### 1.2 uAssist status flow

```
Submitted ─► In Progress ─► Model Prep in Progress ─► Model Prep Complete ─► Tech Review / Treatment Plan Review
                │                                                                     │
                ├─► On Hold – <reason> ──(released)──► back to work                    ▼
                │                                                         Case ready to review (CRTR)
                │                                                                     │
                │                     Modification Requested ◄────────────────────────┤
                │                     Modification in Progress ─► Modification Complete ─┘
                │                                                                     │
                ├─► Rejected (terminal)                                               ▼
                └─► Cancel (terminal)                                      Completed (system only, terminal)

Cloud QC stages: Ready to QC ─► QC in Progress ─► (Rework Required) ; Ready for Mod QC ─► Mod QC In Progress
```

There are eight **On Hold** reasons:

- Rx Form needs review
- New photos needed
- New scans needed
- New X-Rays needed
- New scans, photographs and X-Rays needed
- Scans and images do not match
- New photos and Rx form review needed
- Please review uAssist Message

### 1.3 Rules enforced by validation rules

Most rules apply to Cloud orders. Users with the custom permission `Bypass_uAssist_Status_Validation` (the integration/system user) skip them.

- **Completed** can be set only by the system, and it is terminal.
- **Cancel** and **Rejected** are terminal. Once `Date_entered_Rejected_Status__c` is set, the order stays Rejected.
- After **Case ready to review**, the uAssist Team cannot cancel or reject the order.
- An order that has been **invoiced** (`Billing_System_Inv_Number__c` set) cannot be rejected.
- An order cannot be cancelled once it is **Shipped**.
- At CRTR, Plan 1 and Plan 2 text are required, depending on `Number_of_Plans__c`.
- Users with the `Block_InProgress_Update` permission (the QC API user) cannot set QC statuses, and cannot move an order from QC back to In Progress.
- Only bypass users can edit `Voided__c`.

### 1.4 Who moves the order

| Actor | How it is identified | Typical changes |
|---|---|---|
| uAssist team (≈29 active users, profiles "uLab uAssist Team" and "Lead & Sr. Trainer") | Profile / role contains "uAssist" | In Progress, On Hold, Model Prep, CRTR, Modifications |
| Integration users | `$User.Alias` = `ApiUser` or `Jarvis` | Status updates from uDesign Cloud / WebApp, Completed |
| Client Services, Sales | Profile | Cancellation through the **Cancel uAssist Order** button |

### 1.5 Cancelling an order

The **Cancel uAssist Order** quick action launches the `Cancel_a_Order_Button` screen flow:

1. The flow refuses if the order's field history shows it ever reached *Case ready to review*.
2. If the user's role contains "uAssist", an Assigned uAssistant must be set.
3. The user enters the Cancellation Date, Requested By, Reason (multi-select) and Comments. They must also tick **"I NOTIFIED THE ASSIGNED OWNER"**.
4. The flow sets `uAssist_Status__c = Cancel`.
5. For Cloud orders, a before-save flow then copies the cancellation comments into `On_Hold_Message__c`, so they travel to the WebApp.

### 1.6 Status sync and customer emails

Each status change is sent to the uDesign WebApp through AWS. The customer email is sent **after AWS confirms** the event.

```
User changes uAssist_Status__c
  └─ before-save flow  Cloud_uAssist_Order_Notification  → Send_to_WebApp__c = true (not for ApiUser/Jarvis; not for Cloud QC statuses)
                                                          → Send_to_NetSuite__c = true on In Progress / CRTR / Cancel / Rejected
  └─ after-update trigger OrderChangeTrigger → OrderChangeHandler
        publishes platform event sfdc_order_statusChanged__e  ──► AWS EventBridge ──► WebApp
  AWS writes back AWS_EventBridge_Status__c = Success | Failed
  └─ after-save flow AWS_All_uAssist_Notifications (Cloud) / NonCloud_uD_uA_Order_Customer_Notification (Non-Cloud)
        Success → send the email for the current status, stamp uA_<stage>_Sent__c, reset AWS status and Send_to_WebApp__c
        Failed  → no email, reset Send_to_WebApp__c
```

**Customer emails by stage.** These are email alerts on `uLab_Order__c`. They are sent from org-wide address support@ulabsystems.com to the Company email, Company owner, related Doctor/IS emails and the submitting user.

| Stage | Cloud alert | Non-Cloud alert / template |
|---|---|---|
| New order received | `New_uAssist_Order_Notification` (to the uAssist team) | same |
| In Progress | `Cloud_uA_In_Progress`, sent through the **Notification Center** engine (§4) | `uAssist_Order_Customer_Notification_In_Progress` (uAssist Order Submitted) |
| On Hold | `Cloud_uA_On_Hold_Pt_Overview`; `Cloud_uA_On_Hold_TX_Plan` for "Please review uAssist Message" | `uAssist_Order_Customer_Notification_On_Hold` |
| Case ready to review | `Cloud_uA_CRTR` (not for Retainer Fast Track) | `uAssist_Order_Customer_Notification_Ready_to_Review` |
| Modification Complete | `Cloud_uA_Mod_Complete` | `uAssist_Order_Customer_Notification_Modification_Complete` |
| Rejected | `Cloud_uA_Rejected` | `uAssist_Order_Customer_Notification_Rejected` |
| Cancel | `Cloud_uA_Canceled` | Rejected template reused |

### 1.7 Status KPIs

Every change to `uAssist_Status__c` or `Order_Status__c` writes a row to `ULab_Order_Status_KPI__c`. A row is also written the first time `Assigned_CRB__c` is set. Each row records the field, the previous and new value, the dates and the assigned user. The order also carries `Date_entered_<status>__c` timestamps and SLA formulas, such as the hours from In Progress to Rejected or the time spent On Hold. These feed turnaround reporting.

### 1.8 NetSuite flags

The flow `Flag_Send_to_NetSuite` and the Cloud flow set `Send_to_NetSuite__c` in two cases:

- The order is In Progress and has no NetSuite Sales Order ID yet.
- The order is at CRTR and has no invoice number yet.

*Inferred:* Boomi picks flagged orders up and creates the sales order or invoice in NetSuite (see [Integrations.md](Integrations.md)).

---

## 2. Credit Requests

### 2.1 Purpose

A **Credit Request** (`Credit_Request__c`) asks for money back or a credit for a customer. It is used when a product had a problem; the reason codes include *Too tight/Too loose, Wouldn't seat, Discomfort, Deformity, Poor clarity, Trim line issues, Missing aligners/attachments, Missed delivery deadline, Chipped mold, System Error*.

A request links to:

- the **Company**
- optionally the **uLab Order**
- the **Contact** who asked

Formula fields pull the order, invoice, case, patient and company details. The currency comes from the billing country (USD, CAD, AUD or NZD).

### 2.2 Status values

New → Under Review → Submitted → **Approved** / **Denied** → Processed → Accounting Applied → Archived

### 2.3 Current process (record type *Customer Adjustment*)

```
Client Services creates Credit Request (Customer Adjustment), enters Credit_Request_Amount__c
   │
   ├─ Amount ≤ $250 ─► flow Credit_Request_Below_250_Approval sets Status = Approved automatically
   │
   └─ Amount > $250 ─► submit for approval: "Credit_Request_Approval_A" (only active approval process)
          on submit : Status = Submitted, email CR_Email to RSM + ASD
          approve   : Status = Approved,  email Aprroved_Email to RSM + ASD
          reject    : Status = Denied, Denial Reason = "Request Denied", denial date, email Approval_Denied_Email
   │
   After approval
   ├─ Finance enters Actual_Amount_Entered_In_Netsuite__c ─► Send_to_NetSuite__c = true
   └─ NetSuite Credit Memo ID stored (NS_Credit_Memo_ID__c) + Approved ─► Send_to_Boomi__c = true
```

- **ASD** means Area Sales Director. A Process Builder stamps the Company owner's manager into `ASD_Manager__c` and `ASD_for_approval_process__c` whenever a Company is set.
- **RSM** means Regional Sales Manager, the Company owner.
- **Locking:** after approval, or after submission when the amount is over $250, only a System Administrator or the Company's Area Sales Director can edit the record (`Record_Lock_after_approved`).
- **TO BE CONFIRMED:** In the sandbox the single approval step is assigned to a **named user**, not to `ASD_Manager__c`. The inactive version `_1` uses `ASD_Manager__c`. Confirm which design is intended for production.

### 2.4 Legacy model (inactive, kept for history)

Five inactive approval processes used a tiered model on `Total_Amount_Requested__c`:

| Tier | Amount | Approver |
|---|---|---|
| 1 | < $100 | Named finance/CS users |
| 2 | $100–249 | ASD |
| 3 | $250–499 | ASD manager |
| 4 | $500–999 | Named director |
| 5 | ≥ $1,000 | Named executive |

Some versions also had a Finance approval step at the end. Record types moved Initial → Submitted → Approved.

### 2.5 Home-page list

The **Approved Credit Requests** LWC on the Home page lists approved requests, newest first.

---

## 3. Marketing Rewards, Programs and Promotions

### 3.1 Concepts

| Record | Meaning |
|---|---|
| **Marketing Reward** (`Marketing_Reward__c`) | A program or promotion definition with its price list: aligner, retainer, STL, uAssist and bundle prices (≈200 fields) |
| **Marketing Reward Association (MRA)** | Links a **Company** (master-detail) to a Marketing Reward for a date window. Record type **Program Association** covers uPP, Premier, New Start, Futures and uStart. Record type **Promotion Association** covers free STLs, discounts, STAFF50 and similar |
| **Product Bundle** / **Program Bundle Association** | Which bundles (Mild, Moderate, Comprehensive, Retainer…) belong to a program, mirrored from NetSuite |
| **New Feature Association (NFA)** | A per-company feature flag (`uLab_Feature__c`) with Active/Inactive status and dates |

### 3.2 Rules for an MRA

- The Company must be an active **"uLab Account"** when the MRA is created.
- The Effective Date must be on or before the End Date.
- The MRA record type must match the reward type (Program ↔ Program, Promotion ↔ Promotion).
- **Program Associations:** a company can have only one active program at a time. If a new program overlaps an existing one, its `Active_Start_Date__c` is moved to the day after the earlier program ends.
- **Futures promotions:** an overlapping Futures promo for the same bundle types has its Effective Date pushed past the existing one. If that makes it invalid, it is rejected with *"There is already a similar promotion…"*.
- **Send to Boomi** can be ticked only while the program is active. Only one Program Association per company may be flagged.

### 3.3 Lifecycle

```
MRA created (manually, by STAFF50 flow, or by yearly rollover job)
  └─ if Effective Date = today: copy ~24 prices from the Marketing Reward, set Company Email, Send_to_Boomi = true
  └─ otherwise: daily scheduled flow (05:30 UTC) copies prices on the Effective Date
              daily batch MraEffectiveDateBatch flags Send_to_Boomi on the Effective Date
  └─ Boomi syncs to NetSuite, writes NetSuite_Sync_Date__c / NSPL_Sync__c  (Inferred)
  └─ End Date changed after sync ─► Send_to_Boomi = true again
  └─ Company fields updated: Program_Name__c, uPP start/end, New Start date, Mari's List, Click n Go date
```

### 3.4 Promotions

- **STAFF50:** when a Commercial company becomes a "uLab Account" with an account number, a STAFF50 promotion MRA is created automatically. It has Max Qty 50, runs from today to 2026-12-31 and is flagged for Boomi.
- **AAOCOMPTRIO:** on creation, the company receives the "Exclusive Offer for You" promo-code email.
- **Mari's List / Click n Go:** associating these programs sets matching flags and dates on the Company.
- **Yearly rollover** (`MarketingRewardProcessor`): copies every program active on 2026-03-31 into a new MRA for 2026-04-01 to 2027-12-31. Excluded: *2024 uStart* and *Futures Gold*.

### 3.5 Program goals ("Company Matrix")

The **Calculate Company Matrix** button on the Company, or the scheduled batch, rolls up uLab aligner orders inside the active program window into Company fields:

- **Premier:** progress toward the annual goal (Partner A/B/C = $450k/$250k/$200k, prorated).
- **New Start:** month 1–4 counts.
- **uPP:** current-month and 6-month counts.

### 3.6 Feature flags and bundles

- **New features:** an NFA becomes Active, or its status changes → `Send_to_WebApp__c = true`. Only one NFA is allowed per company and feature.
- **Bundles:** when the integration user writes the NetSuite Bundle Association ID, the platform event `sfdc_bundle_updated__e` is sent to AWS.

---

## 4. Notification Center (email suppression)

Internal users open the **Notification Center** tab to choose which order emails they do **not** want to receive:

| Level | Setting | Stored in |
|---|---|---|
| User | "Disable all emails" | `User.Disable_All_Emails__c` |
| Company | Disable emails per selected Company | `User_Account_Notification__c` |
| Contact | Per Contact, optionally only for chosen email-template folders | `Contact_Notification__c` |
| Field rule | "Object.Field = Value → suppress" | `User_Notification_Preference__c` |

When an order email is due, `EmailAlertReaderQueueable` works out who should receive it:

1. It reads the email alert's recipient definition.
2. It expands roles and groups to users.
3. It adds the order's email fields.
4. It removes everyone suppressed by these settings. Contacts with *Email Opt Out* are also removed.
5. It sends one email per order.

**Current coverage:** only the Cloud **In Progress** email uses this engine. The mapping is in custom metadata `Ulab_Order_Notification__mdt` (one record). Every other status email is sent directly by email alerts and ignores the preferences.

The org has very little data for this feature so far (2 company, 1 field and 1 contact preference records). *Inferred:* it is still being piloted.

---

## 5. Sales support processes

| Process | How it works |
|---|---|
| **New lead assignment** | When a lead is created, the lead owner receives the "Leads New assignment notification" email (from a named sender) |
| **Aligner Workflow Plan** | A Task of record type *Aligner_Workflow_Plan* is mandatory before the DocuSign agreement. When it is Completed or Closed on a Company, the Company is marked `Aligner_WF_Task_Completed__c` with the date. *Inferred:* the Task status defaults to Closed, so the flag is set as soon as the task is created |
| **Practice metrics** | Events of record type *Practice_Metrics* capture annual aligner and bracket starts, in-house printing and the software used. When Status = Close, all metric fields are required |
| **Premier agreements** | Contacts hold the Premier type, the agreement effective and end dates (at most 12 months) and the transitional period |
| **Address quality** | Companies and Contacts need 2-letter US/CA states (2–3 for AU/NZ), 2-letter countries, and no `. , / \|` in street lines. Admin profiles are exempt |
| **Okta users** | When Okta provisions a user with profile *AA_Okta*, two administrators receive "New user has been created from Okta" |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from Ulab Sandbox metadata. |
