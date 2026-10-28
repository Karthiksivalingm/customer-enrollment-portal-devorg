# ATR-003 — Suite Lease payment schedule and Person Account Type values

| | |
|---|---|
| **Report ID** | ATR-003 |
| **Requirements** | [REQ-019](../../03-Requirements/REQ-019_Suite-Lease-Payment-Schedule.md) · [REQ-020](../../03-Requirements/REQ-020_Person-Account-Type-Values.md) |
| **Manual test cases** | [MTC-003](../02-Manual-Testing/MTC-003_Suite-Lease-Payment-Schedule-And-Person-Account-Type.md) |
| **Org** | Sandbox (UTDEV) |
| **Run date** | 2026-10-27 (build) and 2026-10-28 (final run) |
| **Run as** | System Administrator (Billy Marlin); a Marlins Sales Leadership user (Sales Managers role) in the Apex tests |
| **Result** | **20 of 20 scenarios passed** in the final run. One defect (DEF-002) was found during the build, fixed and retested. |

## 1. Scope
| Component | Type | Version tested |
|---|---|---|
| `Agreement_Flow` | Screen flow | v75 (active) |
| `Opportunity.Number_of_Payment_Plans__c` (Number of Payment Schedule), `Payment_Amount__c`, `Payment_Due_Date_1–12__c` | Fields | Picklist; Text(18); Text(30) |
| `Payment_Amounts_Numeric_Only`, `Agreement_Sections_Flow_Only` | Validation rules | Active |
| `Ticketing_Opportunity_LRP` | Lightning page | Deploy `0AfiV000000BwVMSA0` |
| Admin, Ticket Sales, Marlins Sales Leadership, Marlins IT Admin | Profiles (field access) | — |
| Suite Lease Adobe document templates DCT-16, DCT-22 | Configuration | 15 entries each |
| `PersonAccount.PersonAccount` | Record type | Deploy `0AfiV000000Bs57SAC` |

## 2. How the tests were run
- **Apex:** QA class [ATR-003_PaymentPlanQaTest.cls](ATR-003_PaymentPlanQaTest.cls), 8 methods with real assertions, run as a validate-only deployment so nothing was saved.
- **Screens:** the Edit Agreement flow was driven in Chrome on test Opportunity 006iV000000XUIfQAO (Suite Lease, This Season Total Amount $1,111). The record was snapshotted, one schedule was saved, the save was checked with a query, and the record was restored and compared field by field.
- **Configuration and access:** UI API, describe and SOQL queries.

## 3. Scenario results
| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-019-01 | Year 1–5 License Fee editable manually | Apex | Sales Manager (user mode) | Fees 1000, 1030, 1060, 1090, 1120 | Saved | Saved; Year 1 = 1000, Year 5 = 1120 | Pass |
| TC-019-02 | License fee editable by an administrator | Apex | System | Year 3 = 5000 | Saved | Saved | Pass |
| TC-019-03 | Schedule fields locked for manual edits | Apex | System | Schedule 3; Payment 1 / 12 Due Date; Payment Amount 100 | Blocked: "Agreement details can't be edited manually" | All 4 blocked with that message | Pass |
| TC-019-04 | Save as the Agreement Flow does | Apex | System | Schedule 3, three due dates, amount 370.33, marker flipped | Saved; values stored | Saved; 3, 370.33, "January 2, 2027" read back | Pass |
| TC-019-05 | Payment Amount numbers only | Apex | System | Valid 1250, 1250.5, 1250.50, 0.99; invalid 12a, abc, 1,250, -5, $100, 1250.505, "12 50" | Valid saved; invalid blocked with "Payment Amount can contain numbers only" | As expected (11 of 11) | Pass |
| TC-019-06 | Only Full and 2–12 accepted | Apex | System | Full, 2, 7, 12; 0, 1, 13, Half | First four saved; others rejected | As expected; "1" rejected | Pass |
| TC-019-07 | Bulk 200 | Apex | System | 200 Suite Lease Opportunities: flow-style save, manual amount "x", manual Year 4 fee | 200 saved / 200 blocked / 200 saved | 200 / 200 / 200 | Pass |
| TC-019-08 | Dropdown label and values | UI | Admin | Edit Agreement, Suite Lease screen | "Number of Payment Schedule", required; --None--, Full, 2–12 | As expected | Pass |
| TC-019-09 | Full shows one Due Date | UI | Admin | Select Full | One required field "Due Date" | As expected | Pass |
| TC-019-10 | N payments show N due dates | UI | Admin | Select 2, 7, 12 | Payment 1–2 / 1–7 / 1–12 Due Date shown | As expected | Pass |
| TC-019-11 | Due dates required | UI | Admin | Select 3, leave dates empty, Next | Stays on the screen, each date flagged | Stayed; "Please enter some valid input. Input is not optional." under Payment 1–3 Due Date | Pass |
| TC-019-12 | End-to-end save | UI + SOQL | Admin | Schedule 3; Nov 2 2026, Dec 2 2026, Jan 2 2027; total $1,111 | Schedule 3; amount 370.33; dates "November 2, 2026", "December 2, 2026", "January 2, 2027"; Payment 4–12 blank; Due Date 2026-11-02; no email | As expected; 0 emails | Pass |
| TC-019-13 | Edit Agreement brings the schedule back | UI | Admin | Reopen Edit Agreement after TC-019-12 | Schedule 3; three dates prefilled | 3; Nov 2 2026, Dec 2 2026, Jan 2 2027 | Pass |
| TC-019-14 | Opportunity page section | UI | Admin | Record after TC-019-12 | Suite Payment Plan shows schedule, Payment 1–3 Due Date, Due Date, Payment Amount only | As expected | Pass |
| TC-019-15 | Adobe tags on both templates | SOQL | Admin | Mappings a2KiV000000Vg4bUAC, a2KiV000000Z9YHUA0 | 15 schedule/type entries each | 15 and 15 | Pass |
| TC-019-16 | Field access | SOQL | Admin | FieldPermissions, 14 fields × 4 profiles | Read and edit on all | 14 of 14 on each profile | Pass |
| TC-019-17 | Definitions | Describe / tooling | Admin | Fields, rules, flow | Label "Number of Payment Schedule"; Payment Amount text 18; due dates text 30; both rules active; flow v75 active; no old amount or "Formatted" fields | As expected | Pass |
| TC-020-01 | Person Account Type values | UI API + UI | Admin | Record type PersonAccount, field Type; Edit on a Person Account | Food and Beverage and Non-Profit offered | 13 values incl. both; shown in the edit form (cancelled, record unchanged) | Pass |
| TC-020-02 | Person Accounts save with the values | Apex | Sales Manager | Two Person Accounts, Type Food and Beverage / Non-Profit | Both saved | Both saved | Pass |
| TC-020-03 | Other record types unchanged | UI API | Admin | Record type Business_Account | Values not offered | Not offered (11 values) | Pass |

