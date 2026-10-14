# Metadata Scope

Which Salesforce metadata from the TVM Fullsandbox (`Fullsandbox`, `00DVa000006Eh6TMAS`) is kept in `force-app/main/default/`, and why.

## Ownership
The Fullsandbox is a full copy of the Team Velocity Marketing production org. It is the TVM org, so its **unmanaged** metadata belongs to TVM.
**Managed-package** components (namespaces such as `dfsle` DocuSign, `pi` Pardot/Account Engagement, `maps` Salesforce Maps, `slackv2`,
`Gong`, `JCFS`, `awsac`, `mondayapp`, `sfsp`) belong to their vendors. They are excluded, including their fields on standard objects
(`.forceignore`). TVM components depend on some of them. Those dependencies are recorded in
[Integrations-and-External-Systems.md](../02-Knowledge-Base/Integrations-and-External-Systems.md).

## In scope (retrieved)
Every unmanaged component of these types. The live list is [`manifest/package.xml`](../manifest/package.xml), rebuilt by
`scripts/build_manifest.py`. Discovery counts: [Retrieval/Discovery.md](Retrieval/Discovery.md).

| Area | Types |
|---|---|
| Code | ApexClass (incl. tests), ApexTrigger, ApexPage, ApexComponent, LightningComponentBundle, AuraDefinitionBundle, StaticResource, LightningMessageChannel, CustomLabels |
| Automation | Flow, Workflow, ApprovalProcess, AssignmentRules, AutoResponseRules, EscalationRules, EntitlementProcess, MilestoneType, CustomNotificationType, DuplicateRule, MatchingRules |
| Data model | CustomObject: all unmanaged custom objects, custom settings, custom metadata types, platform events and Knowledge, plus the standard objects that carry unmanaged fields (with their fields, record types, business processes, validation rules, list views, compact layouts, web links); GlobalValueSet, SharingRules, CustomMetadata records, CustomPermission |
| UI | FlexiPage, Layout (in-scope objects), CustomTab, CustomApplication, Letterhead, ReportType, EmailTemplate (referenced by automation) |
| Access | Profile, PermissionSet, PermissionSetGroup, Group, Role |
| Routing, service, telephony | Queue, QueueRoutingConfig, ServiceChannel, PresenceUserConfig, CallCenter |
| Integrations | NamedCredential, ExternalCredential, RemoteSiteSetting, ExternalServiceRegistration, ConnectedApp (definitions only) |

## Out of scope, and why
| Item | Reason | To bring into scope |
|---|---|---|
| Managed-package components | Vendor-owned; cannot be changed | n/a |
| `TouchPoint_Callout` custom metadata records | Hold integration tokens. Values stay in the org only (`.gitignore`, `.forceignore`) | Never; manage in Setup |
| Reports (5,834), dashboards (412), email templates not referenced by automation (≈2,000) | User-authored analytics and content in about 570 folders. TVM ownership of individual folders is not established | Name the folders that belong to TVM development; add them to `build_manifest.py` |
| Content assets (2,768) | Uploaded images and files: content, not configuration | Decision needed |
| Territory models (`East`, `West`) | No source or requirement references them yet | Decision needed |
| Org settings (`Settings` types) | Not yet inventoried | Add the named settings needed by a requirement |
| Business records | Data, not metadata. Exports need separate approval and security controls | Separate approved scope |
| `CustomObject ActionCadence` | Has unmanaged fields, but the Metadata API returns "cannot be found" | Retrieve its fields as `CustomField` if needed |

## Retrieval procedure
1. `git status -- force-app` must be clean (the script refuses otherwise, so local work is not overwritten).
2. `python scripts/build_manifest.py` rebuilds the manifest and discovery report (read-only).
3. `python scripts/retrieve.py` retrieves in batches (code, automation, datamodel, ui, routing, access), verifying the org before each batch
   and retrying failures.
4. `python scripts/check_retrieval.py` compares the manifest with what was returned and writes [Retrieval/Retrieval-Report.md](Retrieval/Retrieval-Report.md).
5. Add a `[bulk: manifest/package.xml]` row to [Change-History.md](Change-History.md) and finish the turn. The auto-commit regenerates the inventories.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Scope defined: unmanaged code + data model (user decision), widened the same day to the full discovery checklist (automation rules, profiles, sharing, routing, telephony, integrations). |
