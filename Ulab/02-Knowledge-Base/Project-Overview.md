# Project Overview: uLab Systems Salesforce

## 1. Purpose of this knowledge base

This folder documents the Salesforce work done in the **Ulab Sandbox** by four team members:

- Meshak Michel
- Kaviya Natarajan
- Ankit Singh
- Sandip Patel

It covers:

- Automation (Flows, Apex classes, triggers, approval processes, workflow rules) that any of the four **created or last modified**.
- Objects and fields that any of the four **created**.
- Components those items depend on: email templates, platform events and channels, custom metadata, named credentials, remote sites and the connected app.

Everything here was built from metadata retrieved read-only from the sandbox on **2026-10-15**, plus record counts and settings queried the same day. Nothing in the org was changed.

| Document | Content |
|---|---|
| [Business-Process.md](Business-Process.md) | How the business uses Salesforce: orders and uAssist, credit requests, marketing rewards, notifications |
| [Technical-Architecture.md](Technical-Architecture.md) | Data model, automation per object, Apex design, order of execution, technical risks |
| [Salesforce-Environment.md](Salesforce-Environment.md) | Org facts, licences, profiles, installed packages, security findings |
| [Integrations.md](Integrations.md) | AWS EventBridge, Boomi / NetSuite, WebApp, AlignerOEM API, Okta |
| [Component-Inventory.md](Component-Inventory.md) | Every in-scope component with creator, created date, last modifier and modified date |

## 2. The business

uLab Systems makes clear aligners and retainers, and sells them to orthodontic and dental practices. In Salesforce a practice is a **Company**: the Account object is relabelled "Company".

The main products and services seen in the metadata:

- **uDesign / uDesign Cloud:** treatment-planning software.
- **uAssist:** uLab's treatment-planning service, where a uAssistant prepares the plan for the doctor.
- **Aligners, retainers, STL files, IDB trays, Direct Print Aligners (DPA), custom packaging:** physical products.
- **uSmile, Kai:** product lines, flagged on orders and accounts.
- **Marketing programs:** uPP (1–4 star), Premier Partner (A/B/C), New Start, Futures, uStart.
- **Promotions:** STAFF50, Click n Go, Mari's List, AAOCOMPTRIO and others.

## 3. Functional areas in scope

| Area | Main objects | Summary |
|---|---|---|
| **uLab Orders and uAssist** | `uLab_Order__c` (≈60k records), `uLab_Case__c` (≈70k), `ULab_Order_Status_KPI__c` | Order lifecycle through 29 uAssist statuses. Status changes are published to AWS, and customer emails are sent per stage. |
| **Credit Requests** | `Credit_Request__c` (96) | Customer credits for product issues. Requests of $250 or less are auto-approved; larger ones go to Area Sales Director approval. After approval the credit goes to NetSuite through Boomi. |
| **Marketing Rewards** | `Marketing_Reward__c` (109), `Marketing_Reward_Association__c` (2,477), `Program_Bundle_Associations__c` (87), `ProductBundles__c` | Programs and promotions linked to Companies, with date windows and price lists. Changes sync to NetSuite through Boomi. Bundle changes go to AWS. |
| **Feature flags** | `New_Feature_Association__c` (201), `uLab_Feature__c` | Per-company feature switches, sent to the WebApp. |
| **Notification Center** | `User_Account_Notification__c`, `User_Notification_Preference__c`, `Contact_Notification__c` (+2 unused) | Lets internal users suppress order emails by user, company, contact/folder, or field rule. Built Apr–May 2026; only used for the "In Progress" email so far. |
| **Sales support** | Lead, Task, Event, Account, Contact | Lead-assignment email, Aligner Workflow Plan tasks, practice-metric events, Premier agreement dates, address validation. |
| **Okta** | User, connected app | Okta provisions users. New Okta users trigger an admin email. |

## 4. Who built what

| Person | Created | Last modified | Main contributions (from the inventory) |
|---|---|---|---|
| **Sandip Patel** | Most 2022 work, some 2026 work | | Original Credit Request approval (2022), Company Total Price batch and Aura button, NFA feature flags, Okta connected app, Mari's List / Create MRA → Boomi Process Builders, Send to WebApp and NetSuite flag flows (2026) |
| **Ankit Singh** (now inactive in the org) | 2024–Feb 2026 | | uAssist chat (`Showme`, AlignerOEM API, Okta token), Credit Request ≤ $250 auto-approval and the current approval process, Marketing Reward Association trigger and handler, STAFF50 promo, approved-credit LWC |
| **Kaviya Natarajan** | Feb–Apr 2026 | | Marketing Reward Processor (rollover), TriggerBypass, Tech Review comment popup, lead-assignment email, Send to NetSuite (Account), uAssist flag flows |
| **Meshak Michel** | Mar–Sep 2026 | | Notification Center (objects, LWC, Apex, CMDT), order-status platform event and KPI handler, Cloud/Non-Cloud uAssist notification flows, cancel-order wizard, MRA effective-date batch and scheduler, Program Bundle → AWS event, MRA pricing-copy flows |

See [Component-Inventory.md](Component-Inventory.md) for the exact counts and dates.

## 5. Scope and limits

- **In scope:** 631 components. These include 32 Apex classes, 8 triggers, 34 flows, 6 approval processes, 7 objects and 241 fields created by the team, 54 validation rules, 61 workflow rules/alerts/field updates and 6 LWC/Aura bundles.
- **Retrieved as related:**
  - The full definitions of `uLab_Order__c`, `Credit_Request__c`, `Marketing_Reward__c`, `Marketing_Reward_Association__c`, `Program_Bundle_Associations__c`, `New_Feature_Association__c`, `ProductBundles__c` and `uLab_Feature__c`.
  - The workflow files for uLab Order, MRA and Account.
  - 17 email templates and their folders.
  - Both platform events, the AWS event channel and its members.
  - The `AWS_QA` named credential.
  - The `Ulab_Order_Notification__mdt` record.
- **Not documented:** components created and maintained only by other people, and managed packages (see [Salesforce-Environment.md](Salesforce-Environment.md)). Permission sets, layouts, list views and static resources touched by the team are listed in the inventory but not described.
- **Excluded from Git for security:**
  - The custom labels `Authkey` and `tokenapi`.
  - `showmemockclass.cls`, which contains an access token.
  - `Okta.connectedApp-meta.xml`, which contains the consumer key.

  They are listed in `Ulab/.gitignore`. See [Salesforce-Environment.md §6](Salesforce-Environment.md#6-security-findings).
- **Inferred statements** are marked *Inferred:*. Anything that needs confirmation from the business or the integration owners is marked **TO BE CONFIRMED**.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Knowledge base created from Ulab Sandbox metadata (read-only retrieval). |
