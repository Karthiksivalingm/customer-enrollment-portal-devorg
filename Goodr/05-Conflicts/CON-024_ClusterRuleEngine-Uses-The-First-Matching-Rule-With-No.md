# CON-024 — ClusterRuleEngine uses the first matching rule with no ordering

| | |
|---|---|
| **ID** | CON-024 |
| **Status** | ⚠ Open risk |
| **Found** | 2026-10-12 |
| **Where** | `Sales_Channel_Cluster__mdt` |

## Risk
`ClusterRuleEngine` uses the **first matching rule** with no ordering

## Mitigation
Rules must never overlap for the same object
