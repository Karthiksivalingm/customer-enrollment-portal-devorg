# REQ-008 — Certificate checkboxes editable only by the upload flow

| | |
|---|---|
| **ID** | REQ-008 |
| **Status** | ✅ Built and deployed to sandbox (utdev) |
| **Requested** | 2026-10-07 |
| **Related** | CON-003 · CR-014 · TECH-004 |

## Business need
`COI_Collected__c`, `W_9_Collected__c` and `Food_Services_Certificate_Collected__c` must be set **only** by the Upload Certificate flow. No user, including administrators, may edit them by hand.

## Functional behaviour
- **Field-level security:** read-only for every profile that could edit them (stops normal users).
- **Validation rule `Certificate_Fields_Flow_Only`:** blocks any manual change, and any new or cloned contact created with a box ticked, for **all users including System Administrators**. Message: *"COI Collected, W-9 Collected and Food Services Certificate Collected are set automatically when a certificate is uploaded. Please use the Upload Certificate button instead of editing these fields."*
- **Flow exception:** the Upload Certificate flow runs in system context and flips a hidden marker field (`Certificate_Flow_Update__c`) in the same save, which lets its update through.

## Acceptance criteria (tested as System Administrator)
| Action | Result |
|---|---|
| Tick W-9 by hand | Blocked |
| Upload flow ticks W-9 | Saved |
| Untick by hand | Blocked |
| Edit any other field | Saved |
| Create a contact with COI ticked | Blocked |

## Note
Any data load or integration that sets these boxes is also blocked, by design.
