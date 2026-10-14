# CR-018 — Deactivate the Delete Agreement File flow

| | |
|---|---|
| **Change ID** | CR-018 |
| **Date** | 2026-10-08 |
| **Requirement** | [REQ-009](../03-Requirements/REQ-009_Demo-Feedback-Agreement-Files-Status-Tracking-Certificate-Rules.md) §9.1 |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000008JezSAE (deployed with CR-019) |

## What changed
`Delete_Agreement_File` (record-triggered flow on ContentVersion, created 2026-09-23 by Billy Marlin, version 5 active) → **deactivated** with `FlowDefinition activeVersionNumber = 0`. The flow and its versions are kept.

## Rollback
Activate version 5 in Flow Builder.

## Note
Files deleted before this change may still be in the Recycle Bin (kept 15 days). They have not been restored.
