# CON-018 — API version: Retrieving with manifest version 59

| | |
|---|---|
| **ID** | CON-018 |
| **Status** | ✅ Resolved |
| **Found** | 2026-10-13 |
| **Area** | API version |

## Conflict
Retrieving with manifest version 59.0 dropped newer flow and page elements (styleProperties, areMetricsLoggedToDataCloud)

## Resolution
Use `<version>68.0</version>` in retrieve manifests
