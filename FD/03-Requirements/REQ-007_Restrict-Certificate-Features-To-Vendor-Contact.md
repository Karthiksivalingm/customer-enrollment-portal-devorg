# REQ-007 — Restrict all certificate features to the Vendor Contact record type

| | |
|---|---|
| **ID** | REQ-007 |
| **Status** | ✅ Fixed and deployed to sandbox (utdev) |
| **Requested** | 2026-10-07 (reported as a bug) |
| **Related** | CON-004 · CR-013 · TECH-004 |

## Business need
Contact has three record types: Business Contact, Internal and Vendor Contact. The buttons, field section, validation and automation must apply **only to Vendor Contact**, so other record types are unaffected.

**Reported symptom:** creating an *Internal* contact failed with an error about Agreement Status "Document Pending".

## Functional behaviour (as fixed)
These are limited to record type **Vendor Contact**:
- Upload Certificate, Create Agreement and Send Agreement buttons
- the Vendor Information field section
- the Certificate Reminder banner (checked on the page and inside the component)
- the document-status flow

## Acceptance criteria (tested)
- Internal and Business contacts on a vendor-type account save without error; status untouched.
- A Vendor Contact still gets Document Pending or Document Uploaded.
