# CR-009 — New Sector values in logic

| | |
|---|---|
| **Change ID** | CR-009 |
| **Date** | 2026-10-06 (6 Oct) |
| **Requirement** | [REQ-004](../03-Requirements/REQ-004_Add-New-Sector-Values-Where-Old-Values-Are.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GAl4TCAT`, `0Afdx00000GAp02CAD` |
| **By** | Assistant |
| **Status** | Done |

## What changed
| Time | Deploy (dry run) | Components |
|---|---|---|
| 13:07 | `0Afdx00000GAl4TCAT` (`GAj4HCAT`, `GAkoLCAT`) | 8 new cluster rules: Specialty_Self_Service_Account/Lead/Opp/Contact (Cluster 6), Specialty_Planned_Account/Lead/Opp/Contact (Cluster 5). Additive; the old rules stay |
| 14:34 | `0Afdx00000GAp02CAD` (`GAihiCAD`) | Company and Lead pages: Specialty-Sellgoodr filter gets `Sector ≠ Planned`, Specialty-Bridge filter gets `Sector = Planned` |

## Rollback
Delete the 8 rules with a destructive-changes deploy and redeploy the previous page versions from git history.
