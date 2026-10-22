# CON-037 — Lightning page filters cannot check "the record exists"

| | |
|---|---|
| **ID** | CON-037 |
| **Status** | ✅ Resolved 2026-10-21 ([CR-030](../04-Change-Records/CR-030_Hide-Shopify-Sections-On-New-Account.md)) |
| **Found** | 2026-10-21 during REQ-037 |
| **Area** | Lightning pages |

## Conflict
To hide a section only on the New form, the filter has to test "the record has been saved". The obvious fields are rejected by Salesforce when the page is deployed:

| Filter tried | Error |
|---|---|
| Created Date is not blank | "The 'Record.CreatedDate' field's type isn't supported" (date/time) |
| Record ID not equal / equal blank | "'Id' is a id field, which doesn't support the NE / EQUAL operator" |
| Created By Name is not blank | "Field Name does not exist" (the relationship can't be followed) |
| Created By ID is not blank | "'CreatedById' is a reference field, which doesn't support the NE operator" |
| Inactivity Stage is not blank | Works, but ties the filter to a Shopify at-risk formula that is still awaiting client approval |

## Resolution
A neutral formula checkbox **Is Saved Record** (`NOT(ISBLANK(Id))`) with the filter **Is Saved Record = True**. It needs no data, is correct on every existing record, and can be reused for any "hide on create" request.

## Lesson
For "hide on create", use Is Saved Record. Every user who should see the section needs read access to it.
