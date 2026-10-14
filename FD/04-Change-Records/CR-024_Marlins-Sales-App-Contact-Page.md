# CR-024 — Marlins Sales app: same Contact record page as the Sales app

| | |
|---|---|
| **Change ID** | CR-024 |
| **Date** | 2026-10-09 |
| **Requirement** | [REQ-012](../03-Requirements/REQ-012_Sales-Managers-Role-Access.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000008hB3SAI |
| **Local file** | `force-app/main/default/applications/Marlins_Sales.app-meta.xml` |

## What changed
| Component | Type | Action |
|---|---|---|
| `Marlins_Sales` (console app) | CustomApplication | Added app-level action override: Contact **View** → FlexiPage `Contact_Record_Page_Three_Column`, form factor Large. Copied from the Sales app (`standard__LightningSales`). |
| `MLB_Sales_Manager_Access` | Permission set | Added application visibility `Marlins_Sales` |

## Before / after
| | Before | After |
|---|---|---|
| Contact page in Marlins Sales | none set: org default `Contact_Record_Page2` (no banner, buttons or Vendor Information) | `Contact_Record_Page_Three_Column` |

## Not changed (already correct)
Contact page layout assignments for Marlins Sales Leadership and President match System Administrator: Contact Layout (default), Internal → Contact-Internal, Vendor Contact → Contact-Vendor.

## Verification
The app and permission set were retrieved back from the org: override present; app visibility true.

## Rollback
Remove the Contact override from the Marlins Sales app and redeploy.
