# REQ-009 — Client demo feedback (2026-10-07): agreement files, status tracking, certificate rules

| | |
|---|---|
| **ID** | REQ-009 |
| **Status** | ✅ Built and deployed to sandbox (utdev) |
| **Requested** | 2026-10-08 |
| **Related** | CON-006 · CR-018 · CR-019 · TECH-004 |

## 9.1 Show all agreement files (don't delete)
- **Need:** only the signed agreement was showing; all agreement files should stay.
- **Cause found:** the `Delete_Agreement_File` flow deleted every file added to an Opportunity unless it was a signed PDF.
- **Behaviour:** that flow is **deactivated** (kept, not deleted, so it can be switched back on). No other file automation was touched.

## 9.2 Track the agreement status on the Contact after sending
- **Need:** after the agreement is sent, store its status in the Contact's Agreement Status.
- **Behaviour:** new values added: Out for Approval, Out for Signature, Signed, Cancelled / Declined, Expired. A new flow copies the Adobe status to the agreement's **Recipient** Vendor Contact. Refined by REQ-010.

## 9.3 Certificate rules changed
| Account Type | COI | W-9 | Behaviour |
|---|---|---|---|
| Food & Beverage | No change | No change | Food Service + W-9 required, as before |
| Non-Profit | **Required** | **Optional** | COI must be uploaded; W-9 can be uploaded or skipped |
| Sales Activation | **Required** | **Optional** | COI must be uploaded; W-9 can be uploaded or skipped |

- The upload screen offers COI for Sales Activation; W-9 is labelled "W-9 (optional)".
- Document Uploaded as soon as COI is in.
- The banner shows W-9 as Optional with an "Upload W-9 (optional)" button.
- Create Agreement is shown once COI is in.

## Acceptance criteria (tested)
- Non-Profit or Sales Activation with COI only → Document Uploaded.
- Sales Activation with W-9 only → Document Pending.
- Contact status follows the Adobe statuses and is not overwritten by later contact edits.
- The delete-file flow has no active version.
