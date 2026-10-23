# CR-037 — Sales Manager ticks and access for ten sales users

| | |
|---|---|
| **Change ID** | CR-037 |
| **Date** | 2026-10-23 |
| **Requirements** | [REQ-017](../03-Requirements/REQ-017_User-Sales-Manager-Checkbox.md) · [REQ-012](../03-Requirements/REQ-012_Sales-Managers-Role-Access.md) |
| **Org** | utdev sandbox |
| **Status** | Done in sandbox (data only, no metadata), confirmed by user |

## What changed
| Change | Users |
|---|---|
| `User.Sales_Manager__c` ticked | Samantha MacIntosh, Jason Liss, Pierce Jefferson, Brandon Federico, Nathan Medrano |
| Permission set `MLB_Sales_Manager_Access` assigned | Antonio Diz, Chema Sanchez, Isaac Paladino, Keeley Himmelreich (Ticket Sales profile, Sales Reps role) |

Name spellings in the request: "Sam Macintosh" = Samantha MacIntosh, "Peirce Jefferson" = Pierce Jefferson, "Keely Himmelreich" = Keeley Himmelreich.

## Pre-check (all ten users)
| Needed by our features | Result before the change |
|---|---|
| Marlins Sales app | All 10 had it |
| Run Flows | All 10 |
| Adobe Access, Adobe Acrobat Sign User, Acrobat Sign Document Builder User | All 10 |
| Object access: Opportunity, Contact, Account, Membership Agreement, Adobe Agreement / Recipients / Documents | All 10 |
| Field read on the 50 fields used by our screens, flows and banner | All 10 (ContentVersion.Certificate_Category__c not needed: set by the flow in system mode) |
| MLB_Sales_Manager_Access (all four Contact record types) | 6 Sales Managers had it; the 4 reps did not |

## Verification
- All 10 users hold MLB_Sales_Manager_Access, Adobe_Sign_User, Adobe_Access and AdobeSign_ContractBuilder_User.
- Sales Manager dropdown in the Contact Create Agreement flow: Jason Liss, Samantha MacIntosh, Nathan Medrano, Ruben Smith, Billy Marlin, Brandon Federico, Pierce Jefferson.

## Notes
- Billy Marlin and Ruben Smith are still ticked from the first setup (CON-012 item 15).
- The reps now also see the Internal Contact record type, which comes with the permission set (CON-012 item 16).

## Rollback
Untick the five users; delete the four permission set assignments.
