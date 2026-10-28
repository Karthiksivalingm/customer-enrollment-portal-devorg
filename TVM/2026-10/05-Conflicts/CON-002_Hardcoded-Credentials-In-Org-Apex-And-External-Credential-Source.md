# CON-002 — Hardcoded credentials in org Apex and external credential source

| Field | Value |
|---|---|
| **ID** | CON-002 (formerly CF-001) |
| **Found** | 2026-10-14, during the baseline retrieval from Fullsandbox (`00DVa000006Eh6TMAS`) |
| **Related requirement / change** | TVM project setup (baseline retrieval). No REQ yet |
| **Status** | Open. Contained for Git; the org-side fix needs approval |

## Error message and evidence
The source analysis, confirmed by `scripts/secret_scan.py`, found credential values written directly into retrieved org source.
Values were never printed or copied into documents.

```
SECRET CHECK FAILED (values not shown):
  classes/TouchPointMakeAccountPOSTCallout.cls   : Quickbase user token, Hardcoded Authorization header (Apex)
  classes/TouchPointMakeAutoGroupPOSTCallout.cls : Quickbase user token, Hardcoded Authorization header (Apex)
  classes/TouchPointMakeBudgetPOSTCallout.cls    : Quickbase user token, Hardcoded Authorization header (Apex)
  classes/TouchPointMakeCPPOSTCallout.cls        : Quickbase user token, Hardcoded Authorization header (Apex)
  classes/TouchPointMakeContactPOSTCallout.cls   : Quickbase user token, Hardcoded Authorization header (Apex)
  classes/TouchpointAGAPI.cls                    : Quickbase user token, Hardcoded Authorization header (Apex)
  classes/TouchpointAPI.cls                      : Quickbase user token, Hardcoded Authorization header (Apex)
  externalCredentials/fndn_google_ads.externalCredential-meta.xml : Hardcoded Authorization header value (metadata)
```

## Affected components
- Apex: the 7 classes above. They send TouchPoint (Quickbase) callouts from the TouchPoint triggers and Flows.
  See [Integrations-and-External-Systems.md](../../02-Knowledge-Base/Integrations-and-External-Systems.md).
- External credential `fndn_google_ads`: an Authorization header parameter holds a literal value.
- `TouchPoint_Callout__mdt` records `apptoken` and `usertoken`: credentials stored as custom metadata. These were already excluded by design.

## Reproduction steps
1. `python scripts/retrieve.py` (or retrieve the classes above).
2. Temporarily remove the entries from `config/secret-files.json`, then run `python scripts/secret_scan.py --all`. The files are reported.

## Investigation performed
| Date | Step | Finding |
|---|---|---|
| 2026-10-14 | Read-only source analysis of integrations | The Quickbase classes set the `Authorization` header from a string literal. None of them uses the existing `TP` named credential (`callout:TP`) |
| 2026-10-14 | Secret scanner reviewed | The first version did not detect this format. Patterns were added for Quickbase tokens and hardcoded Authorization headers in Apex and metadata |

## Potential causes (suspected, not confirmed)
- The integration was built before the `TP` named credential and `TPAuth` external credential existed, and was never migrated.

## Confirmed root cause
Credentials are hardcoded in source in the org itself (confirmed by scan). Why they were not migrated is not confirmed.

## Resolution
**Containment, done 2026-10-14:**
- The 8 files are listed in [`config/secret-files.json`](../../config/secret-files.json) and git-ignored by `TVM/.gitignore`.
- `scripts/secret_scan.py` blocks them, so they cannot be committed or pushed. They remain in local source for development.
- Nothing containing these values was committed. This was verified before the first TVM commit.

**Permanent fix: not done; needs approval.**
1. Move the callouts to `callout:TP` (the named credential already exists) and remove the literals.
2. Rotate the Quickbase user token and the Google Ads value in the external systems. They are in org source and in any earlier copies.
3. Deploy through a DEP record.
4. Remove the entries from `config/secret-files.json`.

## Files and components changed
- `config/secret-files.json`, `.gitignore`, `scripts/secret_scan.py` (containment only). No Salesforce change.

## Tests and verification
| Date | Test / check | Result |
|---|---|---|
| 2026-10-14 | `git check-ignore` on a listed class | Ignored |
| 2026-10-14 | `python scripts/secret_scan.py --all` (listed files excluded) | Passed |

## Remaining risks and follow-up actions
- The credentials remain readable to anyone with access to Apex source in the org, including in production (INFERENCE: production has the same code).
- Until the code is fixed, these 8 files are not version-controlled. Changes to them must be recorded here and in `2026-10/07-Technical/Change-History.md`.
- Owner decision needed: approve the permanent fix (new REQ) and credential rotation.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Conflict recorded; containment applied. |
