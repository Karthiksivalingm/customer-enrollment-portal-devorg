# ATR-004 — Lead validation rule: Sales Channel and Sector required to qualify

| | |
|---|---|
| **Report ID** | ATR-004 |
| **Requirement** | [REQ-039](../../03-Requirements/REQ-039_Sales-Channel-Sector-Required-To-Qualify-Lead.md) |
| **Change record** | [CR-033](../../04-Change-Records/CR-033_Lead-Qualify-Validation-Rule.md) |
| **Manual test cases** | [MTC-005](../02-Manual-Testing/MTC-005_Lead-Qualify-Validation-Rule.md) |
| **Org** | Sandbox (GDRSAND) |
| **Run date** | 2026-10-27 |
| **Run as** | System Administrator; Standard User test user inside the Apex test |
| **Result** | **15 of 15 scenarios passed**; regression **110 of 110** tests passed; on screen **8 of 8** passed |

## 1. Scope
| Component | Type | Version tested |
|---|---|---|
| `Lead.Require_Sales_Channel_Sector_To_Qualify` | Validation rule | CR-033 |
| `LeadConversionServiceTest` | Apex test class (test data fix) | CR-033 |
| `LeadManualApproveController` (Approve / Reject), `LeadConversionService.canConvert` (Create Shopify) | Existing Apex, called by the tests | unchanged |

## 2. How the tests were run
- **Apex:** test class [ATR-004_LeadQualifyRuleQaTest.cls](ATR-004_LeadQualifyRuleQaTest.cls), 15 tests with real assertions, run as a **validate-only deployment** (`sf project deploy validate -l RunSpecifiedTests`), so nothing was saved in the org. Each test Lead passes the existing checks (early stages trigger, Tax ID format, rejection email flow), so only the new rule decides the result.
- **On screen:** headless Chrome on a test Lead, clicking the real buttons (Lead Status edit, Approve, Create Shopify). Screenshots in [MTC-005](../02-Manual-Testing/MTC-005_Lead-Qualify-Validation-Rule.md).
- **Regression:** the 15 existing test classes that work with Leads, run without the rule (baseline) and with the final rule. See [CR-033](../../04-Change-Records/CR-033_Lead-Qualify-Validation-Rule.md#impact-on-other-classes).

## 3. Scenario results
| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-039-01 | Sector blank → Qualified | Apex | Admin | Sales Channel Specialty, Sector blank | Blocked with the rule message; Status stays New | As expected | Pass |
| TC-039-02 | Both blank → Qualified | Apex | Admin | Both blank | Blocked with the rule message | As expected | Pass |
| TC-039-03 | Both filled → Qualified | Apex | Admin | Specialty / Self Service | Saved as Qualified | As expected | Pass |
| TC-039-04 | Fill after the error, then retry | Apex | Admin | Blank, then Specialty / Self Service | First try blocked, second saved | As expected | Pass |
| TC-039-05 | Create a Lead with blanks | Apex | Admin | New Lead, Status New | Saved | Saved | Pass |
| TC-039-06 | Edit another field with blanks | Apex | Admin | Company changed | Saved | Saved | Pass |
| TC-039-07 | Other statuses with blanks | Apex | Admin | Working, then Manual Rejection | Both saved | Both saved | Pass |
| TC-039-08 | Edit a Lead that is already Qualified | Apex | Admin | Company changed | Saved | Saved | Pass |
| TC-039-09 | **Approve** button with blanks | Apex | Admin | `approveLead(Id, 'Approved')` | Error; Status stays New | As expected | Pass |
| TC-039-10 | **Approve** button with both filled | Apex | Admin | `approveLead(Id, 'Approved')` | Qualified | Qualified | Pass |
| TC-039-11 | **Reject** button with blanks | Apex | Admin | `approveLead(Id, 'Rejected')` | Manual Rejection | Manual Rejection | Pass |
| TC-039-12 | Create Shopify availability | Apex | Admin | Blank Lead and filled Lead, both set to Qualified | Blank: disabled (stays New); filled: enabled | false / true | Pass |
| TC-039-13 | Bulk: 200 Leads, half blank | Apex | Admin | 200 updates to Qualified | 100 saved, 100 blocked with the rule message | 100 / 100 | Pass |
| TC-039-14 | Non-admin user | Apex | Standard User | Own Lead, blanks | Blocked with the rule message | As expected | Pass |
| TC-039-15 | Rule together with the existing trigger check | Apex | Admin | Blanks and Has Physical Store = No | Blocked | Blocked | Pass |
| TC-039-UI | On screen: Lead Status edit (both blank, Sector blank), Working, Approve (blank, filled), Create Shopify (before, after), create with blanks | UI | Admin | QA Qualify Rule UI | Blocked / allowed as in rows 01 to 12 | 8 of 8 as expected | Pass |

## 4. Defects found
None in the rule. Found and fixed during the build:
- **First rule (at Create Shopify):** worked, but 20 of 33 existing Lead tests failed. Replaced by the Qualified rule (CR-033).
- **Standard conversion:** it sets Status to Qualified, so the rule fired inside 12 tests. Fixed with `NOT(IsConverted)`.
- **One existing test** moved a Lead with no Sales Channel or Sector to Qualified. Test data fixed (`LeadConversionServiceTest`).

## 5. Evidence
| Item | Value |
|---|---|
| CR-033 deploy | `0Afdx00000GV9aTCAT`: 110 of 110 tests passed |
| Apex QA test run (validate only) | `0Afdx00000GV9SPCA1`: 15 of 15 passed, nothing saved |
| Regression baseline (no rule, check-only) | `0Afdx00000GV8XxCAL`: 110 of 110 passed |

## 6. Test data and cleanup
| Record | Used in | Cleanup |
|---|---|---|
| Leads and the Standard User created inside the Apex tests | TC-039-01 to 15 | Rolled back automatically (validate-only run) |
| Lead **QA Qualify Rule UI** (`00Qdx00000KhgdBEAR`) and its 6 Lead Team rows | TC-039-UI | Deleted after the run; Convert Lead was not clicked |
