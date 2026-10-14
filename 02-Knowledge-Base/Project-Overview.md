# KB-001 — Project Overview

| | |
|---|---|
| **Document ID** | KB-001 |
| **Last updated** | 2026-10-14 |

## Business context
Goodr sells to retailers through these **Sales Channels**: Key Account, Specialty, Partnerships and Global.
Each account also has a **Sector** within its channel. Together, Sales Channel and Sector decide:

- the **Cluster** (1–8) on Account, Contact, Lead and Opportunity;
- the **team**: Account Team, Opportunity Team, and the Contact Team / Lead Team custom objects;
- which **record-page sections** are visible;
- reporting and some integrations (for example, Shopify configuration is chosen by Sales Channel or country).

## Orgs
| Alias | Type | Notes |
|---|---|---|
| `GDRSAND` | Sandbox | Development and testing. This repository mirrors this org. It also contains work that isn't approved for production yet (R12, Fulfillment, YTD/inactivity and Tiers fields on pages). |
| `GDRPROD` | Production | Changed only through approved packages in `06-Deployment/Packages/`. |

## Objects in scope
| Object | Key record types / notes |
|---|---|
| Account | Company, Store Location, Franchise. `Sales_Channel__c`, `Sector__c` (dependent picklist), `Cluster__c`, `Sales_Channel_V1__c` and `Sector_V1__c` (backup text fields). |
| Contact | Cluster follows the parent Account. |
| Lead | Created from Typeform retailer forms. The lead page shows a Convert button based on Sales Channel and Status. |
| Opportunity | Sales Channel, Sector and Cluster are copied from the Account. Open opportunities are kept in sync by `AccountCascadeHandler`. |

## 2026 Sales Channel / Sector transition (the main project)
| Old Sales Channel | Old Sector | New Sales Channel | New Sector | Cluster |
|---|---|---|---|---|
| Key Accounts | Core | Key Account | Enterprise | 1 |
| Key Accounts | Mid-Market | Key Account | Strategic (default, confirmed by client) | 1 |
| Key Accounts | Off-Price | Key Account | Discount | 1 |
| Specialty | Bridge | Specialty | Planned | 5 |
| Specialty | Sellgoodr USA | Specialty | Self Service | 6 |
| Specialty | Sellgoodr CAN | Specialty | Self Service | 6 |
| Specialty CAN | Sellgoodr CAN | Specialty | Self Service | 6 |
| Specialty CAN | Bridge | Specialty | Planned | 5 |
| Partnerships | Partnerships | Partnerships | Partnerships | 8 |
| Global | Global | Global | Distributor | 7 |

Values are in **global value sets**: `Sales_Channel`, `Sales_Channel1` (Lead in the sandbox) and `Sector`.
In the sandbox, the old Sector values are **deactivated, not deleted**. Old values are backed up in the V1 fields.

## Cluster and team model (summary)
- `Sales_Channel_Cluster__mdt` holds one rule per object, e.g. `Sales_Channel__c = 'Specialty' && Sector__c = 'Self Service'` → Cluster 6.
  `ClusterRuleEngine` applies the **first matching rule**, with no ordering. It skips Contact; Contact follows its Account.
- `Account_Cluster_Team__mdt` holds the team members per cluster and object (roles: Sales Director, Sales Manager, Account Manager,
  Marketing Support, Field Support, Field Marketing Support). `ClusterTeamEngine` assigns them and skips inactive users.
- The cluster is recalculated when **Sales Channel or Sector** changes (fixed 2026-10-09).

More detail: [07-Technical/TECH-001_Cluster-and-Team-Engine.md](../07-Technical/TECH-001_Cluster-and-Team-Engine.md).

## Integrations
Shopify (accounts, contacts, addresses, orders, sales, at-risk offboarding), NetSuite (products and pricebooks),
Typeform (retailer forms → Lead, files) and Zendesk (webhook → Case). See [02-Knowledge-Base/Integrations.md](../02-Knowledge-Base/Integrations.md).

## Client decisions (data migration)
| Question | Decision |
|---|---|
| Which records? | All records on Account, Contact, Lead and Opportunity |
| Backup | Full DWH download first; old values copied to the V1 fields |
| Old picklist values | Remove after the copy exists |
| Key Account + Mid-Market | Strategic (default) |
| Converted Leads | Update them too |
| Blank Sector | Stays blank |
| Records with "UAT" in the name | Can be deleted |

## Glossary
| Term | Meaning |
|---|---|
| Cluster | Number 1–8 that decides the sales team for a record |
| LRP | Lightning Record Page (FlexiPage) |
| V1 fields | Backup text fields holding the pre-2026 Sales Channel / Sector |
| CMDT | Custom metadata type |
| Check-only / validate | A deploy that runs everything but saves nothing (`--dry-run`) |
| DWH | Data warehouse export taken before data changes |
