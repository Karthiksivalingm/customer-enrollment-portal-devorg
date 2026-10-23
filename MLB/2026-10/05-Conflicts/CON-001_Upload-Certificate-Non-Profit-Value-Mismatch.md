# CON-001 — Upload Certificate flow: "Non Profit" vs "Non-Profit"

| | |
|---|---|
| **ID** | CON-001 |
| **Status** | ✅ Resolved 2026-10-08 ([CR-017](../04-Change-Records/CR-017_Upload-Certificate-Non-Profit-Fix.md)) |
| **Found** | 2026-10-07 during analysis; reported by the user 2026-10-08 |

## Conflict
- The `Upload_Certificate` flow compared `Account.Type` with **"Non Profit"**, but the picklist value is **"Non-Profit"**.
- The Contact formula `Account_Type__c` turns "Non-Profit" into "Non Profit", so the page button filters (which use the formula) worked while the flow (which uses `Account.Type`) did not.

## Impact
Non-Profit vendors got *"Certificates cannot be uploaded for this Contact … Current Type: Non-Profit"*.

## Resolution
The flow compares with "Non-Profit". The page filters still correctly use "Non Profit" (the formula value).

## Lesson
Two spellings exist for the same type: `Account.Type` = "Non-Profit", `Contact.Account_Type__c` = "Non Profit". Use the right one for the field being read.
