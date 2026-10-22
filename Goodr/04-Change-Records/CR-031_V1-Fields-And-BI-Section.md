# CR-031 — Sales Channel V1 and Sector V1 on Contact, Lead and Opportunity; BI section

| | |
|---|---|
| **Change ID** | CR-031 |
| **Date** | 2026-10-22 |
| **Requirement** | [REQ-038](../03-Requirements/REQ-038_V1-Fields-And-BI-Section.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GRH6nCAH` (15 of 15 components; check-only `0Afdx00000GRH1xCAH`) |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `Contact`, `Lead`, `Opportunity` `.Sales_Channel_V1__c` and `.Sector_V1__c` | Fields (6 new) | Exact copy of the Account fields: Text 50, same label, description and help text |
| System Administrator, Account Management | Field access | Admin read and edit; Account Management read only (same as Account) |
| `Account_Company_Record_Page`, `Account_Franchise_Record_Page1`, `Account_Store_Location_Record_Page1` | Lightning pages | New **BI** section after Account Information with the two V1 fields; the fields were removed from Account Information |
| `Contact_Record_Page`, `Lead_Record_Page`, `Opportunity_Record_Page_Three_Column`, `Opportunity_Record_Page_Updated` | Lightning pages | New **BI** section after the main information section with the two V1 fields |

## Pre-check
The seven pages were retrieved before editing. Differences from the repository were only the CR-030 filters (not yet committed) and tab labels Salesforce drops; the org versions were used.

## Verification
- Fields and access confirmed by query (6 of 6 fields for both profiles).
- Each page has one BI section and each V1 field once.
- Full test run: [ATR-003](../08-QA/01-Automated-Testing/ATR-003_Hide-Shopify-Sections-And-BI-V1-Fields.md).

## Rollback
Redeploy the previous versions of the seven pages from git history, then delete the six new fields (they hold no data).
