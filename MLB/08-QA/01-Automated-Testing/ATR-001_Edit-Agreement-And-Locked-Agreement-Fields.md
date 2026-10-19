# ATR-001 — Edit Agreement and locked agreement fields

| | |
|---|---|
| **Report ID** | ATR-001 |
| **Requirement** | REQ-014 Edit Agreement and locked agreement fields (requirement document to follow) |
| **Manual test cases** | [MTC-001](../02-Manual-Testing/MTC-001_Edit-Agreement-And-Locked-Agreement-Fields.md) |
| **Org** | Sandbox (UTDEV) |
| **Run date** | 2026-10-19 |
| **Run as** | System Administrator (Billy Marlin); Sales Manager profile (Marlins Sales Leadership) in backend tests |
| **Result** | **22 of 22 scenarios passed** after one defect was found and fixed (DEF-001) |

## 1. Scope
| Component | Type | Version tested |
|---|---|---|
| `Edit_Agreement_Flow` | Screen flow (Edit Agreement button) | v4 |
| `Agreement_Flow` | Screen flow (Create Agreement button) | v66 |
| `Opportunity.Edit_Agreement` | Quick action on the Ticketing Opportunity record page | — |
| `Membership_Agreement__c.Membership_Agreement_Flow_Only` | Validation rule | active |
| `Membership_Agreement__c.Flow_Update__c` | Hidden checkbox | — |
| `Membership_Agreement_Reset_Flow_Update` | Record-triggered flow (unticks Flow_Update__c) | v1 |
| `Opportunity.Agreement_Sections_Flow_Only` | Validation rule (35 agreement fields) | active |
| `Opportunity.Agreement_Flow_Update__c` | Hidden checkbox | — |
| `Update_Opportunity_from_Membership_Agreement` | Record-triggered flow | v5 |

## 2. How the tests were run
- **Backend (TC-014-01 to 13):** Apex test class [ATR-001_EditAgreementQaTest.cls](ATR-001_EditAgreementQaTest.cls), run as a **validate-only deployment**. Salesforce ran the tests in the org and saved nothing: no class or data was left behind.
- **Front end (TC-014-14 to 22):** the real Create Agreement and Edit Agreement screens driven in Chrome as the System Administrator. Each save was checked with SOQL queries. The four test Opportunities and their Membership rows were snapshotted first and restored afterwards (section 6).

## 3. Scenario results

### Backend
| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-014-01 | Create Membership Agreement rows | Apex | System | 3 new rows | Rows are created (rule ignores new records) | 3 rows created | Pass |
| TC-014-02 | Manual edit of a row by an administrator | Apex | System Administrator | Seat Quantity 1 → 5 | Save blocked with the Membership rule message | Blocked: "Membership Agreement records can't be edited manually…" | Pass |
| TC-014-03 | Manual edit of a row by a Sales Manager | Apex (runAs, user mode) | Sales Manager | Seat Quantity → 7 | Save blocked with the Membership rule message | Blocked with the rule message | Pass |
| TC-014-04 | Edit Agreement row update (Flow_Update__c ticked) | Apex | System | Seat Quantity → 4, box ticked | Saves; box unticked right after the save | Saved, Qty 4, Flow_Update__c = false | Pass |
| TC-014-05 | Manual edit after a flow update | Apex | System Administrator | Seat Quantity → 9 | Blocked again | Blocked with the rule message | Pass |
| TC-014-06 | Bulk: 200 rows | Apex | System Administrator / System | 200 manual edits; 200 flow updates | All 200 manual edits blocked; all 200 flow updates saved and unticked | 200 blocked; 200 saved with Qty 3 and box unticked | Pass |
| TC-014-07 | Delete a surplus row | Apex | System | Delete 1 of 3 rows | Delete allowed | 2 rows remain | Pass |
| TC-014-08 | Manual edit of agreement fields on the Opportunity by an administrator | Apex | System Administrator | Parking Passes (Suite), Term Length (Membership), Amount for Flex (Multi-Product), Total Due Today (Flex) | Each save blocked with the Opportunity rule message | All four blocked: "Agreement details can't be edited manually…" | Pass |
| TC-014-09 | Manual edit of an agreement field by a Sales Manager | Apex (runAs, user mode) | Sales Manager | Parking Passes → 13 | Blocked | Blocked with the rule message | Pass |
| TC-014-10 | Create / Edit Agreement save (checkbox flipped) | Apex | System | Parking Passes → 14, checkbox flipped | Saves | Parking Passes 14 | Pass |
| TC-014-11 | Non-agreement Opportunity field | Apex (runAs, user mode) | Sales Manager | Next Step = "QA next step" | Saves normally | Saved | Pass |
| TC-014-12 | New Opportunity with agreement values | Apex | System | Flex, Total Due Today 50 | Created (rule applies to edits only) | Created with Total Due Today 50 | Pass |
| TC-014-13 | Paid to Date changed through Edit Agreement | Apex | System | Row Paid to Date → 500, box ticked | Row saves; Opportunity Total Paid to Date becomes 500 | Saved; Opportunity Total Paid to Date 500 | Pass (after DEF-001 fix) |

