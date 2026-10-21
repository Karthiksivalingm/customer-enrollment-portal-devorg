# CON-018 — Contact page visibility filters at the 10-condition limit

| | |
|---|---|
| **ID** | CON-018 |
| **Status** | ℹ Known, worked around ([CR-033](../04-Change-Records/CR-033_Contact-Sales-Vendor-Record-Type.md)) |
| **Found** | 2026-10-21 |
| **Related** | [REQ-016](../03-Requirements/REQ-016_Contact-Sales-Vendor-Record-Type.md) |

## Problem
Adding the Sales Vendor record type to the Contact page filters needed one more condition, but the Create Agreement filter already uses the platform maximum of 10 conditions.

## Workaround
Every filter's record type condition is now **RecordType DeveloperName contains "Vendor"** (matches Vendor_Contact and Sales_Vendor) instead of equals "Vendor_Contact". The condition count is unchanged.

## Risk
Any future Contact record type whose API name contains "Vendor" also gets the vendor buttons and banner. Name new record types accordingly, or move the rule into a formula field if that becomes a problem.
