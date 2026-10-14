# REQ-006 — Vendor Contact certificate reminder and document status

| | |
|---|---|
| **ID** | REQ-006 |
| **Status** | ✅ Built and deployed to sandbox (utdev); rules later changed by REQ-009 |
| **Requested** | 2026-10-07 |
| **Related** | REQ-007 · REQ-008 · REQ-009 · CR-012 · CR-015 · CR-017 · TECH-004 |

## Business need
Every time a user opens a vendor Contact, remind them which certificates still have to be uploaded for that Account Type. Track progress in **Agreement Status** automatically.

## Decisions taken with the client
| Topic | Decision |
|---|---|
| Certificates by Account Type (original) | Food and Beverage: Food Service + W-9. Non-Profit: COI + W-9. Sales Activation: W-9. **Changed by REQ-009.** |
| Status values handled | **Document Pending** and **Document Uploaded** only. *Ready to Send* stays with the existing Vendor Activation flow. |
| Reminder style | Banner on the page **and** a popup toast when the page opens |
| Page | The page used by Vendor Contacts: `Contact_Record_Page_Three_Column` (Sales and Sales Console app default) |

## Functional behaviour
- **Banner:** lists each certificate as Uploaded or Pending, shows the Agreement Status, and has an **Upload Certificate** button that opens the existing Upload Certificate flow.
- **Popup:** a warning toast on page open while required certificates are missing.
- **Status:** Document Pending until all required certificates are collected, then Document Uploaded.
- **Button removed** (2026-10-08): no button once all required certificates are uploaded. The "Upload another certificate" button was removed.

## Acceptance criteria
- The banner and popup show only when certificates are missing.
- Status moves Pending → Uploaded as certificates arrive (tested for every type).
- *Ready to Send* is never overwritten.

## Open questions
- A one-time update of existing vendor contacts with a blank status (offered, not yet approved).
