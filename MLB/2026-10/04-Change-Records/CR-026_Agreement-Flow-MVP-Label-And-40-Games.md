# CR-026 — Agreement Flow: MVP location label and 40-game option

| | |
|---|---|
| **Change ID** | CR-026 |
| **Date** | 2026-10-13 |
| **Requirement** | [REQ-013](../03-Requirements/REQ-013_Suite-Lease-MVP-Label-And-40-Games.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000009F6JSAU |
| **Flow version** | 65 (active); 64 now obsolete |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `Agreement_Flow` | Flow (screen) | Modified. Choice `SuiteChoice_MPV`: label and stored value MPV → **MVP**. Formula `frmSuiteTicketsFinal`: comparison `"MPV"` → `"MVP"` (description updated to match). New choice `SuiteGames_40` (label and value 40), added to the `Suite_Total_Games` dropdown between 20 and 41. |

**Fields used (already existed, unchanged):** `Opportunity.Suite_Location__c` (restricted picklist, already contains MVP) and `Opportunity.Total_of_Games__c` (restricted picklist, already contains 40).

## Pre-check
- The active flow was retrieved from the sandbox and compared with the local file before editing: identical.
- The Opportunity picklists were checked: Suite Location values are Fiesta, Founders, Hall of Fame, Legends, MVP; Total # of Games values are 10, 20, 40, 41, 81.
- The games-in-words formula `frmSuiteGamesInWords` already supports 1–99, so 40 gives "Forty (40)" with no change.

## Verification
- Deploy succeeded: 1 component, 0 errors. Version 65 is active.
- The user ran the Suite Lease path with MVP and 40 games and confirmed it works ("all good").

## Rollback
Activate `Agreement_Flow` version 64 in Flow Builder. Note that version 64 saves "MPV", which the Opportunity picklist rejects (see [CON-015](../05-Conflicts/CON-015_Suite-Location-MPV-vs-MVP.md)).
