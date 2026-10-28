# CR-042 — Payment due dates stored as "November 2, 2026"

| | |
|---|---|
| **Change ID** | CR-042 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | `0AfiV000000BxHjSAK` (12 "Formatted" formula fields, later removed) · `0AfiV000000ByIbSAK` (temporary flow v74, rule, page and layout without the date fields) · `0AfiV000000ByKDSA0` (24 fields deleted and purged) · `0AfiV000000BwVMSA0` (12 text fields recreated; Agreement_Flow **v75**; rule; page; layout; profiles). Rejected validate: `0AfiV000000BvB5SAK` ("Cannot change type due to existing data") |
| **Status** | Deployed to sandbox, confirmed by user |

## Why it was rebuilt
The user wanted the dates in the format "November 2, 2026" and no extra fields: "keep same API name". Salesforce does not let a Date field be changed to Text through deployment. So the fields were deleted, purged and recreated as text with the same API names (CON-019). The user agreed to lose the existing values: Opportunity 006iV000000PlTgQAK had dates in Payment 1 and 2.

## What changed
| Component | Type | Action |
|---|---|---|
| `Opportunity.Payment_Due_Date_1__c` … `_12__c` | Text(30) | **Recreated** (were Date). Hold "Month D, YYYY". |
| `Opportunity.Payment_Due_Date_1_Formatted__c` … `_12_` | Formula (text) | Created, then **deleted and purged** the same day (replaced by the above). |
| `Agreement_Flow` | Flow (v75) | `frmPayDueNText` (date → "November 2, 2026") saved to `Payment_Due_Date_N__c`; `frmExistingDueN` turns the saved text back into a date for Edit Agreement; confirmation shows `frmPayDue1Text`. `Due_Date__c` stays a date. |
| `Agreement_Sections_Flow_Only`, `Ticketing_Opportunity_LRP`, `Opportunity-Opportunity Layout` | Rule, page, layout | Date fields removed (temporary) and added back. |
| 4 profiles | Profiles (partial) | Read and edit on the recreated fields; read on the temporary formula fields (gone with them). |
| Agreement_Flow v73 and v74 | Flow versions (inactive) | **Deleted** (v73 still used the Date fields; v74 was the temporary version). |
| Adobe entries | Data | See CR-039. |

## Verification
Validate-only `0AfiV000000ByP3SAK` (7 of 7). End-to-end screen save on 2026-10-28 stored "November 2, 2026", "December 2, 2026", "January 2, 2027", and Edit Agreement brought them back: ATR-003 TC-019-12 and TC-019-13.

## Rollback
Delete the text fields with purge, recreate them as Date, and redeploy the v73 flow from git history. The data would need re-entering.

## Production note
In production, create the fields as **text from the start** (no Date version exists there), so none of this rebuild is needed.
