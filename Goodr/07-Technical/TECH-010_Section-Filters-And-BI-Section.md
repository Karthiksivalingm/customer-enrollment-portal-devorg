# TECH-010 — Hide-on-create section filters and the BI section

| | |
|---|---|
| **ID** | TECH-010 |
| **Requirements** | [REQ-037](../03-Requirements/REQ-037_Hide-Shopify-Sections-On-New-Account.md) · [REQ-038](../03-Requirements/REQ-038_V1-Fields-And-BI-Section.md) |
| **Source** | `force-app/main/default/flexipages/`, `force-app/main/default/objects/*/fields/` |

## 1. Hide a section while a record is created
| Item | Design |
|---|---|
| Field | `Account.Is_Saved_Record__c`, formula checkbox `NOT(ISBLANK(Id))`. On the New form the record has no Id, so it is false; on every saved record it is true |
| Filter | On the `flexipage:fieldSection` component (the section), not on fields: `{!Record.Is_Saved_Record__c} EQUAL true` |
| Sections | "Shopify Offboarding" and "Shopify Sales Performance" on `Account_Company_Record_Page` and `Account_Store_Location_Record_Page1` |
| Access | Read only for the 16 profiles that can read Accounts; not on any layout or page |
| Why this field | Salesforce page filters can't test date/time, Id or lookup fields for blank ([CON-037](../05-Conflicts/CON-037_Page-Filters-Cannot-Check-Record-Exists.md)) |

## 2. BI section
| Object | Pages | Position |
|---|---|---|
| Account | Company, Franchise, Store Location | After Account Information (the V1 fields moved here) |
| Contact | Contact Record Page | After Contact Information |
| Lead | Lead Record Page | After Lead Information |
| Opportunity | Three Column (default), Updated (GOODR app) | After Opportunity Information |

Each BI section has two columns: **Sales Channel V1** (left) and **Sector V1** (right). Both are Text(50) backup fields, editable by System Administrator, read only for Account Management.

## 3. What was deliberately left alone
Page layouts, the unassigned Lead pages (Global, Key Account, Partnership, Specialty Bridge, Specialty Sellgoodr), lead conversion mapping and all automation.
