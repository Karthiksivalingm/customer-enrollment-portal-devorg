# CR-025 — Adobe Sign permission sets assigned to the Sales Managers role

| | |
|---|---|
| **Change ID** | CR-025 |
| **Date** | 2026-10-09 |
| **Requirement** | [REQ-012](../03-Requirements/REQ-012_Sales-Managers-Role-Access.md) |
| **Related** | [CON-014](../05-Conflicts/CON-014_Sales-Manager-Access-Gaps.md) |
| **Org** | utdev sandbox |
| **Method** | Data: PermissionSetAssignment inserts (anonymous Apex). No metadata deploy. |

## What changed
| Managed permission set | Package | Fixes | Newly assigned to |
|---|---|---|---|
| `Adobe_Sign_User` (Adobe Acrobat Sign User) | echosign_dev1 | Agreements related list (field access, Contact lookup); Send page `echosign_dev1__AgreementTemplateProcess` ("Insufficient Privileges") | Sonja Colon, Caroline O'Connor + 7 inactive |
| `Adobe_Access` (Adobe Access) | custom | Matches what the other Sales Managers have | Sonja Colon, Caroline O'Connor + 7 inactive |
| `AdobeSign_ContractBuilder_User` (Acrobat Sign Document Builder User) | adobesign | "Unable to query field adobesign__DocumentId__c in object adobesign__Document__c" | Sonja Colon, Caroline O'Connor + 7 inactive |

The other 9 active Sales Managers already had all three. Both packages' licences are **Free / unlimited (-1)**, so no seats were used.

## Verification
- Check-only test as Sonja and Caroline: Send page access, Agreement and field access true.
- Final check: **18 of 18** role users hold all four permission sets (these three plus `MLB_Sales_Manager_Access`).
- User confirmed: all good.

## Rollback
Delete the PermissionSetAssignment records for the users listed above.
