# CON-036 — The sandbox-only "Key Account" rename breaks test classes in other deployments

| | |
|---|---|
| **ID** | CON-036 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-22 (validation of the at-risk / offboarding release) |
| **Area** | Deployment / Sales Channel |
| **Related** | [CR-006](../04-Change-Records/CR-006_Key-Accounts-To-Key-Account-Rename-In-The.md) · [CR-008](../04-Change-Records/CR-008_Key-Account-References.md) · [CR-029](../04-Change-Records/CR-029_ShopifyOrderSyncTest-Org-Independent-Sales-Channel.md) |

## Risk
The Sales Channel value "Key Accounts" was renamed to "Key Account" in the sandbox, and 9 test classes were changed to use the new value (CR-008). In any org that still has "Key Accounts", a test class that inserts "Key Account" fails with *"bad value for restricted picklist field"*.

## Mitigation
- `ShopifyOrderSyncTest` was fixed so that it does not set a Sales Channel (CR-029).
- Before deploying any other test class changed in CR-008, either release the Sales Channel rename first or remove the value from the test data.