## 4. Defects found
| ID | Where found | Description | Fix | Retest |
|---|---|---|---|---|
| DEF-002 | TC-019-10 / 11, first run 2026-10-27 (flow v69) | The due-date fields stayed hidden after choosing a number. Their visibility used a formula (`frmPaymentCount`), which a flow screen does not recalculate, so the "required" check was skipped. The test then pressed Next and saved Opportunity 006iV000000XUIfQAO without dates, clearing Due Date. | Visibility now tests the dropdown value directly (v70, `0AfiV000000BrIjSAK`). The test script now presses Next only when the dates are visible and stops if it leaves the screen. The record was restored (0 differences apart from `Prevent_Validations__c`). | TC-019-10 and 11 passed, and again on v75 |

## 5. Evidence
| Item | Value |
|---|---|
| Final Apex run (validate-only) | `0AfiV000000C8mbSAC`: 8 of 8 passed (amountsAcceptNumbersOnly, bulk200, flowSaveOfFullPlanSucceeds, licenseFeesCanBeEditedManually, licenseFeesEditableByAdminToo, numberOfPaymentPlansOnlyAllowsListValues, paymentPlanFieldsLockedForManualEdits, personAccountTypeValues) |
| Earlier Apex runs | `0AfiV000000BrH7SAK` (v69), `0AfiV000000BxcfSAC` (after CR-041), `0AfiV000000ByP3SAK` (after CR-042): 7 of 7 each |
| Deploys under test | See CR-038 to CR-043 |
| Test record | Opportunity 006iV000000XUIfQAO; Person Account 001iV000000caijQAA (opened only) |
| Screenshots | [MTC-003_screenshots](../02-Manual-Testing/MTC-003_screenshots) |

## 6. Test data and cleanup
| Record | Used in | Cleanup |
|---|---|---|
| Opportunity 006iV000000XUIfQAO | TC-019-08 to 14 (saved once in TC-019-12) | Restored with temporary class `Req019RestoreTmp` (deployed `0AfiV000000C8BWSA0`, run, deleted `0AfiV000000C8jNSAS`; 0 classes left). Field-by-field compare with the snapshot: **0 differences** apart from `Prevent_Validations__c`, which org automation stamps on every save (CON-021). |
| 200 Opportunities, 2 Person Accounts | Apex tests | Validate-only: never saved |
| Person Account 001iV000000caijQAA | TC-020-01 | Edit form opened and cancelled; LastModifiedDate unchanged |
| Emails | All | 0 emails created during the run |
