# CR-028 — Edit Agreement flow and button

| | |
|---|---|
| **Change ID** | CR-028 |
| **Date** | 2026-10-15 |
| **Requirement** | [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | 0AfiV0000009jKVSAY (flow v1) · 0AfiV0000009k6rSAA (quick action and page) · 0AfiV0000009k6sSAA (v2, rows updated in place) |
| **Status** | Superseded on 2026-10-21 by [CR-031](CR-031_Combined-Agreement-Flow.md): the flow was merged into Agreement_Flow and deleted |

## What changed
| Component | Type | Action |
|---|---|---|
| `Edit_Agreement_Flow` | Screen flow | Created (v1 to v4), built from Agreement_Flow with every screen prefilled. **Deleted 2026-10-21.** |
| `Opportunity.Edit_Agreement` | Quick action (flow) | Created. Now opens `Agreement_Flow` (CR-031). |
| `Ticketing_Opportunity_LRP` | Record page | Edit Agreement action added, visible when Agreement Type is Membership, Multi-Product, Flex or Suite Lease. |

## History
- v1 replaced Membership rows (create new, delete old). The user asked for rows to be **updated**, so v2 updates rows in place with `Flow_Update__c` ticked (CR-027).
- v3 flipped the Opportunity checkbox (CR-029); v4 saved the Opportunity before the rows (CR-030).

## Rollback
Not applicable; the flow no longer exists. Remove the quick action from the page to hide the button.
