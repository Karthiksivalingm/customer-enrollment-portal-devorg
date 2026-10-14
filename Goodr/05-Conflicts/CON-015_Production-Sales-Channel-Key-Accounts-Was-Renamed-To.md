# CON-015 — Production: "Key Accounts" renamed by hand before the package was deployed

| | |
|---|---|
| **ID** | CON-015 |
| **Status** | ⚠ Open (deploy REQ-024, fix report REQ-020) |
| **Found** | 2026-10-13 |
| **Area** | Production |

## Conflict
Sales Channel "Key Accounts" was renamed to "Key Account" by hand in **production** on 2026-10-06 11:48, before the rest of the Key Account package

## Resolution
Rename step is already done in prod. Deploy `KeyAccount_Rename_PROD` (cluster rules, team records) soon: prod cluster rules still say 'Key Accounts' and no longer match. Fix the report filters (REQ-020)
