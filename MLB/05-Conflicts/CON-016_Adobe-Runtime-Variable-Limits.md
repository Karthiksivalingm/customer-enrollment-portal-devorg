# CON-016 — Adobe Sign runtime variables can't express "whatever certificates exist"

| | |
|---|---|
| **ID** | CON-016 |
| **Status** | ✅ Resolved by design choice ([CR-035](../04-Change-Records/CR-035_Certificate-Only-Agreement-Attachments.md)) |
| **Found** | 2026-10-21 |
| **Related** | [REQ-018](../03-Requirements/REQ-018_Certificate-Only-Agreement-Attachments.md) |

## Problem
The Vendor Activation Agreement template attached "Document from Master Object – All Documents – Files", so every Contact file was sent. The template has no filter on file properties, and Adobe **copies** the files (new documents, the Certificate Category is lost), so the agreement's copies can't be filtered afterwards either.

## What was tested (sandbox, all test data removed)
| Option | Result |
|---|---|
| Runtime variable with one ContentVersion ID passed from Send Agreement | ✅ Only that file attached |
| One variable with two IDs, comma-separated | ❌ Empty draft, no recipient or files |
| One variable with two IDs, semicolon-separated | ❌ Same |
| Three variables (COI, W-9, Food) with one left empty | ❌ "No value specified for runtime variable: certFood" |
| Opening the Adobe page directly by URL | ❌ Requires the CSRF token a button click supplies |

## Resolution
Component uploads are also saved as Contact **Attachments**, and the template attaches "Document from Master Object – Attachments". Files added directly to Files never become Attachments.
