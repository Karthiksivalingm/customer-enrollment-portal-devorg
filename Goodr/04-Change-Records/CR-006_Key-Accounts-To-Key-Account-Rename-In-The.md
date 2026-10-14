# CR-006 — Key Accounts → Key Account rename in the sandbox

| | |
|---|---|
| **Change ID** | CR-006 |
| **Date** | 2026-10-06 (6 Oct 10:45, Setup) |
| **Requirement** | [REQ-003](../03-Requirements/REQ-003_Rename-Key-Accounts-To-Key-Account.md) |
| **Org** | GDRSAND |
| **Deploy ID** | n/a |
| **By** | User (Setup) |
| **Status** | Done |

## What changed
The label and API name were changed in the global value sets `Sales_Channel` and `Sales_Channel1`. Salesforce updated the records automatically.
Side effect: report filters that used "Key Accounts" lost that value.


## Rollback
Rename the value back in Setup (records follow the rename).
