# CR-033 — Lead validation rule: Sales Channel and Sector required to qualify

| | |
|---|---|
| **Change ID** | CR-033 |
| **Date** | 2026-10-27 |
| **Requirement** | [REQ-039](../03-Requirements/REQ-039_Sales-Channel-Sector-Required-To-Qualify-Lead.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GV9aTCAT`: 3 components, 15 Lead test classes, **110 of 110 tests passed** |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `Lead.Require_Sales_Channel_Sector_To_Qualify` | Validation rule (new, **active**) | Blocks the change to Qualified while Sales Channel or Sector is blank. Error shown on the Status field |
| `Lead.Require_Sales_Channel_Sector_For_Shopify` | Validation rule (new, **inactive**) | First approach, replaced the same day; kept inactive for reference (see below) |
| `LeadConversionServiceTest` | Apex test class | Test Lead in `testCanConvert_QualifiedLeadWithVertical` now has Sales Channel `Specialty` and Sector `Self Service`. Test data only; no logic change |

### Rule formula
```
AND(
  ISCHANGED(Status),
  NOT(IsConverted),
  ISPICKVAL(Status, 'Qualified'),
  OR(ISBLANK(TEXT(Sales_Channel__c)), ISBLANK(TEXT(Sector__c)))
)
```
- **ISCHANGED(Status):** only the move to Qualified is checked. Creating and editing Leads is not affected.
- **NOT(IsConverted):** standard Salesforce conversion also sets Status to Qualified (Goodr's converted status). Without this line the rule fired inside 12 existing tests that use standard conversion. Create Shopify does not use standard conversion, so nothing is lost.

## Why the first approach was replaced
The first rule (`Require_Sales_Channel_Sector_For_Shopify`, deploy `0Afdx00000GV889CAD`) blocked the final step of Create Shopify (ticking Shopify Created). It worked, but it made **20 of 33** existing Lead tests fail, because their test Leads have no Sector. Checking at "Qualified" stops the user one step earlier and needs only one test data fix.

## Impact on other classes
The same 15 test classes that work with Leads were run check-only three times:

| Run | Deploy ID | Result |
|---|---|---|
| No rule (baseline) | `0Afdx00000GV8XxCAL` | 110 of 110 passed |
| Rule without `NOT(IsConverted)` | `0Afdx00000GV8svCAD` | 13 failed (12 standard conversion, 1 genuine) |
| Final rule + test data fix | `0Afdx00000GV9aTCAT` | 110 of 110 passed |

A full RunLocalTests run is not possible in the sandbox at the moment: `CaseTeamAssignmentQueueable` and `WinbackStatusScheduler` don't compile (missing `CaseTeamAssignmentService` and `WinbackStatusSync.syncEmailStatus`). This is not related to this change; see [CON-038](../05-Conflicts/CON-038_Qualify-Rule-And-Existing-Qualified-Leads.md).

## Verification
[ATR-004](../08-QA/01-Automated-Testing/ATR-004_Lead-Qualify-Validation-Rule.md): 15 of 15 scenarios passed, plus the 110 regression tests.

## Rollback
Setup → Object Manager → Lead → Validation Rules → **Require_Sales_Channel_Sector_To_Qualify** → Deactivate. The test class change can stay (it is valid with or without the rule).
