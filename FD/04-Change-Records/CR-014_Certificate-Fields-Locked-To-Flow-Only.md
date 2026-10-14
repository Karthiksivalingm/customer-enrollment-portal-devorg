# CR-014 — Certificate checkboxes locked: only the upload flow can set them

| | |
|---|---|
| **Change ID** | CR-014 |
| **Date** | 2026-10-07 |
| **Requirement** | [REQ-008](../03-Requirements/REQ-008_Lock-Certificate-Fields-To-Flow-Only.md) |
| **Org** | utdev sandbox |
| **Deploy IDs** | 0AfiV00000085s9SAA · 0AfiV00000085wzSAA · 0AfiV000000866fSAA (+ a validation rule update deploy) |

## What changed
| Change | Method | Detail |
|---|---|---|
| `Upload_Certificate` flow runs in system context | Deploy 0AfiV00000085s9SAA | `runInMode = SystemModeWithoutSharing` |
| FLS read-only on `COI_Collected__c`, `W_9_Collected__c`, `Food_Services_Certificate_Collected__c` | **Direct DML on FieldPermissions** (84 of 96 rows) and an Admin profile metadata deploy (0AfiV00000085wzSAA) | 29 profiles. 4 profiles on Identity / Integration licences couldn't change but have no Contact access anyway. |
| `Contact.Certificate_Flow_Update__c` | Deploy 0AfiV000000866fSAA | **Created**: hidden checkbox, no FLS for any profile |
| `Contact.Certificate_Fields_Flow_Only` | Validation rule (same deploy, then updated) | Blocks manual changes and new records with any box ticked |
| `Upload_Certificate` flow | Same deploy | Formula `frmToggleCertificateFlowUpdate`; marker flipped in `Mark_COI`, `Mark_Food`, `Mark_W9` |

## Verification
Check-only test as System Administrator: manual tick blocked, flow-style update saved, manual untick blocked, other edits saved, pre-ticked creation blocked.

## Production note
The FLS changes are **not** in the metadata files. Repeat them in production when this is deployed there.
