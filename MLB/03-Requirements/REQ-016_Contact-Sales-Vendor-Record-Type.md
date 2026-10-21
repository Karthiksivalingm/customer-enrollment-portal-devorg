# REQ-016 — Contact "Sales Vendor" record type

| | |
|---|---|
| **ID** | REQ-016 |
| **Status** | ✅ Built in the sandbox (utdev) and confirmed working by the user ("all good", 2026-10-21) |
| **Requested** | 2026-10-21 (client call); certificate features and Sales Manager access added the same day |
| **Related** | CR-033 · TECH-010 · CON-018 · REQ-006 to REQ-010 · ATR-002 · MTC-002 |

## Business need
Sales vendors need their own Contact record type, cloned from **Vendor Contact**, and they go through the same certificate and agreement process as vendor contacts.

## Scope
- **In:** new Contact record type `Sales_Vendor`; access for sales reps (Ticket Sales profile), System Administrators and Sales Managers; every Vendor Contact certificate feature.
- **Out:** changes to the Vendor Contact record type itself.

## Functional behaviour
- **Sales Vendor** record type: active, same picklist values as Vendor Contact, Contact-Vendor page layout.
- Available to the **Ticket Sales** and **System Administrator** profiles and, through the MLB Sales Manager Access permission set, to all **Sales Managers**. It is not the default record type.
- Certificate features work for Sales Vendor exactly as for Vendor Contact:
  - certificate reminder banner and pop-up, with the Upload Certificate button
  - Agreement Status set to Document Pending / Document Uploaded from the collected certificates
  - Create Agreement and Send Agreement buttons and the Vendor Information section on the Contact page
  - Agreement Status kept in step with the latest Adobe Sign agreement
  - certificate checkboxes locked to the Upload Certificate flow; only certificate files attached to agreements (REQ-018)

## Acceptance criteria
1. Sales reps, administrators and Sales Managers can create a Sales Vendor contact.
2. A new Sales Vendor contact on a vendor-type Account gets Agreement Status = Document Pending and shows the certificate banner with the Upload Certificate button.
3. A new Adobe agreement for a Sales Vendor contact updates the contact's Agreement Status.

## Assumptions
- The Contact page filters treat any record type whose API name contains "Vendor" as a vendor (see CON-018). A future record type with "Vendor" in its name would also get the vendor features.

## Open questions
None.
