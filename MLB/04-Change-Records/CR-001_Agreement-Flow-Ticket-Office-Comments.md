# CR-001 — Agreement Flow: Ticket Office Comments field

| | |
|---|---|
| **Change ID** | CR-001 |
| **Date** | 2026-10-05 |
| **Requirement** | [REQ-001](../03-Requirements/REQ-001_Ticket-Office-Comments-Field.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000007bKdSAI |
| **Status** | Deployed to sandbox |

## What changed
| Component | Type | Action |
|---|---|---|
| `Agreement_Flow` | Flow (screen) | Modified. Added LargeTextArea screen fields `Ticket_Office_Comments_Membership`, `_MultiProduct`, `_Flex` and `_SuiteLease`, each prefilled from `Get_opportunity.Ticket_Office_Comments__c`. Added one assignment item per type in the existing Assign_* elements: `Get_opportunity.Ticket_Office_Comments__c` = screen field. |

**Field used (already existed):** `Opportunity.Ticket_Office_Comments__c` (long text area).

## Pre-check
The deployed flow was retrieved and compared with the local file before editing: identical.

## Verification
The deploy succeeded. The field sits after the Entity Name section on each agreement screen.

## Rollback
Activate the previous `Agreement_Flow` version in Flow Builder, or redeploy the previous file.
