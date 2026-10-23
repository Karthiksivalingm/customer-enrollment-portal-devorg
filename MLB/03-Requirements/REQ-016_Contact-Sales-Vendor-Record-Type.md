# REQ-016 — Contact "Sales Vendor" record type

| | |
|---|---|
| **ID** | REQ-016 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-21) |
| **Requested** | 2026-10-21 (client call); certificate features and Sales Manager access added the same day |
| **Related** | CR-033 · CR-036 · TECH-010 · CON-018 · REQ-006 to REQ-010 · ATR-002 · MTC-002 |

## Business need
Sales vendors need their own Contact record type, cloned from **Vendor Contact**. On 2026-10-23 the client decided the certificate and agreement process runs **only on Sales Vendor** contacts; Vendor Contact no longer gets it.

## Scope
- **In:** new Contact record type `Sales_Vendor`; access for sales reps (Ticket Sales profile), System Administrators and Sales Managers; all certificate and agreement features, on Sales Vendor only.
- **Out:** changes to the Vendor Contact record type itself.

## Functional behaviour
- **Sales Vendor** record type: active, same picklist values as Vendor Contact, Contact-Vendor page layout.
- Available to the **Ticket Sales** and **System Administrator** profiles and, through the MLB Sales Manager Access permission set, to all **Sales Managers**. It is not the default record type.
- Certificate features work **only for Sales Vendor** contacts (Vendor Contact, Business Contact and Internal get none of them):
  - certificate reminder banner and pop-up, with the Upload Certificate button
  - Agreement Status set to Document Pending / Document Uploaded from the collected certificates
  - Create Agreement and Send Agreement buttons and the Vendor Information section on the Contact page
  - Agreement Status kept in step with the latest Adobe Sign agreement
  - certificate checkboxes locked to the Upload Certificate flow; only certificate files attached to agreements (REQ-018)

## Acceptance criteria
1. Sales reps, administrators and Sales Managers can create a Sales Vendor contact.
2. A new Sales Vendor contact on a vendor-type Account gets Agreement Status = Document Pending and shows the certificate banner with the Upload Certificate button.
3. A new Adobe agreement for a Sales Vendor contact updates the contact's Agreement Status.
4. A Vendor Contact shows no certificate banner and no Upload Certificate, Create Agreement or Send Agreement buttons.

## Assumptions
- The Contact page filters test RecordType = Sales_Vendor exactly (since CR-036).

## Open questions
- Whether the 18 existing Vendor Contacts should move to Sales Vendor so they keep the certificate and agreement features (CON-012 item 14).
