# CR-015 — Banner: no upload button once required certificates are uploaded

| | |
|---|---|
| **Change ID** | CR-015 |
| **Date** | 2026-10-08 |
| **Requirement** | [REQ-006](../03-Requirements/REQ-006_Vendor-Contact-Certificate-Reminder-And-Document-Status.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000008AdJSAU |

## What changed
`certificateReminder` LWC: removed the "Upload another certificate" button. The Upload Certificate button now shows only while a required certificate is missing.
