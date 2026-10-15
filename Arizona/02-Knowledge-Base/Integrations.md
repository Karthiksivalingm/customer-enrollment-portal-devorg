# Integrations and External Systems

> Credential **names** only; no values are recorded anywhere in this repository.

## Overview

| System | Direction | Mechanism | Auth | Main components | Status |
|---|---|---|---|---|---|
| **PandaDoc** (e-signature) | Outbound + inbound webhook | REST `https://api.pandadoc.com/public/v1` (`PandaDocApi`); `callout:PandaDoc` Named Credential (`NewPandaDocService`); Apex REST `/pandadoc/webhook/*` on the `PandaDocWebhook` site | Outbound: API key from custom label `PandaDoc_API_Key` (`PandaDocApi`) or External Credential `PandaDoc` (header merge formula). Inbound: HMAC-SHA256 signature checked with custom label `PandaDoc_Webhook_Key` | `PandaDocService`, `PandaDocApi`, `PandaDocWebhook`, `PandaDocWebhookTrigger`, `PandaDocEventProcessor`, `NewPandaDocController/Service`, `pandaDoc` LWC, `PandaDoc_Template__mdt` | **VERIFIED** active code |
| **TS Documents** (managed `docb`) | In-org | Apex reads `docb__Document_Builder__c` templates and generates PDFs | — | `TSDocumentService`, `TSTemplateSelector`, `FormWorkflowService` | **VERIFIED** — main PDF path for forms |
| **Google Workspace / Drive** | Outbound | OAuth JWT bearer with domain-wide delegation, token from `https://oauth2.googleapis.com/token`; Drive v3 export | Org certificate `GoogleServiceAccountCert` signs the JWT (`Crypto.signWithCertificate`); service account and impersonated user from `Google_Service_Account_Config__mdt`; scope `drive.readonly` | `GoogleServiceAccountAuth`, `TSDocumentService` (Drive export), `GoogleDriveService`, `PerContactDocumentService`; Remote Sites `GoogleDriveAPI`, `GoogleOAuthToken` | **VERIFIED** partly retired: `GoogleDriveService` / `PerContactDocumentService` call Named Credential `Google_Drive_API`, which does **not** exist in the org |
| **360 SMS** (managed `tdc_tsw`) | Inbound + outbound SMS | Package objects `tdc_tsw__Message__c`, `tdc_tsw__Scheduled_Sms__c` | Package-managed | Flows `Inbound_SMS_Case_creation`, `SMS_Case_Scheduled_SMS`; site `Incoming_SMS` | **VERIFIED** |
| **Pardot / Account Engagement** | Content hosting | Image and link URLs in the reminder email | — | `CertificationExpiryReminderBatch` | **VERIFIED** (hardcoded URLs) |
| **Calendly** | Link only | Booking link in the reminder email | — | `CertificationExpiryReminderBatch` | **VERIFIED** (hardcoded, fixed to `month=2026-07`) |
| CPQ integration user | Unknown | ConnectedApp `CPQIntegrationUserApp` | Unknown | — | **Not retrievable** ([CF-001](../05-Conflicts/2026-10-15-CF-001-connectedapp-cpqintegrationuserapp-cannot-be-retrieved.md)) |

CSP Trusted Site `ArizonaLogo` allows loading the logo in Lightning/portal pages.

## PandaDoc end-to-end (VERIFIED from code)

1. Staff (or the portal) requests a form that has a `PandaDoc_Template__mdt` record. `PandaDocService` creates a document from the template with the Contact
   as recipient and tracks the PandaDoc document ID. (Separately, the record action `pandaDoc` LWC → `NewPandaDocController` /
   `NewPandaDocService` creates documents through `callout:PandaDoc` and inserts a `pandadoc__PandaDocDocument__c` link record.)
   A code comment notes that a **sandbox API key only sends to addresses on the sandbox login's domain**.
2. PandaDoc calls `https://…sandbox.my.salesforce-sites.com/services/apexrest/pandadoc/webhook` (URL hardcoded in `PandaDocApi`).
   [`PandaDocWebhook`](../force-app/main/default/classes/PandaDocWebhook.cls) runs as the **site guest user**: it checks the HMAC signature (401 if invalid),
   parses events, ignores "completed" until the `document_completed_pdf_ready` event, and publishes one `PandaDoc_Webhook__e` per document.
   It returns 500 on failure so PandaDoc keeps the event for retry.
3. [`PandaDocWebhookTrigger`](../force-app/main/default/triggers/PandaDocWebhookTrigger.trigger) enqueues [`PandaDocEventProcessor`](../force-app/main/default/classes/PandaDocEventProcessor.cls)
   (Queueable, callouts, chunks of 5). It maps the PandaDoc status to a Contact status value, only moves the status forward, downloads the completed PDF
   and saves it as a file linked to the Contact (skipping duplicates).
4. Custom permission `PandaDoc_Status_Sync` and permission set `PandaDoc_Webhook_Files` support this path.

## Environment-specific values to change for another org

| Value | Where |
|---|---|
| Webhook URL with the sandbox host | `PandaDocApi` |
| Sandbox-domain email restriction note | `PandaDocService` |
| Calendly and Pardot URLs, branded sender | `CertificationExpiryReminderBatch` |
| SMS template record ID and sender number | Flow `SMS_Case_Scheduled_SMS` |
| PandaDoc keys | Custom labels (not in source) and External Credential `PandaDoc` principal |
| Google certificate and service account | Certificate `GoogleServiceAccountCert` (org), `Google_Service_Account_Config.Default` |

## History
| Date | Change |
|---|---|
| 2026-10-15 | Created from the initial retrieval. |
