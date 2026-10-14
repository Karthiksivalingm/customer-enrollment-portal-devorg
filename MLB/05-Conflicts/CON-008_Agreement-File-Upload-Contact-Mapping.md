# CON-008 — Signed PDF not saved to the Contact (wrong data mapping target)

| | |
|---|---|
| **ID** | CON-008 |
| **Status** | ✅ Resolved 2026-10-06 ([CR-010](../04-Change-Records/CR-010_Agreement-File-Upload-Contact-Mapping-Fix.md)) |

## Conflict
- Every signed Vendor Activation agreement showed Data Mapping Result **Failed**: *"Attempted to map to a related object reference which was not set on the agreement: echosign_dev1__Recipient2__r"*.
- The signer Contact is stored in `echosign_dev1__Recipient__c` (first recipient), not `Recipient2__c`.
- Earlier attempts in the mapping editor had targeted Opportunity and Recipient4, with the same failure.

## Resolution
The mapping object now points at `Recipient__c` / `echosign_dev1__Recipient__r`.
