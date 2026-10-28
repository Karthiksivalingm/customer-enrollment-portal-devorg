# REQ-014 — Agreement Flow (create and edit) and locked agreement fields

| | |
|---|---|
| **ID** | REQ-014 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-21) |
| **Requested** | 2026-10-14 to 2026-10-21 (built in steps; see the change records) |
| **Related** | CR-027 · CR-028 · CR-029 · CR-030 · CR-031 · TECH-009 · CON-016 · CON-017 · ATR-001 · MTC-001 · changed by REQ-019 (CR-038, 2026-10-27) |

## Business need
1. Sales reps need to **change an agreement after it has been captured**, without re-entering everything.
2. Agreement details must not be changed by hand: the **Membership Agreement rows** and the **agreement fields on the Opportunity** may only change through the agreement screens.
3. The client asked for **one flow** for creating and editing agreements (client call, 2026-10-20).

## Scope
- **In:** Agreement Flow (Membership, Multi-Product, Flex, Suite Lease); Create Agreement and Edit Agreement buttons on the Ticketing Opportunity page; Membership Agreement rows; the four agreement sections on the Opportunity.
- **Out:** changing the agreement type of an existing agreement; Adobe Sign sending.

## Functional behaviour
### One flow for create and edit
- **Create Agreement** shows while the Opportunity has no Agreement Type; **Edit Agreement** shows once it has one. Both open **Agreement Flow**.
- **No agreement yet:** the flow asks for the Agreement Type and shows blank screens.
- **Agreement saved:** the flow opens that type directly, with every field filled from the saved values (empty values stay empty). The type cannot be changed.
- Screens, required checks and calculations are the same in both modes (amount in words, games / tickets / years in words, license fees, auto renewal, escalator, prorated payments, seat format).
- **Membership:** each row screen is filled from the matching saved row. Saving updates the same rows; extra rows are created when the row count goes up and surplus rows are deleted when it goes down.
- **Entity Name – Leave As Is** keeps the Entity Name already on the Opportunity (falls back to the Account name when blank).
- **Suite Lease Due Date** is recalculated as today + 3 business days on every save.
- Any error rolls the whole save back and shows the error.

### Locked agreement details
- **Membership Agreement rows:** any change to an editable field on an existing row is blocked for every user, including System Administrators: "Membership Agreement records can't be edited manually. Please use the Edit Agreement button on the Opportunity." Creating and deleting rows is allowed.
- **Opportunity:** changes to the editable fields in the Suite Lease Details, Membership Agreement Details, Multi Product Information and Flex Membership Information sections are blocked for every user: "Agreement details can't be edited manually. Please use the Edit Agreement button on the Opportunity." New Opportunities and all other fields are not affected.
  - **Changed 2026-10-27 by [REQ-019](REQ-019_Suite-Lease-Payment-Schedule.md):** Year 1–5 License Fee are no longer locked (users can edit them), and the Suite Lease payment schedule fields (Number of Payment Schedule, Payment Amount, Payment 1–12 Due Date) are locked. The rule now covers 44 fields (was 35).
- Only Agreement Flow (and the Paid to Date copy flow) can change these fields, through hidden checkboxes that users cannot see or edit.

## Acceptance criteria
1. Only one of Create Agreement / Edit Agreement shows on an Opportunity.
2. A new agreement starts blank after choosing the type; an existing one opens prefilled without the type screen.
3. Saving an edit updates the Opportunity and, for Membership, the same rows (row numbers unchanged); rows are added or removed with the row count.
4. Manual edits of agreement fields on the Opportunity and of Membership rows are blocked for administrators and sales users; other Opportunity fields stay editable.
5. Changing Paid to Date through the flow saves without an error and reaches the Opportunity.

All verified: see ATR-001 and MTC-001.

## Assumptions
- One agreement per Opportunity; the agreement type does not change after creation.

## Open questions
- "1 year New Business" term option (added in the org on 2026-10-19) is not yet wired into the term calculations: see CON-017.
