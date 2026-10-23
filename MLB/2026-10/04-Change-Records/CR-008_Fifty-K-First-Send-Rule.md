# CR-008 — $50k notification only on the first send

| | |
|---|---|
| **Change ID** | CR-008 |
| **Date** | 2026-10-07 |
| **Requirement** | [REQ-003](../03-Requirements/REQ-003_Ticket-Office-Email-Triggering-Conditions.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000007nAUSAY |

## What changed
Flow `Adobe_Agreement_Notify_Ticket_Office`, formula `frmSentAt50kOrMore`. It now fires only when:
- the **prior** status is Draft, Pre-Send, Send in Progress, Created or blank, and
- the new status is Out for Approval or Out for Signature, and
- the agreement value is 50,000 or more.

## Verification
Ten scenarios simulated with a forced rollback:
- first send from Draft or Created → email
- re-entering approval → no email
- under $50k → no email
