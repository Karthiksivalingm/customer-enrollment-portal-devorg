# CON-031 — Shopify company rollup is calculated per 200-record batch chunk

| | |
|---|---|
| **ID** | CON-031 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-13 |
| **Where** | `ShopifyR12SalesBatch` |

## Risk
Shopify company rollup is calculated per 200-record batch chunk; a company split across chunks gets partial R12/YTD totals

## Mitigation
Fix before relying on company-level at-risk flags
