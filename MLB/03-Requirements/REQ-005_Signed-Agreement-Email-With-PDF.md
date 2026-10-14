# REQ-005 — Attach the signed PDF to the "customer signed" email

| | |
|---|---|
| **ID** | REQ-005 |
| **Status** | ✅ Built and deployed to sandbox (utdev); awaiting a real end-to-end signature |
| **Requested** | 2026-10-08 |
| **Related** | REQ-003 · CR-016 · TECH-002 |

## Business need
When an **Opportunity** agreement is signed, the Ticket Office email should include the signed document from the Adobe agreement. **Only for the signed email**; the other events are unchanged.

## Functional behaviour
- **Event:** status → Signed, on an Opportunity agreement.
- **What's sent:** the same Marlins email, to the same recipients, with **"<agreement> - signed.pdf"** attached.
- **Timing:** the email waits **1 minute**, because Adobe saves the PDF a few seconds around the status change. If the PDF isn't there yet, it retries every 2 minutes, up to 4 tries. If it never appears, the email is sent **without** the attachment, so the Ticket Office is still informed.
- **Address:** the Ticket Office address for this email comes from Custom Label `Ticket_Office_Email`.

## Scope
- **In:** Opportunity agreements only.
- **Out:** Vendor Activation (Contact) agreements. They get no Salesforce email; Adobe emails the signed copy itself.

## Acceptance criteria (tests passed)
1. The email attaches the *signed* PDF, not the *approved* one.
2. It goes to the Ticket Office and the Sales Manager.
3. With no PDF, the email is still sent.
4. Approved, declined and $50k events still use the standard alert (routing verified).

## Open questions
- Confirm in a real Adobe signature that the PDF arrives within the retry window.
