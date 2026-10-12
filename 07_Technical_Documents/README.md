# Technical Documents

| Document | Contents | How it's maintained |
|---|---|---|
| [Cluster_and_Team_Engine.md](Cluster_and_Team_Engine.md) | How Sales Channel / Sector drive the Cluster and the teams | By hand |
| [Integrations.md](Integrations.md) | Shopify, NetSuite, Typeform, Zendesk: settings, classes, entry points | By hand |
| [Apex_Classes.md](Apex_Classes.md) | All Apex classes by area: kind, objects queried, callouts, methods, test class | Generated |
| [Apex_Triggers.md](Apex_Triggers.md) | Triggers: object, events, handler classes | Generated |
| [Flows.md](Flows.md) | Flows: type, object, trigger, status, description | Generated |
| [Fields_and_Custom_Metadata.md](Fields_and_Custom_Metadata.md) | Tracked custom fields, custom metadata types, the full cluster rule list | Generated |
| [UI_Components.md](UI_Components.md) | Record pages, LWC, Aura, Visualforce | Generated |
| `Impact_Analysis/Sector_Where_Used_Analysis.xlsx` | Where Sales Channel / Sector are used (classes, flows, pages, reports, dashboards) and the impact of each change | Excel |

To regenerate the generated files after retrieving new metadata, run this from the repo root:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/doc-builders/build_technical_docs.ps1
```
