---
id: CF-001
date: 2026-10-15
title: ConnectedApp CPQIntegrationUserApp cannot be retrieved
status: Open
event_key: cf-connectedapp-retrieve-2026-10-15
---

# CF-001 — ConnectedApp CPQIntegrationUserApp cannot be retrieved

| Field | Value |
|---|---|
| **Conflict ID** | CF-001 |
| **Discovered** | 2026-10-15 14:04 UTC+05:30 (batch `04-security-integration`), retried 14:12 UTC+05:30 |
| **Related requirement / change** | Initial retrieval — [2026-10-15 retrieval report](../07-Technical-Documents/Retrieval/2026-10-15-Initial-Retrieval.md) |
| **Status** | Open |

## Error message and evidence
```
sf project retrieve start --manifest manifest/batches/04-security-integration.xml --target-org Arizona
Status: Succeeded (18 created, 1 failed)
ConnectedApp CPQIntegrationUserApp: Metadata API received improper input. Please ensure file name and capitalization is correct.
Load of metadata from db failed for metadata of type:ConnectedApp and file name:CPQIntegrationUserApp.

Retry: sf project retrieve start --metadata ConnectedApp:CPQIntegrationUserApp --target-org Arizona  → same error.
```

## Affected components
- ConnectedApp `CPQIntegrationUserApp` (listed by `sf org list metadata --metadata-type ConnectedApp`, `manageableState = unmanaged`).

## Reproduction steps
1. `node scripts/verify-org.js`
2. `sf project retrieve start --metadata ConnectedApp:CPQIntegrationUserApp --target-org Arizona --wait 20`

## Investigation performed
| Date | Step | Finding |
|---|---|---|
| 2026-10-15 | Batch retrieval | 1 of 19 components in the batch failed with the error above |
| 2026-10-15 | Single-component retry | Same error; not a transient failure |
| 2026-10-15 | Reviewed name/capitalization against the org listing | Name is exactly as listed by the org |

## Potential causes (suspected, not confirmed)
- The connected app is platform-created (the name suggests the Salesforce CPQ / Revenue Cloud integration-user app); some
  system-created connected apps cannot be read through the Metadata API.
- The app may belong to a feature or package context that the listing reports as unmanaged.

## Confirmed root cause
Not yet confirmed.

## Resolution
Not yet resolved. No local file exists for this component; the rest of the baseline is unaffected.
Next step: an administrator checks Setup → App Manager for `CPQIntegrationUserApp` (owner, whether it was created by the platform) and decides
whether it is project configuration. If not, add it to the scope exclusions in `config/arizona-project.json`.

## Files and components changed
- None.

## Tests and verification
| Date | Test / check | Result |
|---|---|---|
| 2026-10-15 | Retry of the single component | Failed (same error) |

## Remaining risks and follow-up actions
- Integration documentation cannot describe this app's OAuth scopes or policies until it is retrieved or reviewed in Setup.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Conflict recorded during the initial retrieval. |
