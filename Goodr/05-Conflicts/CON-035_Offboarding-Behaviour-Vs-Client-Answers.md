# CON-035 — Offboarding behaviour vs the client's answers (parked)

| | |
|---|---|
| **ID** | CON-035 |
| **Status** | ⚠ Open (parked by the project lead on 2026-10-21; existing automation left as it is). Gap 6 fixed and gap 5 no longer affects automatic offboarding ([CR-035](../04-Change-Records/CR-035_Offboarding-Batch-Removes-Shopify-Ordering-Role.md), 2026-10-27) |
| **Found** | 2026-10-21 (code review and read-only checks in the sandbox) |
| **Area** | Offboarding / Shopify integration |
| **Related** | [REQ-035](../03-Requirements/REQ-035_Auto-Offboarding-Exclusion.md) (client answers) · [KB-002](../02-Knowledge-Base/Business-Process.md) |

## Gaps found
| # | Client answer | What the sandbox does today |
|---|---|---|
| 1 | Stores offboarded earlier keep their original reasons | The flow *Account – Auto-Populate Offboarding Date and User* copies the Company's Reason and Notes to **every** child store, including stores already offboarded |
| 2 | Re-ticking Active re-enables **that** account | Reactivating one store rolls the Company up to active. The Company update then cascades Active to **all** its inactive stores, and their Shopify ordering roles are pushed. Found by reading the code (`AccountTriggerHelper.updateCompanyActiveStatus` / `syncChildLocationsActiveStatus`); not run in the sandbox |
| 3 | Reactivating a Company | Reactivates every store under it, including stores closed for other reasons |
| 4 | Data kept on reactivation | Kept. On a later re-offboarding the old Reason and Notes are still filled, so the validation rule `Require_Offboarding_Reason_And_Notes` passes without new input. Only `Active__c` has field history |
| 5 | Offboarding is done only in Salesforce | The Shopify Sales Sync (scheduled every 12 hours where the process is live, and the "Sync to Shopify" button) overwrites `Active__c` from Shopify role assignments. **2026-10-27:** with gap 6 fixed, a store deactivated by the batch has no role left, so the sync keeps it inactive (ATR-005, TC-040-07). The sync itself is unchanged. |
| 6 | Offboarding is done only in Salesforce | Stores deactivated by the warm-off batch were not pushed to Shopify: `AccountTriggerHandler` skips the push when `System.isBatch()`. **Fixed 2026-10-27:** the batch now removes their ordering role through the existing push ([REQ-040](../03-Requirements/REQ-040_Offboarding-Removes-Shopify-Ordering-Role.md), [CR-035](../04-Change-Records/CR-035_Offboarding-Batch-Removes-Shopify-Ordering-Role.md)). |

## Other notes
- In the sandbox, version 1 of the flow *Account – Auto-Populate Offboarding Date and User* is active. TECH-004 lists it as Obsolete.

## Resolution
Parked. To be raised with the client and handled as a separate requirement when the project lead decides.
