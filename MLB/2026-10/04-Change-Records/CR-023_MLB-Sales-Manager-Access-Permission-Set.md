# CR-023 — Permission set "MLB Sales Manager Access"

| | |
|---|---|
| **Change ID** | CR-023 |
| **Date** | 2026-10-09 |
| **Requirement** | [REQ-012](../03-Requirements/REQ-012_Sales-Managers-Role-Access.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | 0AfiV0000008eumSAA (created) · 0AfiV0000008hB3SAI (app access added; see CR-024) |
| **Local file** | `force-app/main/default/permissionsets/MLB_Sales_Manager_Access.permissionset-meta.xml` |

## What changed
| Component | Type | Action |
|---|---|---|
| `MLB_Sales_Manager_Access` | Permission set | **Created**. Grants: app `Marlins_Sales` visible; record types `Contact.Business_Contact`, `Contact.Internal`, `Contact.Vendor_Contact` visible; user permission `RunFlow`. |
| Permission set assignments | Data (anonymous Apex) | Assigned to all **18** users with role `Sales_Managers` (11 active, 7 inactive) |

## Why a permission set (not profile edits)
The Marlins Sales Leadership and President profiles are shared. A permission set adds exactly what's needed and is easy to remove.

## Verification
Check-only test running as Sonja Colon and Caroline O'Connor: 3 record types available (default Business Contact), Run Flows true, Agreement Status readable, COI not editable.

## Rollback
Delete the assignments, or the permission set. Users go back to Business Contact only and no Run Flows.
