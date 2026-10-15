# Retrieval Report — 2026-10-15 (initial baseline)

| Field | Value |
|---|---|
| Org | Alias `Arizona` — Azlionhearts, Org ID `00DWH000005wW9V2AU`, `IsSandbox = true` (verified by `node scripts/verify-org.js` before listing and before retrieval) |
| Production | Not used |
| Method | `sf project retrieve start --manifest manifest/batches/<batch>.xml --target-org Arizona --wait 60`, run from `Arizona/`, one batch at a time |
| Scope | [Metadata-Scope.md](../Metadata-Scope.md); explicit member names from `scripts/build-manifest.js` |
| Org changes | None. Read-only listing and retrieval; no deployment, no record changes |

## Batch results
| Batch | Time (UTC+05:30) | Status | Files created | Failed components |
|---|---|---|---|---|
| `01-code` | 14:01–14:02 | Succeeded | 417 | 0 |
| `02-data-model` | 14:02–14:03 | Succeeded | 873 | 0 |
| `03-automation` | 14:03–14:03 | Succeeded | 26 | 0 |
| `04-security-integration` | 14:03–14:04 | Succeeded with failure | 18 | 1 — ConnectedApp `CPQIntegrationUserApp` ([CF-001](../../05-Conflicts/2026-10-15-CF-001-connectedapp-cpqintegrationuserapp-cannot-be-retrieved.md)) |
| `05-reports-email` | 14:04–14:05 | Succeeded | 228 | 0 |
| `06-experience` | 14:05–14:05 | Succeeded with failures | 10 | 4 — ExperienceBundles ([CF-002](../../05-Conflicts/2026-10-15-CF-002-aura-site-experiencebundles-not-retrievable.md)) |
| Retry: `ConnectedApp:CPQIntegrationUserApp` | 14:12 | Failed again | 0 | 1 (same error) |
| Retry: `DigitalExperienceBundle:site/Marketing_Landing_Pages1` | 14:12 | Succeeded | 75 | 0 |
| **Total** | | | **1,647** | **4 still missing** |

1,647 files exist under `force-app/main/default/` after retrieval, matching the reported created count.

## Still missing from source
| Component | Reason | Record |
|---|---|---|
| ConnectedApp `CPQIntegrationUserApp` | Metadata API "Load of metadata from db failed" | CF-001 |
| ExperienceBundle `Client_Portal1`, `MemberDocuments1`, `Provider_Portal_Member_Portal1` | Org setting *Enable ExperienceBundle Metadata API* is off (not changed: not authorized) | CF-002 |

## Checks after retrieval
- `node scripts/secret-scan.js`: no findings. Manual review: PandaDoc keys are read from custom labels (not retrieved); the PandaDoc
  External Credential header is a `{!$Credential...}` merge formula; Google authentication signs with an org certificate.
- `node scripts/build-inventory.js`: [Metadata-Inventory.md](../Metadata-Inventory.md) generated.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Report written after the initial retrieval. |
