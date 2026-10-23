# CON-011 — Gaps against 01-Instructions/Coding-Standards.md

| | |
|---|---|
| **ID** | CON-011 |
| **Status** | ⚠ **Open: must be closed before production** |
| **Reference** | [Coding-Standards.md](../../01-Instructions/Coding-Standards.md) · [AI-Workflow.md](../../01-Instructions/AI-Workflow.md) |

| Standard | Current state | Gap |
|---|---|---|
| §5 Tests: positive, negative, **bulk 200**, **no-access user** | `TicketOfficeAgreementStatusCtrlTest` (5 tests) and `TicketOfficeSignedEmailTest` (3 tests) cover positive and negative paths | No bulk-200 test; no no-access-user test |
| §2 Enforce FLS / object access in Apex | Both classes are `without sharing` and read without FLS checks. Reason: they run in email-render and async contexts as the Adobe integration user. | Needs an agreed exception, recorded with the reasoning, or added access checks |
| §7 Second developer review | Not done | Peer review against the review checklist |
| §7 Walk through as the affected profile | Tested as System Administrator and through rolled-back simulations | Click-through as a Sales Rep or vendor user profile |
| §2 Naming convention (`utsCls_` "to be confirmed") | New classes use `TicketOffice*` names | Confirm the naming convention with the team |
| §1 One change, one review | Followed per requirement | — |
| §6 Secrets | No secrets in code. The logo is a public document. | — |
