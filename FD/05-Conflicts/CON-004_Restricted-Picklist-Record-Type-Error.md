# CON-004 — Status flow broke Internal contact creation (restricted picklist and record type)

| | |
|---|---|
| **ID** | CON-004 |
| **Status** | ✅ Resolved 2026-10-07 ([CR-013](../04-Change-Records/CR-013_Restrict-To-Vendor-Contact-Record-Type.md)) |

## Conflict
- The document-status flow ran for **any** Contact on a vendor-type Account. On an **Internal** contact it set `Agreement_Status__c` = "Document Pending".
- That value is enabled only on the Vendor Contact record type, and the picklist is **restricted**, so the save failed.
- There are **no validation rules** on Contact; this flow was the only cause.

## Resolution
Everything certificate-related (flow, banner, three buttons, Vendor Information section) is filtered to `RecordType.DeveloperName = Vendor_Contact`.

## Lesson
When adding restricted picklist values, check which record types can use them before writing automation that sets them.
