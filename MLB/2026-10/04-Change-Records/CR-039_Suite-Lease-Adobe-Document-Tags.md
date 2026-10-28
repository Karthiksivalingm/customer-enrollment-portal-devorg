# CR-039 — Payment schedule and Account Type tags on the Suite Lease Adobe templates

| | |
|---|---|
| **Change ID** | CR-039 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-019](../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | None: Adobe Sign configuration data (`adobesign__Object_Field_Mapping_Entry__c`) |
| **Status** | Done in sandbox, confirmed by user |

## What changed
"Add Salesforce Fields" entries on both Suite Lease document templates:

| Template | Document template | Field mapping |
|---|---|---|
| Suite Lease Agreement <50k | DCT-16 (a2HiV0000000Qc1UAE) | a2KiV000000Vg4bUAC |
| Suite Lease Agreement Template >50k | DCT-22 (a2HiV0000000UAzUAM) | a2KiV000000Z9YHUA0 |

Final entries on each template (15):

| Index | Tag |
|---|---|
| 22 | `{{Opportunity.Number_of_Payment_Plans__c}}` |
| 23, 25, 27 … 45 | `{{Opportunity.Payment_Due_Date_1__c}}` … `{{Opportunity.Payment_Due_Date_12__c}}` |
| 24 | `{{Opportunity.Payment_Amount__c}}` |
| 47 | `{{Opportunity.Account.Type}}` |

### History
| Step | Change |
|---|---|
| CR-038 build | 25 entries added per template (schedule, 12 dates, 12 amounts) plus Account Type. |
| CR-041 | Payment 1 Amount entry changed to `Payment_Amount__c`; the 11 entries for amounts 2–12 deleted (22 in total). Backup taken first. |
| CR-042 | Date entries pointed to temporary "Formatted" fields, then back to `Payment_Due_Date_N__c` once those became text fields. Backup taken first. |

## Verification
Query: 15 schedule/type entries on each mapping (ATR-003 TC-019-15).

## Not done here
The tags still have to be placed inside the two Word documents in Adobe, and one agreement generated as a test (CON-021).

## Rollback
Delete the entries with index 22–47 on both mappings.

## Production steps (not deployable)
Add the same 15 entries to both Suite Lease document templates in production after the fields are deployed.
