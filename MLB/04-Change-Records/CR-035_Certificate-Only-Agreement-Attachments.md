# CR-035 — Only certificate files attached to vendor agreements

| | |
|---|---|
| **Change ID** | CR-035 |
| **Date** | 2026-10-21 |
| **Requirement** | [REQ-018](../03-Requirements/REQ-018_Certificate-Only-Agreement-Attachments.md) |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV000000Ao8PSAS (Apex, 5 of 5 tests, 100% coverage); Upload_Certificate flow deployed the same day |
| **Status** | Deployed to sandbox, confirmed by user |

## What changed
| Component | Type | Action |
|---|---|---|
| `CertificateAttachmentService` / `…Test` | Apex (invocable + Queueable) | Created. Copies the passed ContentVersions to Contact attachments "[Category] title.ext"; deletes the earlier attachment of the same category; `backfill()` for existing contacts. |
| `Upload_Certificate` | Screen flow | Action `Copy_Certificates_To_Attachments` after the file category loop (contactId, varVersionIds, varCategory). |
| Adobe template row 0000031 (`echosign_dev1__Attachment_Template__c` a0oiV0000000D0TQAU) on template "Vendor Activation Agreement" (a0kiV0000000IZdQAM) | Data (Adobe configuration) | Source type **Files → Attachments** (Document from Master Object, All Documents). |
| Existing vendor contacts | Data | Backfill: 29 certificate attachments created for 18 Vendor / Sales Vendor contacts. |

## Approach considered and rejected
Adobe runtime variables (pass certificate file IDs from the Send Agreement button) worked for one file but Adobe rejects an empty variable ("No value specified for runtime variable") and comma- or semicolon-separated IDs. See CON-016. All test drafts, temporary template rows and the temporary button URL were removed.

## Verification
Send Agreement on "Vendor Contact" (W-9 from the component, signed PDF added to Files): the draft held only the generated agreement and "[W-9] …pdf". Draft deleted unsent. See ATR-002 TC-018-01 to 04.

## Rollback
Set template row 0000031 back to Source type Files, remove the action from Upload_Certificate. Attachments can stay.

## Production steps (not deployable)
1. Change template row 0000031 to Attachments.
2. Run `CertificateAttachmentService.backfill()` for Vendor and Sales Vendor contacts.
