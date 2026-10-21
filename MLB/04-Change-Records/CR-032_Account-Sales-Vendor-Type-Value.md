# CR-032 — Account Sales Vendor record type: "Sales Vendor" removed from Type

| | |
|---|---|
| **Change ID** | CR-032 |
| **Date** | 2026-10-21 |
| **Requirement** | [REQ-015](../03-Requirements/REQ-015_Account-Sales-Vendor-Type-Value.md) |
| **Org** | utdev sandbox |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `Account.Sales_Vendor` | Record type | "Sales Vendor" removed from the Type picklist values available on this record type. |

## Pre-check
Retrieved from the org first. Sales Vendor Accounts by Type: Food and Beverage 3, Non-Profit 2, Sales Activation 1, "Sales Vendor" 0.

## Verification
UI API picklist values for the record type: 13 values, without "Sales Vendor". The Vendor record type still offers it.

## Rollback
Add the value back to the record type.
