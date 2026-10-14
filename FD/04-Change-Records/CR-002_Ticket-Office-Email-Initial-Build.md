# CR-002 — Ticket Office email: initial build

| | |
|---|---|
| **Change ID** | CR-002 |
| **Date** | 2026-10-05 / 06 |
| **Requirement** | [REQ-002](../03-Requirements/REQ-002_Ticket-Office-Notification-Email.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000007a0NSAQ (the first attempt failed because `TEXT()` was used on picklists in Visualforce; fixed) |
| **Status** | Deployed to sandbox; parts later replaced by CR-006, CR-009 and CR-016 |

## What changed
| Component | Type | Action |
|---|---|---|
| `unfiled$public/Ticket_Office_Agreement_Details` | Email template (Visualforce) | Created |
| `Opportunity.Ticket_Office_Agreement_Details` | Workflow email alert | Created. Existing Opportunity workflow alerts and field updates kept. |
| `Adobe_Agreement_Notify_Ticket_Office` | Flow (record-triggered, after save, on `echosign_dev1__SIGN_Agreement__c`) | Created. First version fired only on Out for Approval → Out for Signature. |

## Verification
The template was rendered for all four types from the sandbox with `Messaging.renderStoredEmailTemplate`; nothing was sent. Membership seat rows were tested with temporary rows in a rolled-back transaction.

## Rollback
Deactivate and delete the flow, then delete the alert and the template.
