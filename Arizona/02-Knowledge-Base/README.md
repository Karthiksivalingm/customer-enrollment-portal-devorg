# 02-Knowledge-Base

Evidence-based overview of the Arizona implementation, built only from retrieved Arizona sandbox metadata and authorized requirements.
Statements are labelled **VERIFIED**, **INFERRED** or **OPEN QUESTION** ([Documentation-Rules.md](../01-Instructions/Documentation-Rules.md) §5).

## Status (2026-10-15)

**Not yet written.** The metadata baseline has been retrieved, but the analysis of the source was interrupted before any Knowledge Base
page was produced. Planned pages: `Project-Overview.md`, `Salesforce-Org-Context.md`, `Data-Model-and-Relationships.md`,
`Automation-and-Processes.md`, `Integrations.md`, `Security-and-Permissions.md`, `Experience-Cloud-Portals.md`, `Known-Constraints-and-Open-Questions.md`.

## Verified so far
| Fact | Evidence |
|---|---|
| Org: Azlionhearts sandbox, Org ID `00DWH000005wW9V2AU`, Enterprise Edition, instance USA766S | `Organization` query, 2026-10-15 ([Salesforce-Safety-Rules.md](../01-Instructions/Salesforce-Safety-Rules.md)) |
| 23 installed packages, including PandaDoc, Pardot / Account Engagement, RingCentral (`rcsfl`), 360 SMS (`tdc_tsw`), Adobe Acrobat Sign, Calendly, TS Documents (`docb`), Data Cloud packages | `sf package installed list`, 2026-10-15 |
| Unmanaged footprint: 56 Apex classes, 4 triggers, 10 flows, 14 LWCs, 5 Aura bundles, 28 VF pages, 5 custom objects, 6 custom metadata types, 2 platform events, Knowledge, 4 Experience sites | [Metadata-Inventory.md](../07-Technical-Documents/Metadata-Inventory.md) |

Until the pages exist, use the [Metadata Inventory](../07-Technical-Documents/Metadata-Inventory.md) and the source directly.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Folder created; status recorded after the analysis was interrupted. |
