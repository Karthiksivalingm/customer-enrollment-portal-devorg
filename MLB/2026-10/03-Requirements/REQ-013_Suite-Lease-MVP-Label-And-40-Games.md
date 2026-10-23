# REQ-013 — Suite Lease: MVP location label and 40-game option

| | |
|---|---|
| **ID** | REQ-013 |
| **Status** | ✅ Built, deployed to sandbox (utdev) and confirmed working by the user |
| **Requested** | 2026-10-13 |
| **Related** | CR-026 · TECH-008 · CON-015 · REQ-001 |

## Business need
Two small corrections to the Suite Lease screen of the Agreement Flow:
1. The Suite Location option was spelt **MPV**; the suite is called **MVP**.
2. Reps need to sell a **40-game** suite lease. Total # of Games only offered 10, 20, 41 and 81.

## Scope
- **In:** the Suite Location option label and value, and the Total # of Games options, on the Suite Lease screen of `Agreement_Flow`.
- **Out:** every other screen, field and piece of logic in the flow. No change to Opportunity fields: they already held MVP and 40.

## Functional behaviour
- Suite Location shows **MVP** and saves "MVP" to `Opportunity.Suite_Location__c`. The MVP Total Tickets in Suite dropdown (12–20) still appears when MVP is picked.
- Total # of Games offers **10, 20, 40, 41, 81**. Picking 40 saves `Total_of_Games__c` = 40 and `Total_of_Games_in_Words__c` = "Forty (40)".

## Affected objects and processes
`Agreement_Flow` (Suite Lease screen) · `Opportunity.Suite_Location__c` · `Opportunity.Total_of_Games__c` · `Opportunity.Total_of_Games_in_Words__c`

## Acceptance criteria
1. Suite Location lists MVP, not MPV.
2. Choosing MVP saves the Opportunity without error and shows the MVP ticket dropdown.
3. Total # of Games lists 10, 20, 40, 41, 81 in that order.
4. Choosing 40 saves 40 and "Forty (40)" to the Opportunity.

All four were confirmed by the user on 2026-10-13.

## Assumptions
- The request said "10, 20, 41, 82"; the flow and the Opportunity picklist use **81**. 81 was kept unchanged.

## Open questions
None.
