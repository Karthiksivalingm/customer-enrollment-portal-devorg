# REQ-018 — Only certificate files attached to vendor agreements

| | |
|---|---|
| **ID** | REQ-018 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-21) |
| **Requested** | 2026-10-21 (client call) |
| **Related** | CR-035 · TECH-010 · CON-016 · REQ-006 · ATR-002 · MTC-002 |

## Business need
When **Send Agreement** is used on a vendor contact, Adobe Sign attached every file on the Contact. Only files uploaded through the **Upload Certificate** component should be attached; files a user adds directly to the Contact's Files must not be.

## Scope
- **In:** Upload Certificate flow; Vendor Activation Agreement template (Adobe Sign); Vendor Contact and Sales Vendor contacts.
- **Out:** the generated agreement document itself; signed-document handling.

## Functional behaviour
- Each certificate uploaded through Upload Certificate is also saved on the Contact as an attachment named "[Category] file name" (for example "[W-9] license.pdf").
- A new upload replaces the earlier attachment of the same category (COI, W-9, Food Service).
- Send Agreement attaches the generated agreement document plus the Contact's certificate attachments. Files added directly through Files are not attached.

## Acceptance criteria
1. Uploading a certificate through the component creates the matching "[Category]" attachment on the Contact.
2. Send Agreement on a Contact with a certificate and a directly added file attaches only the certificate (and the generated agreement document).
3. Existing vendor contacts keep their certificates on new agreements (backfill).

## Assumptions
- Certificates stay within normal file sizes; the copy runs asynchronously, so files up to roughly 12 MB can be copied.

## Open questions
None.
