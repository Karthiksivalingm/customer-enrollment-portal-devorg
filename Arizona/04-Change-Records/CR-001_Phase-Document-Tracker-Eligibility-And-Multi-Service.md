# CR-001 — Phase Document Tracker: eligibility filtering and multiple services

| Field | Value |
|---|---|
| **Change ID** | CR-001 |
| **Org** | Arizona sandbox (alias `Arizona`, Azlionhearts, Org ID `00DWH000005wW9V2AU`). Not production. |
| **Component** | Lightning Web Component `phaseDocumentTracker` ([source](../force-app/main/default/lwc/phaseDocumentTracker/)) |
| **Changed in the org by** | Sandip Patel (org user), directly in the sandbox |
| **When (UTC)** | `.html`, `.css`, `.js-meta.xml`: 2026-10-21 11:20:58 (deploy `0AfWH00000EdGkn0AF`, Succeeded, 1 component). `.js`: **2026-10-22 07:00:02** (no matching Metadata API deployment; saved directly in the org) |
| **Recorded in Git** | 2026-10-22, retrieved from the sandbox and committed with this record |
| **Related requirement** | TO BE CONFIRMED (no REQ document exists for this change) |
| **Status** | Changed in sandbox; not verified by us; not in production |

## What changed

Compared with the version retrieved on 2026-10-15 (Git commit `990547b8`). Intermediate saves between 15 and 22 October
(about 25 single-component deployments on 21 October) are not individually recorded here; this record describes the net change.

### `phaseDocumentTracker.js` (1,381 → 1,607 lines; saved 2026-10-22)

1. **Category filtering by Contact type (eligibility matrix).** New constants `DIVISION_ONLY_TOKENS`, `PARENT_PROVIDER_TOKEN`,
   `CONTRACT_KEY_MAP`, `TOKEN_ALIASES` and getters `isDivisionOnly`, `isParentProvider`, `contractKey`, `canShowDriverItems`,
   `canShowNonDriverItems`, `isPayTaxAllowed`:
   | Division | What the tracker shows |
   |---|---|
   | Member, Tutor | Only the *Based Forms* tab (`filterTabsByDivision`) |
   | Parent Provider | Based Forms; Pay and Tax for **1099 only**; no driver documents or driver forms; Service and Live-In follow the Contact |
   | Provider | Every category follows the Contact (W2 or 1099, Driver or Non-Driver, ATC/HAH/RSP, Live-In) |
   A blank Contact value hides the category that depends on it. Values are normalized (lowercase, letters and digits only;
   legacy "RSH" / "Respite" → `rsp`, "Habilitation" → `hah`; contract "W2" → `w4` key).
2. **Several services per Contact.** The service field is now read as a multi-select (`atc;hah;rsp`). One `@wire` per service for
   `getServiceFormDocuments` and `getServiceAgreementForms` (active only when that service is selected); results kept per service
   (`serviceDocsBySvc`, `serviceFormsBySvc`). New getter `serviceGroups` builds one section per service with its own certification
   and agreement headings (`certificationHeadingFor`, `agreementHeadingFor`). Replaces the single-service `serviceStatusDocs`,
   `serviceAgreementForms`, `serviceFormStatusRows`.
3. **Status normalization.** New `normalizeStatus()` maps raw values (including the `document.` prefix, e.g. `document.completed`)
   to the known status options; rows are *Completed* when the flag is set **or** the normalized status is Completed. Badge classes and
   the Upload / Re-upload label use the normalized status.
4. **Document lists.** Labels renamed (e.g. "- English" suffixes, "I-9" → "I-9 - English", "Client Orientation" → "AZLH Client
   Orientation - English"), lists sorted alphabetically, and new entries such as *Client Orientation - Spanish*, *I-9 - Spanish*,
   *HCBS_Service_Contract - Spanish* and *Member_Opt_Out_Agreement - Spanish* (which replaces *ATC Monitoring Agreement* in one Spanish list).
5. **Refresh** now refreshes every per-service wire. The "Form ready" toast text changed to "Complete and sign the form."

### `phaseDocumentTracker.html` (deployed 2026-10-21)

The service-forms section loops over `serviceGroups`: per service, a certification heading with status rows and an agreement heading
with form rows (213 lines changed). `.css` and `.js-meta.xml` are unchanged in content.

### Observation (not changed)

In the Spanish service list, the entry for page `HCBSServiceContractMemberEs` (a Spanish page) is labelled
**"HCBS Service Contract - English"**. **OPEN QUESTION:** label error, or intended?

## Dependencies

- Calls Apex `PhaseDocumentTrackerController` (`getServiceFormDocuments`, `getServiceAgreementForms` and others). That class was also
  changed in the sandbox on **2026-10-21 06:38 UTC** and has **not** been retrieved into Git yet, so the per-service parameters
  (`atc`, `hah`, `rsp`) cannot be checked against the Apex in this repository.
- Other components changed in the sandbox since 2026-10-15 and not yet in Git: `DynamicFormsController` (2026-10-21),
  `PandaDocService` (2026-10-22), LWCs `dynamicformscontact` and `recordCertificateDocuments` (2026-10-19).

## Verification

| Check | Result |
|---|---|
| Repository copy equals the sandbox source (Tooling API `LightningComponentResource.Source`) | Verified 2026-10-22: all four files identical |
| Deployment `0AfWH00000EdGkn0AF` contents | Verified: `LightningComponentBundle phaseDocumentTracker`, changed, Succeeded |
| Functional test (tabs per division, Pay and Tax per contract, multiple services) | **Not performed** by us. TO BE CONFIRMED by the developer / QA |
| Jest or Apex tests | None exist for this component |

## Rollback

Restore the previous version from Git (`git show 990547b8:Arizona/force-app/main/default/lwc/phaseDocumentTracker/<file>`) and deploy it
to the sandbox — only with the project lead's approval. The Apex controller change (above) would need to be rolled back with it if the
method signatures changed.

## Related documents

- Knowledge Base: [Automation-and-Processes.md §1](../02-Knowledge-Base/Automation-and-Processes.md)
- Component Change History: [07-Technical-Documents/Change-History.md](../07-Technical-Documents/Change-History.md)

## History
| Date | Change |
|---|---|
| 2026-10-22 | Change record created from the sandbox source, Tooling API data and deployment history. |
