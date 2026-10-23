# TECH-003 — Ticket Office email: field mapping per agreement type (final)

| | |
|---|---|
| **ID** | TECH-003 |
| **Requirements** | [REQ-002](../03-Requirements/REQ-002_Ticket-Office-Notification-Email.md) · [REQ-004](../03-Requirements/REQ-004_Ticket-Office-Email-Design-And-Content.md) |
| **Last verified** | 2026-10-07 (rendered from the sandbox) |

## Common to all types
| Shown as | Object.Field |
|---|---|
| Subject `{Type} Details \|\| {ProVenue}` | `Opportunity.Agreement_Type__c`, `Opportunity.ProVenue_ID__c` (falls back to `Account.ProVenue_ID__c`) |
| Reply-to | `Opportunity.Owner.Email` |
| Header type and ProVenue chip | `Agreement_Type__c`, ProVenue as above |
| Agreement Update | `echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c` of the latest agreement |
| Ticket Office comments ("from …") | `Opportunity.Ticket_Office_Comments__c`, `Opportunity.Owner.Name` |
| Customer name | `Account.Name` |
| Customer address | `Account.BillingStreet/City/State/PostalCode`, falling back to `Account.PersonMailingStreet/City/State/PostalCode`, else "Address not provided" |
| ProVenue ID | as above |
| Button | `Opportunity.Id` |
| Footer | `Opportunity.Owner.Name`, `Owner.Title` (default "Sales Representative"), `Owner.Email` |

## Agreement Summary
| Type | Columns |
|---|---|
| Membership | **Agreement Value** `Total_MembershipPrice__c` · Payment Plan `Payment_Type__c` · Seats = Σ `Membership_Agreement__c.Qty_Seats__c` (rows with Plan Type) · Parking = Σ `Qty_Parking__c` (rows with Parking Plan Type) |
| Suite Lease | **Agreement Value** `This_Season_Total_Amount__c` · Suite `#Suite_Number__c` · Tickets `Total_Tickets_in_Suite__c` · Games `Total_of_Games__c` |
| Multi-Product | **Agreement Value** `Total_Multi_Product__c` · Flex `Amount_allocated_to_Flex__c` · Suites `Amount_allocated_to_Suites__c` · Groups `Amount_allocated_to_Groups__c` |
| Flex | **Agreement Value** `Total_Flex_Membership__c` · Payment Plan `Payment_Plan__c` |

## Type-specific sections
**Membership: Seats & Parking** (one card per `Opportunity.Membership_Agreements__r` row, via `Opportunity_LUR__c`)

| Card | Fields |
|---|---|
| Seat (when `Plan_Type__c` set) | `Location_Section__c`, `Location_Row__c`, `Location_Seat__c`, `Plan_Type__c`, `Qty_Seats__c`, `Order_ID__c`, `Total_Seat_Price__c` |
| Parking (when `Plan_Type_Parking__c` set) | `Location_Parking__c`, `Plan_Type_Parking__c`, `Qty_Parking__c`, `Order_ID_Parking__c`, `Total_Parking_Price__c` |

**Suite Lease: Suite card**: `Suite_Number__c`, `Suite_Location__c`, `Suite_Level__c`, `Total_Tickets_in_Suite__c`, `Total_of_Games__c`.

## Not shown (removed by the client)
- Order # for Suite Lease, Multi-Product and Flex. Membership shows Order # on each seat or parking card.
- Payment Plan for Suite Lease and Multi-Product.
