# CR-006 — Ticket Office email: three triggering rules and the Agreement Status block

| | |
|---|---|
| **Change ID** | CR-006 |
| **Date** | 2026-10-06 |
| **Requirement** | [REQ-003](../03-Requirements/REQ-003_Ticket-Office-Email-Triggering-Conditions.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000007lVISAY (earlier attempts failed on component access level, attribute naming and a too-long entry formula; all fixed) |

## What changed
| Component | Type | Action |
|---|---|---|
| `Adobe_Agreement_Notify_Ticket_Office` | Flow | Rebuilt: short entry criteria and a Decision with three outcomes. Formulas `frmAgreementTotal`, `frmManagerApprovedOrDeclined`, `frmSentAt50kOrMore`, `frmCustomerSignedOrDeclined`. |
| `TicketOfficeAgreementStatusCtrl` + `TicketOfficeAgreementStatusCtrlTest` | Apex | Created: reads the Opportunity's latest Adobe agreement status |
| `TicketOfficeAgreementStatus` | Visualforce component (global) | Created: status block inside the email |
| `Ticket_Office_Agreement_Details` | Email template | Status block added; footer reworded to be neutral |

## Verification
- Seven status transitions simulated with a forced rollback and a debug trace: every one routed as expected.
- Tests: 2 of 2 passed, 100% coverage.
