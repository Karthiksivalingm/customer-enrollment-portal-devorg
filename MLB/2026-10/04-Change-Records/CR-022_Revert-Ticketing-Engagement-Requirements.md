# CR-022 — Ticketing Engagement fields and Opportunity link: built, then reverted

| | |
|---|---|
| **Change ID** | CR-022 |
| **Dates** | Built 2026-10-08 · Reverted 2026-10-09 |
| **Requirement** | [REQ-011](../03-Requirements/REQ-011_Ticketing-Engagement-Fields-and-Opportunity-Link.md) (ON HOLD) |
| **Org** | utdev sandbox |
| **Build deploy IDs** | 0AfiV0000008QADSA2 · 0AfiV0000008QLVSA2 · 0AfiV0000008QOjSAM |
| **Revert deploy IDs** | 0AfiV0000008ZmzSAE · 0AfiV0000008ZqDSAU, plus Tooling API deletion of 2 flow versions |
| **Final state** | **Fully reverted**; nothing remains. No data was lost (all new fields were empty). |

## Built, then removed
| Component | Type |
|---|---|
| `Ticketing_Engagement__c.Member_Since__c`, `Traditional_Group_Since__c`, `Nightly_Suite_Since__c` | Text(4) fields (FLS granted to 8 profiles and 2 permission sets) |
| `Member_Since_Year_Only`, `Traditional_Group_Since_Year_Only`, `Nightly_Suite_Since_Year_Only` | Validation rules |
| "Since (Year)" section | Ticketing Engagement layout |
| `Opportunity.Ticketing_Engagement__c` | Lookup (read-only FLS for 23 profiles) |
| `Opportunity_Link_Ticketing_Engagement` | Flow (before save, Opportunity) |
| `Ticketing_Engagement_Link_Opportunities` | Flow (after save, Ticketing Engagement) |
| `Ticketing_Engagement__c.Engagement_Summary` | Quick action (card field set) |
| Lookup field and `console:relatedRecord` card | `Ticketing_Opportunity_LRP` and Opportunity Layout |

## Revert steps (in order)
1. Removed the page and layout references, and deactivated both flows (0AfiV0000008ZmzSAE).
2. Deleted the flow versions through the Tooling API. Flows can't be deleted with a destructive deploy.
3. Destructive deploy of the quick action, validation rules and fields (0AfiV0000008ZqDSAU).
4. Deleted the local files.

## To restore
Deleted fields can be undeleted from **Setup → Object Manager → Fields → Deleted Fields** for 15 days (until about 2026-10-24). Otherwise rebuild from [TECH-006](../07-Technical/TECH-006_Ticketing-Engagement-Design-On-Hold.md).
