# REQ-012 — Sales Managers role: Contact record types, Marlins Sales page and Adobe Sign access

| | |
|---|---|
| **ID** | REQ-012 |
| **Status** | ✅ Done in sandbox (utdev); confirmed by the user 2026-10-09 ("all good") |
| **Requested** | 2026-10-09 |
| **Related** | CR-023 · CR-024 · CR-025 · CON-014 · TECH-007 |

## Business need
Users in the **Sales Managers** role (for example Sonja Colon) must be able to run the full Contact and agreement process in the **Marlins Sales** app, the same way it works in the Sales app.

## Problems reported and requests made
| # | Reported | Request |
|---|---|---|
| 1 | New Contact opened Business Contact directly | Show all 3 record types; give access to all Sales Managers role users, plus everything we built |
| 2 | Users work in **Marlins Sales**, not Sales | Same Contact page as the Sales app; add the app to the permission |
| 3 | Agreements related list not showing | Fix |
| 4 | Send Agreement: "Insufficient Privileges" | Fix |
| 5 | Send Agreement: "Permission denied. Unable to query field adobesign__DocumentId__c in object: adobesign__Document__c" | Fix |
| 6 | Same permissions for **all** Sales Managers role users, active and inactive | Apply to all 18 |

## Functional behaviour (as delivered)
- **New Contact:** a record-type chooser with Business Contact, Internal and Vendor Contact. Business Contact is the default.
- **Flows:** Upload Certificate, Create Agreement and the Agreement Flow run for these users.
- **Marlins Sales app:** shows the same Contact page as Sales (`Contact_Record_Page_Three_Column`): certificate banner, vendor buttons, Vendor Information.
- **Agreements:** the related list shows; Send Agreement opens Adobe and the Document Builder works.

## Scope
- **In:** all **18** users with role `Sales_Managers` (11 active, 7 inactive).
- **Out:** unrelated permission sets (Chatter for Ticket Sales, ZoomInfo, Einstein Activity Capture, Conversica), which may use paid licences. Profiles were **not** edited.

## Acceptance criteria (verified as Sonja and Caroline, check-only)
1. Three Contact record types available; default Business Contact.
2. Run Flows: yes.
3. Adobe Send page access and Agreement field access (including the Contact lookup): yes.
4. Certificate checkboxes still **not** editable.
5. All 18 role users hold the four permission sets (checked user by user).

## Open questions
- Sonja Colon has **no Manager** on her user record; who should it be?
- Billy Marlin's manager, Ruben Smith, still has a `.invalid` email ([KB-005](../02-Knowledge-Base/KB-005_Sandbox-User-Status.md)).

## Update 2026-10-23: sales reps
At the client's request the same access was given to four Sales Reps (Ticket Sales profile): Antonio Diz, Chema Sanchez, Isaac Paladino, Keeley Himmelreich. They now hold MLB Sales Manager Access as well as the three Adobe Sign sets. See [CR-037](../04-Change-Records/CR-037_Sales-Manager-Ticks-And-Sales-User-Access.md).
