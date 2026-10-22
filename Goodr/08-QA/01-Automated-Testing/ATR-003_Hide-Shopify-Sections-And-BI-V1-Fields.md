# ATR-003 — Hide the Shopify sections on create; V1 fields and BI section

| | |
|---|---|
| **Report ID** | ATR-003 |
| **Requirements** | [REQ-037](../../03-Requirements/REQ-037_Hide-Shopify-Sections-On-New-Account.md) · [REQ-038](../../03-Requirements/REQ-038_V1-Fields-And-BI-Section.md) |
| **Change records** | [CR-030](../../04-Change-Records/CR-030_Hide-Shopify-Sections-On-New-Account.md) · [CR-031](../../04-Change-Records/CR-031_V1-Fields-And-BI-Section.md) |
| **Manual test cases** | [MTC-004](../02-Manual-Testing/MTC-004_Hide-Shopify-Sections-And-BI-V1-Fields.md) |
| **Org** | Sandbox (GDRSAND) |
| **Run date** | 2026-10-22 |
| **Run as** | System Administrator (Ruben Smith); Account Management, Standard User and System Administrator test users inside the Apex tests |
| **Result** | **28 of 28 scenarios passed** |

## 1. Scope
| Component | Type | Version tested |
|---|---|---|
| `Account.Is_Saved_Record__c` | Field (formula checkbox) | CR-030 |
| `Contact` / `Lead` / `Opportunity` `.Sales_Channel_V1__c`, `.Sector_V1__c` | Fields | CR-031 |
| 16 profiles (Is Saved Record); System Administrator, Account Management (V1) | Field access | CR-030, CR-031 |
| `Account_Company_Record_Page`, `Account_Store_Location_Record_Page1` | Lightning pages (section filters + BI) | CR-030, CR-031 |
| `Account_Franchise_Record_Page1`, `Contact_Record_Page`, `Lead_Record_Page`, `Opportunity_Record_Page_Three_Column`, `Opportunity_Record_Page_Updated` | Lightning pages (BI) | CR-031 |

## 2. How the tests were run
- **Apex:** test class [ATR-003_SavedRecordAndV1QaTest.cls](ATR-003_SavedRecordAndV1QaTest.cls), 13 tests with real assertions, run as a **validate-only deployment** (`sf project deploy validate -l RunSpecifiedTests`), so nothing was saved in the org. It covers positive, negative, bulk (200 records) and other-profile cases.
- **Configuration and access:** SOQL on Account, FieldPermissions and FieldDefinition; retrieve of the 7 record pages and the 6 Account page layouts.
- **Screens:** the real New Account forms and record pages opened in Chrome (headless) on test records, closed without saving. Screenshots are in [MTC-004](../02-Manual-Testing/MTC-004_Hide-Shopify-Sections-And-BI-V1-Fields.md).