### Front end
| Test ID | Scenario | Type | Run as | Input / test data | Expected result | Actual result | Result |
|---|---|---|---|---|---|---|---|
| TC-014-14 | Which button shows | UI | System Administrator | Opportunity with no agreement; Suite Lease Opportunity | No agreement: Create Agreement only. With agreement: Edit Agreement only | Blank: Create Agreement only. Suite Lease: Edit Agreement and Send Suite Agreement, no Create Agreement | Pass |
| TC-014-15 | Suite Lease opens pre-filled | UI | System Administrator | Suite Lease Opportunity | Every field shows the saved value | Legends, 16, Founders, 23 tickets, 10 games, 1 year, $1,111.00, Parking Pass 11 | Pass |
| TC-014-16 | Edit and save Suite Lease | UI + SOQL | System Administrator | Parking Pass 11 → 12; Games 10 → 40 | Saved; words "Forty (40)"; Entity Name unchanged; Due Date = today + 3 business days | Parking 12, Games 40, "Forty (40)", Entity "Meshak UT Person Account", Due Date 2026-10-22 | Pass |
| TC-014-17 | Edit and save Multi-Product | UI + SOQL | System Administrator | Amount for Flex 1 → 5 | Pre-filled $1/$1/$1, 2026; total recalculated to 7 | Pre-filled as saved; total 7, season 2026, auto renewal 2027 | Pass |
| TC-014-18 | Edit and save Membership | UI + SOQL | System Administrator | Row 1 price $1,234 → $1,500; Paid to Date $12,111 → $12,500 | Row counts, rows and terms pre-filled; same rows updated (same IDs); Opportunity Total Paid to Date 12,500 | MA-417 and MA-418 updated in place (IDs unchanged); price 1,500; Paid to Date 12,500 on rows and Opportunity | Pass |
| TC-014-19 | Membership: add rows | UI + SOQL | System Administrator | Ticket rows 1 → 3 | Existing rows kept; one new row created | MA-417 and MA-418 kept; MA-421 created | Pass |
| TC-014-20 | Membership: remove rows | UI + SOQL | System Administrator | Ticket rows 3 → 1 | Surplus row deleted; ticket details cleared from the parking-only row | MA-421 deleted; MA-418 ticket fields cleared, parking kept; MA-417 unchanged | Pass |
| TC-014-21 | Flex: create, then edit | UI + SOQL | System Administrator | Create: Total 6,000, PIF, season 2026. Edit: Total → 6,500 | Created; button switches to Edit Agreement; edit pre-filled; PIF keeps Total Due Today = total | Created (6,000 / PIF / due 6,000 / 2026 / 2027); edit pre-filled; saved 6,500 / due 6,500 | Pass |
| TC-014-22 | Manual edit right after an Edit Agreement save | API | System Administrator | MA-417 Seat Quantity → 4 | Blocked (box was unticked) | Blocked with the rule message | Pass |

## 4. Defects found
| ID | Found in | Description | Fix | Retest |
|---|---|---|---|---|
| DEF-001 | TC-014-13 (first run, validate `0AfiV000000ALw1SAG` failed) | Changing Paid to Date through Edit Agreement failed: "Agreement details can't be edited manually". When the reset flow re-saved the row, `Update_Opportunity_from_Membership_Agreement` ran and updated the Opportunity's Total Paid to Date without flipping `Agreement_Flow_Update__c`, so the Opportunity rule blocked it. | `Update_Opportunity_from_Membership_Agreement` v5 now flips `Agreement_Flow_Update__c`. `Edit_Agreement_Flow` v4 saves the Opportunity before the Membership rows. | TC-014-13 passed (validate `0AfiV000000AMDlSAO`); TC-014-18 passed in the UI with a Paid to Date change |

## 5. Evidence
| Item | Value |
|---|---|
| Backend test run (validate-only, 13 of 13 passed) | `0AfiV000000AMDlSAO` |
| Backend run that exposed DEF-001 | `0AfiV000000ALw1SAG` (failed) |
| Active versions during testing | Edit_Agreement_Flow v4, Agreement_Flow v66, Update_Opportunity_from_Membership_Agreement v5, Membership_Agreement_Reset_Flow_Update v1 |
| Test class | [ATR-001_EditAgreementQaTest.cls](ATR-001_EditAgreementQaTest.cls) (not saved in the org) |
| Error message seen (Opportunity) | "Agreement details can't be edited manually. Please use the Edit Agreement button on the Opportunity." |
| Error message seen (Membership row) | "Membership Agreement records can't be edited manually. Please use the Edit Agreement button on the Opportunity." |

## 6. Test data and cleanup
| Record | Used in | Restored |
|---|---|---|
| Opportunity 006iV000000XUIfQAO (Suite Lease) | TC-014-14 to 16 | Yes |
| Opportunity 006iV000000P9WOQA0 (Multi-Product) | TC-014-17 | Yes |
| Opportunity 006iV000000ZvoDQAS (Membership) and rows MA-417, MA-418 | TC-014-18 to 20, 22 | Yes |
| Row MA-421 | Created in TC-014-19 | Deleted by TC-014-20 |
| Opportunity 006iV000000ZBBtQAO (no agreement) | TC-014-14, 21 | Yes, back to no agreement |

- Every snapshot field on the four Opportunities and both Membership rows was compared after the restore: **0 differences**, no extra rows, both hidden checkboxes unticked.
- The restore used a temporary Apex helper (`TmpQaRestore`), deleted straight after. No temporary classes remain in the org.
