# REQ-010 — Contact status from the latest agreement (from Draft) and the Send Agreement button

| | |
|---|---|
| **ID** | REQ-010 |
| **Status** | ✅ Built and deployed to sandbox (utdev) |
| **Requested** | 2026-10-08 |
| **Related** | CON-007 · CR-020 · CR-021 · TECH-004 |

## 10.1 Which agreement syncs when a Contact has several
- **Question raised:** with two agreements on one contact, which status should show?
- **Decision:** the **most recently created** agreement's status. Status changes on older agreements are ignored.

## 10.2 Show the new agreement's status from creation
- **Decision:** when a new agreement is created, show its status straight away, **Draft or whatever it is**.
- **New values:** Draft, Pre-Send, Send in Progress, Created, Approved.
- **Full order:** Document Pending → Document Uploaded → Ready to Send → Draft → Pre-Send → Send in Progress → Created → Out for Approval → Approved → Out for Signature → Signed → Cancelled / Declined → Expired.

## 10.3 Send Agreement button
- **Decision:** show it for every status from **Ready to Send onward**; hide it for Document Pending and Document Uploaded.
- The client's words were "except document pending and document created". Interpreted as **Document Uploaded**, and confirmed in the response.

## Acceptance criteria (tested)
| Step | Contact status |
|---|---|
| A created | Draft |
| A signed | Signed |
| New B created | Draft (new agreement takes over) |
| B → Pre-Send → Out for Approval → Out for Signature | follows B |
| Older A → Expired | stays Out for Signature |
