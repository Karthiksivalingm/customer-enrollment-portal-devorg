# REQ-037 — Hide the Shopify sections while a new Account is created

| | |
|---|---|
| **ID** | REQ-037 |
| **Status** | ✅ Done in the sandbox (2026-10-21) |
| **Requested** | 2026-10-21 (project lead, client request) |
| **Related** | [CR-030](../04-Change-Records/CR-030_Hide-Shopify-Sections-On-New-Account.md) · [TECH-010](../07-Technical/TECH-010_Section-Filters-And-BI-Section.md) · [CON-037](../05-Conflicts/CON-037_Page-Filters-Cannot-Check-Record-Exists.md) · [ATR-003](../08-QA/01-Automated-Testing/ATR-003_Hide-Shopify-Sections-And-BI-V1-Fields.md) · [MTC-004](../08-QA/02-Manual-Testing/MTC-004_Hide-Shopify-Sections-And-BI-V1-Fields.md) |

## Business need
When a user creates an Account, the **Shopify Offboarding** and **Shopify Sales Performance** sections are not relevant: they are filled by the Shopify jobs after the Account exists. The client asked for both sections to be hidden on the New Account form.

## Scope
- **In:** both sections on every Account record page that has them (Account Company Record Page and Account Store Location Record Page). The filter is set on the **section**, not on single fields.
- **Out:** the fields themselves, field access, page layouts and every other section.

## Functional behaviour
- On the **New Account** form (Company and Store Location) both sections are hidden.
- After the Account is saved, and on every existing Account, both sections show as before.
- A back-end checkbox **Is Saved Record** (`Is_Saved_Record__c`, formula `NOT(ISBLANK(Id))`) drives the filter. It is not shown on any page or layout.

## Acceptance criteria
1. The New Account form for Company and for Store Location shows neither section.
2. Every saved Account shows both sections, for administrators and for other users.
3. Is Saved Record is not visible on any page and cannot be edited.
4. No other part of the pages and no automation changes.

## Assumptions
- Users who see the sections can read Is Saved Record. Read access was given to every profile that can read Accounts (16).

## Open questions
None. The same change can later be made by hand outside the sandbox: create the formula field without adding it to any layout, then add the section filter **Is Saved Record = True** to both sections.
