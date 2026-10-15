---
id: CF-002
date: 2026-10-15
title: Aura site ExperienceBundles not retrievable
status: Open
event_key: cf-experiencebundle-retrieve-2026-10-15
---

# CF-002 — Aura site ExperienceBundles not retrievable

| Field | Value |
|---|---|
| **Conflict ID** | CF-002 |
| **Discovered** | 2026-10-15 14:05 UTC+05:30 (batch `06-experience`) |
| **Related requirement / change** | Initial retrieval — [2026-10-15 retrieval report](../07-Technical-Documents/Retrieval/2026-10-15-Initial-Retrieval.md) |
| **Status** | Open (one of four components resolved; three need an org setting decision) |

## Error message and evidence
```
sf project retrieve start --manifest manifest/batches/06-experience.xml --target-org Arizona
Status: Succeeded (10 created, 4 failed)
ExperienceBundle Marketing_Landing_Pages1: Entity of type 'ExperienceBundle' named 'Marketing_Landing_Pages1' cannot be found
Provider_Portal_Member_Portal1 wasn't retrieved because ExperienceBundle isn't enabled for Aura sites. To enable ExperienceBundle, in Setup, select Enable ExperienceBundle Me[tadata API] ...
MemberDocuments1 wasn't retrieved because ExperienceBundle isn't enabled for Aura sites. ...
Client_Portal1 wasn't retrieved because ExperienceBundle isn't enabled for Aura sites. ...
```

## Affected components
- ExperienceBundle `Provider_Portal_Member_Portal1`, `MemberDocuments1`, `Client_Portal1` (Aura sites).
- ExperienceBundle `Marketing_Landing_Pages1` (LWR site; see resolution).

## Investigation performed
| Date | Step | Finding |
|---|---|---|
| 2026-10-15 | `sf org list metadata --metadata-type DigitalExperienceBundle` | Lists `site/Marketing_Landing_Pages1` (and the CMS workspace `marketing/Default_Content_Workspace`) |
| 2026-10-15 | `sf project retrieve start --metadata "DigitalExperienceBundle:site/Marketing_Landing_Pages1"` | Succeeded, 75 files created |
| 2026-10-15 | Read the three Aura-site messages | The org setting *Enable ExperienceBundle Metadata API* (Setup → Digital Experiences → Settings) is off |

## Confirmed root cause
- `Marketing_Landing_Pages1`: **confirmed** — it is an LWR site, whose metadata type is `DigitalExperienceBundle`, not `ExperienceBundle`.
- Three Aura sites: **confirmed** by the Metadata API message — the org setting *Enable ExperienceBundle Metadata API* is disabled.

## Resolution
- `Marketing_Landing_Pages1`: **resolved.** `scripts/build-manifest.js` now retrieves LWR sites as `DigitalExperienceBundle site/<name>`
  and drops their ExperienceBundle entry; `config/arizona-project.json` includes `DigitalExperienceBundle` (prefix `site/`).
- Three Aura sites: **not resolved.** Turning on the setting is an org configuration change and was **not** made (not authorized).
  The sites' Network and CustomSite metadata were retrieved; page-level content (pages, theme, components on pages) is not in source.
  Options for the user: (a) authorize enabling *Enable ExperienceBundle Metadata API* in the Arizona sandbox and re-run batch 06;
  (b) leave page content documented from Experience Builder only.

## Files and components changed
- `scripts/build-manifest.js`, `config/arizona-project.json`, `manifest/batches/06-experience.xml`, `manifest/package.xml`
- `force-app/main/default/digitalExperiences/site/Marketing_Landing_Pages1/` (retrieved)

## Tests and verification
| Date | Test / check | Result |
|---|---|---|
| 2026-10-15 | Retrieve `DigitalExperienceBundle:site/Marketing_Landing_Pages1` | Succeeded (75 files) |
| 2026-10-15 | Rebuilt manifest lists 3 ExperienceBundles + 1 DigitalExperienceBundle | Verified |

## Remaining risks and follow-up actions
- Changes made in Experience Builder for the three Aura sites are not tracked in Git until the setting is enabled (decision needed).

## History
| Date | Change |
|---|---|
| 2026-10-15 | Conflict recorded; LWR site resolved by retrieving as DigitalExperienceBundle; Aura sites awaiting a decision. |
