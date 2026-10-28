# CON-002 — NIPR credential stored in custom labels

| Field | Value |
|---|---|
| **ID** | CON-002 (formerly CF-002) |
| **Found** | 2026-10-15, source analysis after the baseline retrieval from UTDEV (`00DWB000008ALkv2AG`) |
| **Related requirement / change** | Epicare project setup. No REQ |
| **Status** | Open. Contained for Git; org-side fix needs approval |

## Error message and evidence
The custom labels `Nipr_username` and `Nipr_password` in `labels/CustomLabels.labels-meta.xml` have non-empty values.
The scanner reported this; values were never printed:
```
SECRET CHECK FAILED (values not shown):
  force-app/main/default/labels/CustomLabels.labels-meta.xml: Credential stored in a custom label
```
Custom labels are readable by any user and any code in the org. They are not a secure store for credentials.

## Affected components
- Custom labels `Nipr_username` and `Nipr_password`.
- INFERENCE: the NIPR integration Apex that reads them: `NiprNPNsearch`, `NiprSSNsearch` and related classes. See
  [Integrations-and-External-Systems.md](../../02-Knowledge-Base/Integrations-and-External-Systems.md).

## Investigation performed
| Date | Step | Finding |
|---|---|---|
| 2026-10-15 | Source analysis of labels and security | Two NIPR credential labels are populated |
| 2026-10-15 | Scanner reviewed | It had no rule for credentials in custom labels. A rule was added |

## Confirmed root cause
The NIPR credential is stored in custom labels in the org (confirmed by scan). Why it was stored there is not confirmed.

## Resolution
**Containment, done 2026-10-15:**
- `labels/CustomLabels.labels-meta.xml` is listed in [`config/secret-files.json`](../../config/secret-files.json) and git-ignored.
- `scripts/secret_scan.py` blocks it. It stays in local source.
- Nothing containing the value has been committed.

**Permanent fix: needs approval.**
1. Move the NIPR credential into a Named Credential / External Credential.
2. Update the Apex that reads it.
3. Rotate the NIPR password.
4. Clear the labels.
5. Deploy through a DEP record.

## Remaining risks and follow-up actions
- The other 4 custom labels (URLs) are not version-controlled while the file is excluded.
- INFERENCE: production likely holds the same labels. Rotation must cover every org that uses them.
- Owner decision needed.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Recorded; containment applied. |
