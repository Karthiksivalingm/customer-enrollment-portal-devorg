# CON-026 — Lead_From_US_Retailer_Form_Assignment_And_Email is after-save with no

| | |
|---|---|
| **ID** | CON-026 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-12 |
| **Where** | Flow |

## Risk
`Lead_From_US_Retailer_Form_Assignment_And_Email` is after-save with no fault path, so any failure rolls back the Lead insert from Typeform

## Mitigation
Add a fault path before making further changes
