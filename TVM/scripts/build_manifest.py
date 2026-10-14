"""Discover TVM metadata in the verified Fullsandbox org and build manifest/package.xml.

Scope (user decisions 2026-10-14): every unmanaged component of the types below. The org is the
TVM org, so its unmanaged metadata belongs to TVM. Excluded, with reasons in the discovery report:
managed-package components, secret-bearing custom metadata records (config 'secretRecords'),
reports, dashboards, email templates not referenced by retrieved automation, content assets,
territory models and record data.

Usage (from TVM/):  python scripts/build_manifest.py
Read-only against the org (metadata listings and one SOQL query). Writes:
  manifest/package.xml                      the in-scope components, by explicit name
  07-Technical-Documents/Retrieval/Discovery.md       what was discovered per type, and what was excluded and why
"""
import glob
import os
import re
import sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import tvmlib  # noqa: E402

# All unmanaged members of these types are in scope.
ALL_UNMANAGED = [
    # code
    "ApexClass", "ApexTrigger", "ApexPage", "ApexComponent", "LightningComponentBundle",
    "AuraDefinitionBundle", "StaticResource", "LightningMessageChannel",
    # automation
    "Flow", "Workflow", "ApprovalProcess", "AssignmentRules", "AutoResponseRules", "EscalationRules",
    "EntitlementProcess", "MilestoneType", "CustomNotificationType", "DuplicateRule", "MatchingRules",
    # data model
    "GlobalValueSet", "CustomMetadata", "CustomPermission",
    # UI
    "FlexiPage", "CustomTab", "CustomApplication", "Letterhead", "ReportType",
    # access
    "Profile", "PermissionSet", "PermissionSetGroup", "Group", "Role",
    # routing, service and telephony
    "Queue", "QueueRoutingConfig", "ServiceChannel", "PresenceUserConfig", "CallCenter",
    # integrations (definitions only; secrets are never retrievable or stored)
    "NamedCredential", "ExternalCredential", "RemoteSiteSetting", "ExternalServiceRegistration", "ConnectedApp",
]
WILDCARD = ["CustomLabels"]
CUSTOM_SUFFIXES = ("__c", "__mdt", "__kav", "__e", "__b", "__x")
# Listed for the discovery report only.
REPORT_ONLY = {
    "ContentAsset": "Images/files uploaded by users (content, not configuration). Out of scope pending a decision.",
    "Territory2Model": "Territory models: no TVM source or requirement references them yet. Pending a decision.",
    "SharingSet": "", "PlatformEventSubscriberConfig": "",
}
NOT_RETRIEVABLE = {"ActionCadence": "Listed by the org as having custom fields, but the Metadata API returns "
                                    "'Entity of type CustomObject named ActionCadence cannot be found'."}


def listing(alias, mtype):
    try:
        res = tvmlib.sf_json(["org", "list", "metadata", "--target-org", alias, "--metadata-type", mtype]) or []
    except tvmlib.TvmError as exc:
        return {"error": str(exc)}
    return [res] if isinstance(res, dict) else res


def unmanaged(items):
    """Components authored in the org. 'installedEditable' = owned by a package without a namespace (excluded)."""
    return [i for i in items if not i.get("namespacePrefix") and i.get("manageableState") not in ("installed", "installedEditable")]


def package_owned(items):
    return sorted(i["fullName"] for i in items if not i.get("namespacePrefix") and i.get("manageableState") == "installedEditable")


def referenced_email_templates():
    """Email templates named by retrieved automation (workflow alerts, approval/assignment/auto-response/escalation rules)."""
    src = os.path.join(tvmlib.TVM_DIR, "force-app", "main", "default")
    refs = set()
    for folder in ("workflows", "approvalProcesses", "assignmentRules", "autoResponseRules", "escalationRules",
                   "entitlementProcesses"):
        for path in glob.glob(os.path.join(src, folder, "*.xml")):
            with open(path, encoding="utf-8", errors="replace") as fh:
                refs |= set(re.findall(r"<(?:template|emailTemplate|replyToTemplate|notifyCcRecipients)>([^<]+/[^<]+)</", fh.read()))
    return sorted(refs)


