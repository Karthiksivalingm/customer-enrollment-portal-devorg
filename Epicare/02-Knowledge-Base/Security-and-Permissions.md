# Security and Permissions

Built from retrieved profiles, permission sets, permission set groups, roles, groups, sharing rules and object settings (2026-10-15).
INFERENCE marks interpretation. Full lists: [Permission-Sets](../07-Technical-Documents/Metadata-Inventory/Permission-Sets.md),
[Profiles, groups and sharing](../07-Technical-Documents/Metadata-Inventory/Profiles-Groups-and-Sharing.md).

## Organization-wide defaults
| Setting | Objects |
|---|---|
| Private | Commission_Record, Commission_Exception, Commission_Forecast, Commission_Import_Log, Payment_Batch, Agreement, Referral_Record, Banking_Info, Security_Incident |
| Public Read Only | Contact, Account, Appointment, State_Appointment, Carrier, Product, DOI, License, Upline_Policy, Certification, Onboarding_Checklist, Error_Log |
| Controlled by parent | Product_State, Renewal_Schedule, LOA |
| Public Read/Write | Notes, Premium_Payments, Data_Retention_Log |

External OWD is Private for the custom objects.

## Role hierarchy (5 roles)
```
CEO
 └─ COO                      (INFERENCE: parent CEO; the COO role file has no parent tag)
     ├─ Commissions Director
     │    └─ Broker Support Agent
     └─ Contracting Manager
```

## Sharing rules (4 objects with rules; 25 sharing files are empty)
| Object | Rule type | Shares to | Access |
|---|---|---|---|
| Contact (agents) | 3 criteria-based | COO, Commissions Director, Contracting Manager roles | Read, Read, Edit |
| Agreement__c | Criteria (active agreements) | Role | Read |
| Commission_Record__c | Criteria (Draft) | Role | Read |
| Payment_Batch__c | Owner-based (role → role) | Role | Edit (approval) |

## Profiles (26)
- **Salesforce license, Epicare-specific:** Epicare – Broker Support, Epicare – Commissions, Epicare – Contracting, Epicare – Executive.
- **Standard:** System Administrator, Standard, Contract Manager, Solution Manager, Marketing, Read Only, Minimum Access, End User, Executive Sponsor.
- **Integration:** GO AMS – API User; Epicare – GO AMS Integration; Minimum Access – API Only Integrations; Salesforce API Only System Integrations (Salesforce Integration license).
- **Other licenses:** Analytics Cloud Integration/Security User, CPQ Integration User, Sales Insights Integration User, Chatter users, Guest License User, Identity User.

## Permission sets (24) and groups (6), INFERENCE grouping
| Purpose | Permission sets | Permission set group |
|---|---|---|
| Business roles | Broker_Support_Agent, Commissions_Director (and a second Commissions Director set labelled with a person's name), Contracting_Manager, COO_Executive, Sales_User, Super_Admin | Broker Support, Commission Directors, Contracting Managers, COO/Executives |
| Integration / API | AMS, API_Access, API_User, API_User_Access, GO_AMS_Integration, GoAMS_Event_Integration, Event_Subscriber_Run_As, Automated_User_Permission | GO AMS INTEGRATIONS |
| Credential access | Named_Credentials, NamedCredentialAccess, Named_CredentialsPermission, Grand_External_credential_Access | — |
| Data access | View_Encrypted_Data, Banking_Info_Object_Permission, Field_level_Access, contact, Account_Record_Type_Access | Account Record Type (no members) |

## Controls built into the data model
Segregation-of-duties validation rules:
- `Payment_Batch__c.Approver_not_equal_to_Submitter`
- `Banking_Info__c.Verifier_not_equal_to_Creator_SoD`
- `Commission_Record__c.Lock_Amounts_After_Approval_SoD`

## Risks to review (INFERENCE)
- **Sensitive data:** SSN and bank details on Contact (OWD Public Read Only) depend on field-level security and encryption to stay restricted.
  Review `View_Encrypted_Data` and the field permissions.
- **Credential access sets:** four overlapping permission sets grant named or external credential access.
- **Duplicate role sets:** two Commissions Director permission sets; one has a person-specific label.
- **Credentials in custom labels:** see [CF-002](../05-Conflicts/2026-10-15-CF-002-nipr-credential-stored-in-custom-labels.md).

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the baseline retrieval. |
