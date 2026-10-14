# CON-027 — The Shopify classes call four different Admin API versions

| | |
|---|---|
| **ID** | CON-027 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-12 |
| **Where** | Shopify integration |

## Risk
The Shopify classes call four different Admin API versions (2023-10, 2024-01, 2024-04, 2026-04). Older versions get retired by Shopify

## Mitigation
Align them on a supported version
