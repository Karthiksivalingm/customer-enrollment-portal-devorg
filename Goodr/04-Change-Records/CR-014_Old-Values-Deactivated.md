# CR-014 — Old values deactivated

| | |
|---|---|
| **Change ID** | CR-014 |
| **Date** | 2026-10-08 (8 Oct, Setup) |
| **Requirement** | [REQ-007](../03-Requirements/REQ-007_Specialty-CAN-To-Specialty-In-Metadata.md) |
| **Org** | GDRSAND |
| **Deploy ID** | n/a |
| **By** | User (Setup) |
| **Status** | Done |

## What changed
- 12:07: Specialty CAN deactivated, then reactivated. Dependencies updated.
- 18:24 – 18:34: Sector values **Sellgoodr USA, Core, Mid-Market, Off-Price, Bridge, Sellgoodr CAN, Global** deactivated, and the Sector picklist reordered.
- 18:35 – 18:36: **Specialty CAN** deactivated in Sales Channel and Sales Channel1. Dependencies updated on all 4 objects.
- The user confirmed on 9 Oct that this was intentional. Effect: page filters can't reference these values any more (see CR-017).


## Rollback
Reactivate the values in Setup and restore the dependencies.