def main():
    cfg = tvmlib.load_config()
    ident = tvmlib.verify_org(cfg)
    alias = ident["alias"]
    print(f"Org verified: {ident['organizationName']} ({ident['orgId']}), sandbox={ident['isSandbox']}")

    types = ALL_UNMANAGED + ["CustomObject", "CustomField", "Layout", "SharingRules", "EmailTemplate", "EmailFolder",
                             "EmailTemplateFolder", "ReportFolder", "DashboardFolder"] + list(REPORT_ONLY)
    with ThreadPoolExecutor(max_workers=6) as pool:
        lists = dict(zip(types, pool.map(lambda t: listing(alias, t), types)))

    members, report = {}, []
    secret_prefixes = [os.path.basename(p).replace(".*", "") for p in cfg.get("secretRecords", [])]

    pkg_owned = []

    def note(mtype, items, scope, excluded="", reason=""):
        if isinstance(items, dict):
            report.append(f"| {mtype} | listing failed | | | | {re.sub(r'[|]', '/', items['error'])[:120]} |")
            return
        owned = package_owned(items)
        pkg_owned.extend(f"| {mtype} | `{n}` |" for n in owned)
        managed = len(items) - len(unmanaged(items)) - len(owned)
        reason = "; ".join(x for x in [reason, f"{len(owned)} package-owned without namespace (see below)" if owned else ""] if x)
        report.append(f"| {mtype} | {len(items)} | {managed} | {scope} | {excluded} | {reason} |")

    for mtype in ALL_UNMANAGED:
        items = lists[mtype]
        if isinstance(items, dict):
            note(mtype, items, 0)
            continue
        names = sorted({i["fullName"] for i in unmanaged(items)})
        reason, excluded = "", 0
        if mtype == "CustomApplication":
            std = [n for n in names if n.startswith("standard__")]
            names = [n for n in names if n not in std]
            excluded, reason = len(std), "standard__ apps are Salesforce-owned"
        if mtype == "CustomMetadata":
            sec = [n for n in names if any(n.startswith(g + ".") for g in secret_prefixes)]
            names = [n for n in names if n not in sec]
            excluded, reason = len(sec), "token-bearing records (" + ", ".join(sorted(set(secret_prefixes))) + "): org only"
        if names:
            members[mtype] = names
        note(mtype, items, len(names), excluded or "", reason)

    # Data model: unmanaged custom objects + standard objects carrying unmanaged fields.
    objects = {i["fullName"] for i in unmanaged(lists["CustomObject"]) if i["fullName"].endswith(CUSTOM_SUFFIXES)}
    for f in lists["CustomField"]:
        obj, field = f["fullName"].split(".", 1)
        if "__" not in obj and not f.get("namespacePrefix") and field.count("__") == 1:
            objects.add(obj)
    objects -= set(NOT_RETRIEVABLE)
    members["CustomObject"] = sorted(objects)
    note("CustomObject", lists["CustomObject"], len(objects), "",
         "custom objects + standard objects with unmanaged fields; " +
         "; ".join(f"{k}: {v}" for k, v in NOT_RETRIEVABLE.items()))

    lay = [i["fullName"] for i in unmanaged(lists["Layout"]) if i["fullName"].split("-", 1)[0] in objects]
    members["Layout"] = sorted(lay)
    note("Layout", lists["Layout"], len(lay), len(unmanaged(lists["Layout"])) - len(lay), "layouts of objects outside scope")

    shr = [i["fullName"] for i in unmanaged(lists["SharingRules"]) if i["fullName"] in objects]
    members["SharingRules"] = sorted(set(shr))
    note("SharingRules", lists["SharingRules"], len(members["SharingRules"]),
         len(unmanaged(lists["SharingRules"])) - len(members["SharingRules"]), "objects outside scope")

    tmpl = referenced_email_templates()
    if tmpl:
        members["EmailTemplate"] = sorted(set(tmpl) | {t.split("/", 1)[0] for t in tmpl})
    note("EmailTemplate", [], len(tmpl), "see below",
         "only templates referenced by retrieved automation; the rest pending a scope decision")

    for mtype in WILDCARD:
        members[mtype] = ["*"]
    for mtype, reason in REPORT_ONLY.items():
        items = lists[mtype]
        if isinstance(items, dict) or items:
            note(mtype, items, 0, len(unmanaged(items)) if not isinstance(items, dict) else "", reason)
    for mtype in ("ReportFolder", "DashboardFolder", "EmailTemplateFolder", "EmailFolder"):
        items = lists[mtype]
        note(mtype, items, 0, len(unmanaged(items)) if not isinstance(items, dict) else "",
             "folders only listed; contents pending a scope decision (see counts below)")

    counts = {}
    for label, soql in [("Reports", "SELECT COUNT() FROM Report WHERE NamespacePrefix = null"),
                        ("Dashboards", "SELECT COUNT() FROM Dashboard WHERE NamespacePrefix = null"),
                        ("Email templates", "SELECT COUNT() FROM EmailTemplate WHERE NamespacePrefix = null")]:
        try:
            counts[label] = tvmlib.sf_json(["data", "query", "--target-org", alias, "--query", soql])["totalSize"]
        except (tvmlib.TvmError, KeyError, TypeError):
            counts[label] = "query failed"

    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<Package xmlns="http://soap.sforce.com/2006/04/metadata">']
    for mtype in sorted(members):
        lines.append("    <types>")
        for name in members[mtype]:
            esc = name.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            lines.append(f"        <members>{esc}</members>")
        lines.append(f"        <name>{mtype}</name>")
        lines.append("    </types>")
    lines += [f"    <version>{cfg['salesforce']['apiVersion']}</version>", "</Package>"]
    changed = tvmlib.write_if_changed(os.path.join(tvmlib.TVM_DIR, "manifest", "package.xml"), "\n".join(lines) + "\n")

    total = sum(len(v) for v in members.values() if v != ["*"])
    doc = ["# Metadata discovery — Fullsandbox", "",
           f"_Generated by `scripts/build_manifest.py` from metadata listings of the verified org "
           f"({ident['organizationName']}, `{ident['orgId']}`, sandbox). Rebuild it to refresh._", "",
           f"**In scope: {total} named components** plus all custom labels, written to "
           "[`manifest/package.xml`](../../manifest/package.xml). Scope rules: [Metadata-Scope.md](../Metadata-Scope.md).", "",
           "| Type | Listed in org | Managed (excluded) | In scope | Other exclusions | Notes |",
           "|---|---|---|---|---|---|", *sorted(report), "",
           "## Folder-based analytics and templates (not retrieved; decision pending)", "",
           "| Item | Unmanaged count in org |", "|---|---|", *[f"| {k} | {v} |" for k, v in counts.items()], "",
           "## Package-owned components without a namespace (not retrieved)", "",
           "These come from installed packages that have no namespace (for example flow screen-component and collection-action "
           "packages). They are not TVM-authored and package upgrades replace them, so they are treated as dependencies, not source.", "",
           "| Type | Component |", "|---|---|", *sorted(set(pkg_owned)), "",
           "Reports, dashboards and most email templates are user-authored and numerous. They are not retrieved until the "
           "user confirms which folders belong to the TVM development scope. Email templates referenced by retrieved "
           "automation are retrieved as dependencies."]
    tvmlib.write_if_changed(os.path.join(tvmlib.TVM_DIR, "07-Technical-Documents", "Retrieval", "Discovery.md"), "\n".join(doc) + "\n")
    print(f"{'Wrote' if changed else 'Unchanged'} manifest/package.xml: {total} named members in {len(members)} types")


if __name__ == "__main__":
    try:
        main()
    except tvmlib.TvmError as exc:
        tvmlib.fail(str(exc))
