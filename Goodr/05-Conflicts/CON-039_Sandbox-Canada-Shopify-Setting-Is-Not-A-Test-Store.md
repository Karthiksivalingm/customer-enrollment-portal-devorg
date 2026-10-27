# CON-039 — The sandbox "Specialty CAN" Shopify setting does not point to a test store

| | |
|---|---|
| **ID** | CON-039 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-27 (safety check before the REQ-040 end-to-end test) |
| **Area** | Shopify integration / sandbox settings |
| **Related** | [REQ-040](../03-Requirements/REQ-040_Offboarding-Removes-Shopify-Ordering-Role.md) · [ATR-005](../08-QA/01-Automated-Testing/ATR-005_Offboarding-Shopify-Role-Removal.md) |

## Risk
The sandbox has two Shopify settings (`Shopify_Configuration__c`):

| Setting | Points to |
|---|---|
| **Specialty** (US) | `sellgoodr-test-store`, a test store |
| **Specialty CAN** | `sellgoodr-canada`, which is **not** a test store |

Any sandbox action on a **Canadian** store therefore reaches that store. This includes creating or activating a store, a manual or automatic deactivation, and the Sales Sync.

## Mitigation
- Test Shopify behaviour in the sandbox with **US** stores only.
- Don't schedule the Shopify Sales Sync in the sandbox. It processes every store, including Canadian ones.
- Decision for the project lead: point "Specialty CAN" to a Canada test store, if one exists.
