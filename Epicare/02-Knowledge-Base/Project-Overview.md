# Epicare Project Overview

> Main entry point of the Knowledge Base. It is built from the verified Epicare Insurance sandbox `UTDEV` (`00DWB000008ALkv2AG`)
> and the metadata retrieved on 2026-10-15. Statements are **Confirmed** (read in metadata, source or an org query) or
> **Inferred** (interpretation of names and structure). Anything else is listed under *Not determined*.

## 1. What Epicare's Salesforce org does

| Statement | Basis |
|---|---|
| The org belongs to **Epicare Insurance** (Enterprise Edition). This project works on its sandbox `utdev`. | Confirmed |
| Salesforce is the agency's **back office for insurance agents and agencies**. It covers onboarding, licensing, carrier contracting and appointments, commissions, payouts and reconciliation. Agents are Contacts (record type `Agent`); agencies and uplines are Accounts (`Agency`). | Confirmed by the data model. The business framing is Inferred |
| Lines of business: Medicare, ACA, Life, Supplementary, Annuities, Health. | Confirmed (`Line_of_Business` value set) |
| Salesforce exchanges events with **GO AMS**, an agency management system / agent portal on Supabase, and pulls licensing data from **NIPR**. | Confirmed (credentials, callouts, events). The role of GO AMS is Inferred |
| Sales of policies to consumers are **not** managed here (Opportunity has 4 custom fields; Lead and Case have none). | Inferred |

## 2. Business processes (evidence-based)
| Process | Main components |
|---|---|
| **1. Agent onboarding** | Contact `Agent_Status__c` and `Onboarding_Step__c` (forward-only rules), `Onboarding_Checklist__c`, events `EPA_Signed__e` and `Onboarding_Step__e`, screen Flow `Account_Agent_Onboarding`, checklist escalation job |
| **2. Licensing and compliance** | `DOI__c`, `LOA__c`, `License__c`, `NAICProducerCode__c`, `Certification__c` (AHIP, FFM, E&O). NIPR NPN/SSN lookups and PDB alerts. Expiry alert jobs |
| **3. Carrier contracting and appointments** | `Carrier__c`, `Appointment__c` (Ready-to-Sell gates: writing number, effective date, certification gate), `State_Appointment__c`, events `Appointment_Requested__e` and `Appointment_Status_Changed__e`, the Contracting reports and dashboard |
| **4. Products and commission schedules** | `Product__c` → `Product_State__c` → `Renewal_Schedule__c`. Payment models: as-earned PMPM, advanced 6/9, partial advance |
| **5. Commissions, payouts and reconciliation** | `Commission_Import_Log__c` → `Upline_Policy__c` → `Commission_Record__c` (5 triggers, exceptions, chargebacks). `Payment_Batch__c` with segregation-of-duties approval. `Commission_Paid__e`. `CommissionReconciliationEngine`. Payment batch assembly on the 12th; missing-payment check |
| **6. Upline policy reconciliation** | `Upline_Policy__c` recon status, `Premium_Payments__c`, `Carrier_Alias__c`, the Upline Reconciliation dashboard |
| **7. Referrals and override agreements** | `Referral_Record__c`, `Agreement__c`, referral accrual batch, `ReferralRollupTrigger` |
| **8. Data governance** | `Data_Retention_Rule__mdt` (rules in Test_Mode), `Data_Retention_Log__c`, `Security_Incident__c`, encrypted-data permission, system log export |

## 3. The org in numbers (Confirmed, unmanaged metadata in source)
| Area | Count |
|---|---|
| Apex | 148 classes (73 tests); 33 triggers (11 are platform-event subscribers) |
| Flows | 22 (19 Active): 15 record-triggered, 7 screen |
| Data model | 48 objects in source; ~25 custom objects; 12 platform events; 724 unmanaged fields; 24 validation rules |
| UI | 50 Lightning pages, 34 layouts, 27 tabs, 5 apps, 1 LWC, 2 Aura components |
| Security | 26 profiles, 24 permission sets, 6 permission set groups, 5 roles, 4 objects with sharing rules |
| Analytics | 206+ reports and 16 dashboards in public folders (Contracting, Commissions, Upline Reconciliation, Executive, Operations, plus standard samples) |
| Scheduled | 17 scheduled Apex jobs (9 waiting, 8 paused) |

## 4. Knowledge Base map
| Page | Covers |
|---|---|
| [Salesforce-Org-Context.md](Salesforce-Org-Context.md) | Verified identity, packages, features not enabled |
| [Data-Model-and-Relationships.md](Data-Model-and-Relationships.md) | Objects, relationships, rules, configuration, sensitive data |
| [Automation-and-Execution-Order.md](Automation-and-Execution-Order.md) | Triggers, Flows, events, jobs, rules, order of execution |
| [Integrations-and-External-Systems.md](Integrations-and-External-Systems.md) | GO AMS / Supabase, NIPR |
| [Security-and-Permissions.md](Security-and-Permissions.md) | OWD, roles, sharing, profiles, permission sets |
| [Technical-Architecture.md](Technical-Architecture.md) | Layers and component dependencies |
| [Known-Constraints.md](Known-Constraints.md) | Risks, limits, open questions |
| [Metadata-Inventory](../07-Technical-Documents/Metadata-Inventory/README.md), [Retrieval report](../07-Technical-Documents/Retrieval/Retrieval-Report.md) | What is in source, and what could not be retrieved |

## 5. Not determined
- Business priorities and current requirements. No requirements have been received yet.
- Production configuration, data volumes, and which paused jobs run in production.
- Exactly what GO AMS does, and which system publishes the inbound events.
- Whether the reports from the two unmanaged report packages are in use.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the baseline retrieval and read-only org queries. |
