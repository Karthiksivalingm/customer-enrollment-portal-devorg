# Metadata Scope

Which Salesforce metadata from the Epicare Insurance sandbox (`UTDEV`, `00DWB000008ALkv2AG`) is kept in `force-app/main/default/`, and why.

## Ownership
- **Installed packages:** UTDEV has no managed packages with Epicare-relevant components. Its only namespaced packages are
  Sales Insights (`OIQ`) and Salesforce Connected Apps (`sf_com_apps`); `force`, `standard` and `sfdcInternalInt` are Salesforce-owned.
- **No package-owned components** without a namespace were found (`installedEditable`).
- **Ownership caveat:** two **unmanaged** report packages are installed (GS_Sales_Reports_Dashboards and Salesforce.com CRM Dashboards).
  Reports and dashboards they created are ordinary org metadata and cannot be told apart from Epicare-authored ones.

## In scope (retrieved)
Every unmanaged component of these types, listed by name in [`manifest/package.xml`](../manifest/package.xml), built by
`scripts/build_manifest.py`. Counts per type: [Retrieval/Discovery.md](Retrieval/Discovery.md).

| Area | Types |
|---|---|
| Code | ApexClass (incl. tests), ApexTrigger, LightningComponentBundle, AuraDefinitionBundle, StaticResource, CustomLabels |
| Automation | Flow, AssignmentRules, AutoResponseRules, EscalationRules, CustomNotificationType, DuplicateRule, MatchingRules |
| Data model | CustomObject: unmanaged custom objects and custom metadata types, plus standard objects carrying unmanaged fields, with their fields, record types, validation rules, list views, compact layouts and business processes. Also GlobalValueSet, SharingRules (in-scope objects), CustomMetadata records |
| UI | FlexiPage, Layout (in-scope objects), CustomTab, CustomApplication (non-standard), ReportType |
| Analytics | Report, Dashboard and EmailTemplate in unmanaged **public** folders, with their folders |
| Access | Profile, PermissionSet, PermissionSetGroup (unmanaged), Group, Role |
| Integrations | NamedCredential, ExternalCredential, RemoteSiteSetting, ConnectedApp (definitions only, no secrets) |

## Not in scope
| Item | Reason |
|---|---|
| Reports and dashboards in private or personal folders | Not retrievable through the Metadata API. They appear in the SOQL counts only |
| Content assets (7) | Uploaded files: content, not configuration |
| Platform event subscriber configurations (9) | Platform-managed; not referenced by a requirement yet |
| Layouts and sharing rules of standard objects without unmanaged fields | Standard Salesforce configuration. Add an object when a requirement touches it |
| Omni-Channel, entitlements, territories, sharing sets | Not enabled in this org ("Cannot use … in this organization") |
| Business records | Data, not metadata |

## Procedure
1. Make sure `git status -- Epicare/force-app` is clean.
2. Run `python scripts/build_manifest.py`.
3. Run `python scripts/retrieve.py`.
4. Run `python scripts/check_retrieval.py`.
5. Add a `[bulk: manifest/package.xml]` row to [Change-History.md](Change-History.md).

## History
| Date | Change |
|---|---|
| 2026-10-15 | Scope defined during the Epicare setup. |
