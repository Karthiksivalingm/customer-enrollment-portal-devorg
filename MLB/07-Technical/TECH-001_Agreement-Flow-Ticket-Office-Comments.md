# TECH-001 — Agreement Flow: Ticket Office Comments

| | |
|---|---|
| **ID** | TECH-001 |
| **Requirement** | [REQ-001](../03-Requirements/REQ-001_Ticket-Office-Comments-Field.md) |
| **Source** | `force-app/main/default/flows/Agreement_Flow.flow-meta.xml` |

## Design
| Screen | New screen field (LargeTextArea) | Saved by assignment |
|---|---|---|
| Flex_Agreement | `Ticket_Office_Comments_Flex` | `Assign_Flex_To_Opportunity` |
| Membership_Terms | `Ticket_Office_Comments_Membership` | `Assign_Membership_To_Opportunity` |
| Multi_Product_Agreement | `Ticket_Office_Comments_MultiProduct` | `Assign_MultiProduct_To_Opportunity` |
| Suite_Lease_Agreement | `Ticket_Office_Comments_SuiteLease` | `Assign_Suite_To_Opportunity` |

- Each field: default value `Get_opportunity.Ticket_Office_Comments__c`, not required, full width, placed after the Entity Name section.
- Each assignment adds `Get_opportunity.Ticket_Office_Comments__c ← <screen field>`, just before the existing `Update_*_Opportunity` record update.
- Screen field names must be unique within a flow, hence one per screen.

## What was deliberately left alone
Every other element, decision, formula and connector in the flow.
