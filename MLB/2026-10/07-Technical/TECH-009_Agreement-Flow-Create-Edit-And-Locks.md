# TECH-009 — Agreement Flow (create and edit) and locked agreement fields

| | |
|---|---|
| **ID** | TECH-009 |
| **Requirement** | [REQ-014](../03-Requirements/REQ-014_Agreement-Flow-Create-Edit-And-Locked-Agreement-Fields.md) |
| **Source** | `flows/Agreement_Flow.flow-meta.xml` (v68), `flows/Membership_Agreement_Reset_Flow_Update.flow-meta.xml` (v1), `flows/Update_Opportunity_from_Membership_Agreement.flow-meta.xml` (v5), `objects/Membership_Agreement__c/…`, `objects/Opportunity/…`, `quickActions/Opportunity.Edit_Agreement…`, `flexipages/Ticketing_Opportunity_LRP…` |

## 1. Agreement Flow structure
```
Start → Get_opportunity → Get_Related_Account → Get_Existing_Rows (Membership rows, sorted by Id)
      → Has_Agreement?  ── Agreement Type set ──→ Set_Prefill (prefillOpp = Opportunity, prefillRows = rows) ─┐
                        └─ blank ──→ Agreement screen (Select Agreement Type) ──────────────────────────────┤
                                                                                                           ↓
      Check_the_Agreement_Type (on frmAgreementType = BLANKVALUE(TEXT(Agreement_Type__c), Select_Agreement_Type))
        → Membership / Multi-Product / Flex / Suite Lease screens (defaults read prefillOpp / prefillRows)
```
- Runs in **system mode with sharing**: it can set the hidden checkboxes, and users still only reach Opportunities they can see.
- Every screen default reads `prefillOpp`, which is empty for a new agreement, so new agreements start blank even when the Opportunity holds old hidden values.
- Picklist and number fields are mapped back to dropdown values through `frmExisting*` formulas (TEXT(), Others for non-standard game counts, Term Length from the numeric term plus the "New Business" escalator text, seasons split from "start-end").

## 2. Membership rows
| Step | Elements |
|---|---|
| Before each Row Entry screen | `Prep_Row_Lookup` → loop `Seek_Existing_Row` over `prefillRows` → `existingRow` = the row at position rowIndex. Row fields use `existingRow.*` defaults with "ResetValues", so each pass refreshes. |
| Collect | `Add_Row_To_Collection` also sets `currentRow.Id = existingRow.Id` (blank for added rows). |
| Split | Loop `Split_Rows`: no Id → `createRecords`; Id → tick `Flow_Update__c`, add to `updateRecords`. Loop `Extra_Rows_Loop`: saved rows beyond the new row count → `deleteRecords`. |
| Save order | `Update_Membership_Opportunity` **first**, then create, update, delete rows (DEF-001), then summary. |
| Errors | Every fault path → `Rollback_Changes` → Update Failed screen. |

## 3. Locks
| Object | Rule | Exception | Who sets the exception |
|---|---|---|---|
| Membership_Agreement__c | `Membership_Agreement_Flow_Only`: NOT(ISNEW()) AND NOT(Flow_Update__c) AND OR(ISCHANGED(35 fields)) | `Flow_Update__c` ticked in the same save | Agreement Flow ticks it; `Membership_Agreement_Reset_Flow_Update` (after save) unticks it. |
| Opportunity | `Agreement_Sections_Flow_Only`: NOT(ISNEW()) AND NOT(ISCHANGED(Agreement_Flow_Update__c)) AND OR(ISCHANGED(35 fields)) | `Agreement_Flow_Update__c` **flipped** in the same save | Agreement Flow (`frmToggleAgreementFlowUpdate`) and `Update_Opportunity_from_Membership_Agreement`. |

- The Opportunity uses flip, not tick-and-reset, to avoid a second Opportunity save (which would re-run every Opportunity trigger and flow, including Adobe Sign).
- Formula fields (Total Membership Price, Total Membership Due) are excluded from the rule.
- `Update_Opportunity_from_Membership_Agreement` skips the first row save of an edit (`Flow_Update__c` = true) and runs on the reset save, flipping the Opportunity checkbox.

## 4. Buttons
| Action | Visible when (Ticketing_Opportunity_LRP) | Opens |
|---|---|---|
| Create Agreement | Agreement Type is none of the four types | Agreement_Flow |
| Edit Agreement | Agreement Type is one of the four types | Agreement_Flow |

## 5. Production notes
- Deploy order: the two checkbox fields → flows → validation rules last (so the flows already set the exceptions).
- Agreement_Flow v67's "1 year New Business" choice is kept but not wired (CON-017).
- The outbound change set "Membership Agreement Flow Only" (created 2026-10-14) holds no components; add them in Setup or use a fresh change set.
