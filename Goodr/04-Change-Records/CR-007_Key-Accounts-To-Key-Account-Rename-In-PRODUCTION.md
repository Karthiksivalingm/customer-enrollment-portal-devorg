# CR-007 — Key Accounts → Key Account rename in PRODUCTION

| | |
|---|---|
| **Change ID** | CR-007 |
| **Date** | 2026-10-06 (6 Oct 11:48, Setup) |
| **Requirement** | [REQ-003](../03-Requirements/REQ-003_Rename-Key-Accounts-To-Key-Account.md) [REQ-024](../03-Requirements/REQ-024_Deploy-Key-Account-Package-To-Production.md) |
| **Org** | GDRPROD |
| **Deploy ID** | n/a |
| **By** | User (Setup) |
| **Status** | Done in PRODUCTION |

## What changed
Same rename, done by hand in **GDRPROD**.
- Because of this, the production deployment step "rename the picklist value" is **already done**. The `KeyAccount_Rename_PROD` package (rules, team records, tests) should follow soon, because cluster rules that still say 'Key Accounts' no longer match any record.
- The production report `Accounts_without_NetSuite_Id` lost "Key Accounts" from its filter (REQ-020).


## Rollback
Rename the value back in production Setup (records follow the rename).
