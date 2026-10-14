# TECH-008 — Agreement Flow: Suite Lease location and games choices

| | |
|---|---|
| **ID** | TECH-008 |
| **Requirement** | [REQ-013](../03-Requirements/REQ-013_Suite-Lease-MVP-Label-And-40-Games.md) |
| **Source** | `force-app/main/default/flows/Agreement_Flow.flow-meta.xml` |

## Suite Location
| Element | Type | Before | After |
|---|---|---|---|
| `SuiteChoice_MPV` | Choice | label MPV, value MPV | label **MVP**, value **MVP** |
| `frmSuiteTicketsFinal` | Formula | `{!Suite_Location} = "MPV"` | `{!Suite_Location} = "MVP"` |

- `Suite_Location` (dropdown) keeps referencing `SuiteChoice_MPV`.
- The visibility rule on `Suite_Tickets_MPV` compares against the choice reference, not the text, so it needed no change.
- The value flows to `Opportunity.Suite_Location__c` in `Assign_Suite_To_Opportunity`.

## Total # of Games
| Element | Type | Change |
|---|---|---|
| `SuiteGames_40` | Choice | **New.** Label 40, value 40 (String) |
| `Suite_Total_Games` | Dropdown screen field | Choices now 10, 20, **40**, 41, 81 |

- `frmSuiteGamesFinal` = `VALUE({!Suite_Total_Games})` and `frmSuiteGamesInWords` (supports 1–99) are unchanged; 40 → "Forty (40)".
- Saved to `Opportunity.Total_of_Games__c` and `Total_of_Games_in_Words__c` in `Assign_Suite_To_Opportunity`.

## What was deliberately left alone
API names of existing choices and fields, all other screens, decisions, formulas and connectors.
