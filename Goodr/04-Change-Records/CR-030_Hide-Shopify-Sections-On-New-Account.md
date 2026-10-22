# CR-030 — Hide the Shopify sections on the New Account form

| | |
|---|---|
| **Change ID** | CR-030 |
| **Date** | 2026-10-21 |
| **Requirement** | [REQ-037](../03-Requirements/REQ-037_Hide-Shopify-Sections-On-New-Account.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GQ5xJCAT` (19 of 19 components; check-only `0Afdx00000GQ5vhCAD`) |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `Account.Is_Saved_Record__c` | Field (new) | Formula checkbox `NOT(ISBLANK(Id))`, label "Is Saved Record". Not placed on any page layout or record page |
| 16 profiles that can read Accounts | Field access | Read only on Is Saved Record. Nothing else in the profiles changed |
| `Account_Company_Record_Page` | Lightning page | Section filter **Is Saved Record = True** on "Shopify Offboarding" and "Shopify Sales Performance" |
| `Account_Store_Location_Record_Page1` | Lightning page | Same two section filters |

All 46 record pages in the sandbox were checked: only these two pages hold the two sections.

## Pre-check
Both pages were retrieved and compared with the repository before editing: identical. The other session's changes on the same pages (REQ-035, REQ-036) are kept.

## Verification
- Is Saved Record is true on all 8,431 saved Company and Store Location Accounts.
- Full test run: [ATR-003](../08-QA/01-Automated-Testing/ATR-003_Hide-Shopify-Sections-And-BI-V1-Fields.md).

## Rollback
Remove the two section filters on both pages and save, then delete the field.
