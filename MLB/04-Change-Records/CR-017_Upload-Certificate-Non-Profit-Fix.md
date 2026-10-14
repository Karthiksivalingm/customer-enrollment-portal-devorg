# CR-017 — Upload Certificate flow: Non-Profit fix

| | |
|---|---|
| **Change ID** | CR-017 |
| **Date** | 2026-10-08 |
| **Related** | [CON-001](../05-Conflicts/CON-001_Upload-Certificate-Non-Profit-Value-Mismatch.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000008BeDSAU |

## What changed
`Upload_Certificate` flow, decision `Check_Account_Type`: the comparison value changed from **"Non Profit"** to **"Non-Profit"** to match the Account Type picklist. The error message spelling was also corrected.

## Verification
The user confirmed uploads work for the test contact *MLB Non profit* (003iV000001KEHcQAO).
