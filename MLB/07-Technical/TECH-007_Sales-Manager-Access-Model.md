# TECH-007 — Sales Manager access model

| | |
|---|---|
| **ID** | TECH-007 |
| **Requirement** | [REQ-012](../03-Requirements/REQ-012_Sales-Managers-Role-Access.md) |
| **Applies to** | Users with role `Sales_Managers` (profiles Marlins Sales Leadership, President, System Administrator) |

## 1. Required permission sets (all four)
| Permission set | Type | Grants | Needed for |
|---|---|---|---|
| `MLB_Sales_Manager_Access` | Custom (ours) | App `Marlins_Sales`; Contact record types Business_Contact, Internal, Vendor_Contact; `RunFlow` | New Contact chooser; Upload Certificate, Create Agreement, Agreement Flow |
| `Adobe_Sign_User` | Managed (echosign_dev1) | Agreement object and field access; Adobe VF pages and classes, incl. `echosign_dev1__AgreementTemplateProcess` | Agreements related list; Send Agreement |
| `Adobe_Access` | Custom (existing, no description) | Held by every working Sales Manager | Kept consistent with peers |
| `AdobeSign_ContractBuilder_User` | Managed (adobesign) | `adobesign__Document__c` access | Document Builder step of sending |

## 2. What comes from the profile (unchanged)
- Contact read / create / edit.
- Adobe Agreement, Recipients and Template object CRUD.
- Field access: `Agreement_Status__c` (read/edit), certificate checkboxes (read-only), `Opportunity.Ticket_Office_Comments__c` (read/edit).
- Page layouts:
  - default → Contact Layout
  - `Contact.Internal` → Contact-Internal
  - `Contact.Vendor_Contact` → Contact-Vendor
- Default record type: Business Contact.

## 3. App and page
| App | Contact record page (desktop) |
|---|---|
| Sales (`standard__LightningSales`) | `Contact_Record_Page_Three_Column` |
| Marlins Sales (`Marlins_Sales`, console) | `Contact_Record_Page_Three_Column` (app default override, [CR-024](../04-Change-Records/CR-024_Marlins-Sales-App-Contact-Page.md)) |
| Other apps | org default `Contact_Record_Page2` |

## 4. Onboarding a new Sales Manager (runbook)
1. Set role **Sales Managers**, profile **Marlins Sales Leadership**.
2. Assign all four permission sets in §1.
3. Set the user's **Manager** (needed for approvals and manager lookups).
4. Make sure the user's email is valid; Adobe provisions its account from it.
5. The user refreshes and tests: New Contact chooser, then Upload Certificate, then Send Agreement.

## 5. How it was verified
A check-only Apex test using `System.runAs(<user>)` reads record type availability, the `RunFlow` permission (via PermissionSetAssignment), field describe access, and `SetupEntityAccess` for the Adobe page. Nothing is saved.
