# Data Model and Relationships

Built from `force-app/main/default/objects/` (retrieved 2026-10-15). Coverage: 48 objects. These are the unmanaged custom objects,
platform events, custom settings and custom metadata types, plus the standard objects that carry unmanaged fields.
Field-level detail for each object is in [Metadata-Inventory/Objects](../2026-10/07-Technical/Metadata-Inventory/Objects-and-Fields.md).
Purposes marked INFERENCE are read from names and fields. MD = master-detail; OWD = organization-wide default (internal / external).

## Core standard objects
| Object | OWD | Custom fields | Record types | Role in Epicare |
|---|---|---|---|---|
| **Contact** | Read / Read | 67 | `Agent`, `Agency_Director` | **The insurance agent.** Fields:<br>• Status and onboarding: `Agent_Status__c` (Onboarding / Active / Inactive / Suspended / Terminated), `Onboarding_Step__c`<br>• Identity: NPN, agent code<br>• Certifications: AHIP / AML / FFM, E&O<br>• Compliance: background, banking, license and certification status, `Overall_Semaphore__c`, `Compliance_Score__c`<br>• Sensitive: SSN, bank routing / account numbers<br>• External IDs: GO AMS and Supabase<br>8 validation rules, e.g. `NPN_Required`, `EO_Required_for_Activation`, `Onboarding_Forward_Only`, `Status_Change_Requires_Reason` |
| **Account** | Read / Read | 19 | `Agency`, `Epicare_Corp` | **The agency or upline.** Fields: NPN, FEI/EIN, NIPR dates, `Agency_Tier__c`, `Agency_Status__c`, `Is_Upline_of_Epicare__c`, `Override_Type__c`, Supabase ID. Lookups to Agency Director and Principal (Contact) |
| Opportunity | Read / Private | 4 | — | Generic sales fields only. INFERENCE: not a core process |
| AccountContactRelation | — | 1 | — | `Relationship_Strength__c` |

Lead and Case carry no unmanaged fields, so they are not in source. Only a Lead Lightning page is retrieved.

## Custom objects by functional area
| Area | Objects (OWD) | Key relationships and rules |
|---|---|---|
| **Licensing (NIPR / DOI)** | `DOI__c` (Read; record types Agency_License, Agent_License; 60 fields incl. SSN), `LOA__c` (MD), `License__c` (Read), `NAICProducerCode__c` | `DOI__c` → Account, Contact. `LOA__c` MD → `DOI__c` (lines of authority, CE credits). `License__c` → Agency (Account), Agent (Contact) |
| **Carriers and products** | `Carrier__c`, `Carrier_Alias__c`, `Product__c`, `Product_State__c` (MD), `Renewal_Schedule__c` (MD), `Product_Holder__c` | `Product__c` → Carrier. `Product_State__c` MD → Product: commission rates by state, level and renewal year. `Renewal_Schedule__c` MD → Product_State (rules `Year_To_Range`, `Year_From_Minimum`, `ValidatePercentageOrFixedRate`). `Carrier__c` rule `At_least_one_LOB_must_be_selected` |
| **Contracting and appointments** | `Appointment__c` (Read), `State_Appointment__c` (Read), `Certification__c`, `Onboarding_Checklist__c`, `Notes__c` | `Appointment__c` → Agent, Agency/Upline, Carrier, Product. 7 rules gate activation: writing number and effective date for Ready-to-Sell, carrier certification gate, payment model, termination reason, advance-month range. `State_Appointment__c` → Appointment |
| **Commissions** | `Commission_Record__c` (Private, 61 fields), `Commission_Exception__c`, `Commission_Forecast__c`, `Commission_Import_Log__c`, `Payment_Batch__c` (Private), `Agreement__c` (Private), `Referral_Record__c` (Private) | `Commission_Record__c` → Agent, Agency, Carrier, Agreement, Appointment, Payment_Batch, Upline_Policy, Referral_Record, Product, and itself (original commission). Rules: `Lock_Amounts_After_Approval_SoD`, `Referral_CR_Requires_Links`. `Payment_Batch__c` rule `Approver_not_equal_to_Submitter`. `Referral_Record__c` rule `Verified_Requires_Agreement` |
| **Upline reconciliation** | `Upline_Policy__c` (Read, 38 fields, recon status), `Premium_Payments__c` | `Upline_Policy__c` → Agency, Carrier, Agent, and itself (reactivated from). `Premium_Payments__c` → Upline_Policy |
| **Banking** | `Banking_Info__c` (Private) | → Agent, Agency, Verified_By (User). Rule `Verifier_not_equal_to_Creator_SoD` |
| **Governance and logging** | `Security_Incident__c` (Private), `Error_Log__c`, `Data_Retention_Log__c` | — |

## Platform events (12)
`Agent_Created__e`, `Agent_Deactivated__e`, `Appointment_Requested__e`, `Appointment_Status_Changed__e`, `Commission_Exception_Event__e`,
`Commission_Paid__e`, `EPA_Signed__e`, `Enrollment_Approved__e`, `License_Alert__e`, `Onboarding_Step__e`, `Upline_Policy_Created__e`,
`Upline_Policy_Import_Completed__e`. INFERENCE: these are the integration contract with external systems (GO AMS, the agent portal).
See [Integrations](Integrations-and-External-Systems.md).

## Configuration
| Item | Content |
|---|---|
| `Certification_Gate_Settings__mdt` | Record `Default`: certification gate cutoff date |
| `Data_Retention_Rule__mdt` | 6 rules, all action Delete with `Test_Mode = true`. Retention: Banking_Info deactivated 3 years; Commission Estimated / Written-off 3; Commission exceptions resolved 3; Commission Paid 7; import logs 7; payment batches 7 |
| Custom settings | `Retention_Export_Tracker__c` (last export date), `In_App_Checklist_Settings__c` |
| Global value sets | `Line_of_Business` (Medicare, ACA, Life, Supplementary, Annuities, Health), `Medicare_Carriers` (8), `States` (57) |
| Custom labels | 6: NIPR / PDB URLs and NIPR credentials. The labels file is excluded from Git ([CON-002](../2026-10/05-Conflicts/CON-002_NIPR-Credential-Stored-In-Custom-Labels.md)) |

## Sensitive data held (for access reviews)
- SSN fields on Contact and `DOI__c`.
- Bank routing and account numbers on Contact and `Banking_Info__c`.
- A `View_Encrypted_Data` permission set and a `ContactEncryptedFieldTrigger` exist. NOT YET VERIFIED: whether the fields use Shield or Classic encryption.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from analysis of the baseline retrieval. |
