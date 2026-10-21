# CR-034 — User Sales Manager checkbox and Contact Create Agreement list

| | |
|---|---|
| **Change ID** | CR-034 |
| **Date** | 2026-10-21 |
| **Requirement** | [REQ-017](../03-Requirements/REQ-017_User-Sales-Manager-Checkbox.md) |
| **Org** | utdev sandbox |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `User.Sales_Manager__c` | Checkbox | Created. Edit: Admin; read: Ticket Sales, Marlins Sales Leadership (partial profiles). |
| `Vendor_Activation_Food_and_Beverage_Agreement` | Screen flow | `SalesManagerChoiceSet` filters `Sales_Manager__c = true` and `IsActive = true`; the `Get_Sales_Manager_Role` lookup (UserRole named "Sales Manager") removed and Get_Account connected straight to the Agreement Information screen. Edited on the current org version. |
| Users Billy Marlin, Ruben Smith | Data | Sales Manager ticked. |

## Verification
Dropdown showed Ruben Smith and Billy Marlin; with Ruben unticked it showed Billy Marlin only; Ruben ticked again. See ATR-002 TC-017-01 to 03.

## Rollback
Restore the flow's previous version (role-based list). The field can stay.
