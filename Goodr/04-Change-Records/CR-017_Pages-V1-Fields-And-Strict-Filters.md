# CR-017 — Pages: V1 fields and strict filters

| | |
|---|---|
| **Change ID** | CR-017 |
| **Date** | 2026-10-09 (9 Oct) |
| **Requirement** | [REQ-011](../03-Requirements/REQ-011_Strict-New-Mapping-Page-Filters.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GEoOjCAL`, `0Afdx00000GEotNCAT`, `0Afdx00000GEp9VCAT` |
| **By** | Assistant |
| **Status** | Done |

## What changed
| Time | Deploy (dry run) | Components |
|---|---|---|
| 10:03 | `0Afdx00000GEoOjCAL` (`GEoJtCAL`; `GEo8bCAD` and `GEoLVCA1` failed on the inactive "Bridge") | Store Location and Franchise pages: V1 fields after Sector in Details |
| 10:15 | `0Afdx00000GEotNCAT` (`GEmQBCA1`, `GEoq9CAD`; `GEoi5CAD` and `GEojhCAD` failed) | Company page: old-value filters replaced (Sellgoodr = Specialty AND Self Service; Bridge = Specialty AND Planned; Key Account; Partnerships; Global) + V1 fields |
| 10:20 | `0Afdx00000GEp9VCAT` (`GEoyDCAT`) | Lead page: same filters; Convert = Sales Channel ≠ Specialty AND Status = Qualified |

## Rollback
Redeploy the previous page versions from git history. The old filters reference inactive values, so reactivate those first.