## 3. Scenario results
| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-037-01 | Is Saved Record is a read-only formula checkbox | Apex | Admin | Field describe | Checkbox, formula `NOT(ISBLANK(Id))`, not editable | As expected | Pass |
| TC-037-02 | Unsaved Company and Store Location | Apex | Admin | `Formula.recalculateFormulas` on new records | False (sections hidden) | False on both | Pass |
| TC-037-03 | Saved Company and Store Location | Apex | Admin | Insert Company, then Store | True (sections shown) | True on both | Pass |
| TC-037-04 | Bulk unsaved records | Apex | Admin | 200 new Accounts | All false | 0 of 200 true | Pass |
| TC-037-05 | Account Management can read, not edit | Apex | Account Management | Field describe | Readable, not editable | As expected | Pass |
| TC-037-06 | Standard User can read | Apex | Standard User | Field describe | Readable | Readable | Pass |
| TC-037-07 | All saved Accounts are true | SOQL | Admin | Company + Store Location Accounts | 8,431 of 8,431 true | 8,431 of 8,431 | Pass |
| TC-037-08 | Read-only access for all Account profiles | SOQL | Admin | FieldPermissions | 16 profiles, read, no edit | 16, read, no edit | Pass |
| TC-037-09 | Not visible on any layout or page | Retrieve | Admin | 6 Account layouts, 7 pages | Not placed anywhere | 0 layouts, 0 pages | Pass |
| TC-037-10 | Filter on the sections | Retrieve | Admin | Company and Store Location pages | Both sections filtered on Is Saved Record = True | 2 + 2 filters | Pass |
| TC-037-11 | New Company form | UI | Admin | Accounts → New → Company | Neither Shopify section | Not shown (Account Information, BI, Fulfillment, Address, System) | Pass |
| TC-037-12 | New Store Location form | UI | Admin | Accounts → New → Store Location | Neither Shopify section | Not shown | Pass |
| TC-037-13 | Existing Company | UI | Admin | R12 Test Company Sandbox | Both sections shown | Shown with values | Pass |
| TC-037-14 | Existing Store Location | UI | Admin | R12 WOT Demo Store YTD | Both sections shown | Shown with values | Pass |
| TC-038-01 | Six new fields match Account | Apex | Admin | Describe on Contact, Lead, Opportunity | Text 50, same label and help text | As expected on 6 of 6 | Pass |
| TC-038-02 | Admin can edit | Apex | System Administrator | Describe on all 8 V1 fields | Read and edit | Read and edit | Pass |
| TC-038-03 | Account Management read only | Apex | Account Management | Describe on all 8 V1 fields | Read, no edit | Read, no edit | Pass |
| TC-038-04 | Values save and read back | Apex | Admin | Contact, Lead, Opportunity with V1 values | Saved as entered | Saved as entered | Pass |
| TC-038-05 | Length limit | Apex | Admin | 51 characters | Rejected | Rejected | Pass |
| TC-038-06 | Bulk Contacts | Apex | Admin | 200 Contacts with V1 values | 200 saved | 200 saved | Pass |
| TC-038-07 | No impact on existing logic | Apex | Admin | Account with and without V1 values | Same Sales Channel and Cluster | Same | Pass |
| TC-038-08 | Access on the new fields | SOQL | Admin | FieldPermissions | Admin read/edit, Account Management read on 6 of 6 | As expected | Pass |
| TC-038-09 | BI section on every page in use | Retrieve | Admin | 7 pages | One BI section with both fields | 7 of 7 | Pass |
| TC-038-10 | Account V1 fields moved, not duplicated | Retrieve | Admin | 3 Account pages | Each V1 field once, in BI | Once each | Pass |
| TC-038-11 | Account BI on screen | UI | Admin | R12 Test Company Sandbox | BI with values | "Specialty / Self Service" | Pass |
| TC-038-12 | Contact BI on screen | UI | Admin | Test Canada QA 1 | BI after Contact Information | Shown, empty | Pass |
| TC-038-13 | Lead BI on screen | UI | Admin | Test UT QA | BI after Lead Information | Shown, empty | Pass |
| TC-038-14 | Opportunity BI on screen | UI | Admin | Test Opp Acc | BI after Opportunity Information | Shown, empty | Pass |

## 4. Defects found
None. During the build, five filter options were rejected by Salesforce before Is Saved Record was chosen: see [CON-037](../../05-Conflicts/CON-037_Page-Filters-Cannot-Check-Record-Exists.md).

## 5. Evidence
| Item | Value |
|---|---|
| CR-030 deploy | `0Afdx00000GQ5xJCAT` (check-only `0Afdx00000GQ5vhCAD`) |
| CR-031 deploy | `0Afdx00000GRH6nCAH` (check-only `0Afdx00000GRH1xCAH`) |
| Apex QA test run (validate only) | `0Afdx00000GRdldCAD`: 13 of 13 passed, nothing saved |
| Records shown in screenshots | `001dx00000fzhmnAAA`, `001dx00000qPGOjAAO`, `003dx00000jxMLxAAM`, `00Qdx00000HjS4nEAF`, `006dx00000Jaa5FAAR` (test records, not changed) |

## 6. Test data and cleanup
| Record | Used in | Cleanup |
|---|---|---|
| Accounts, Contacts, Leads, Opportunities, users created inside the Apex tests | TC-037-01 to 06, TC-038-01 to 07 | Rolled back automatically (validate-only run) |
| New Account forms | TC-037-11, 12 | Closed without saving |
| Test records opened on screen | TC-037-13, 14, TC-038-11 to 14 | Viewed only, not changed |
