"""Discover Epicare metadata in the verified UTDEV org and build manifest/package.xml.

Scope (2026-10-15): every unmanaged component of the types below, plus the reports, dashboards and email
templates in unmanaged public folders. Unmanaged metadata of the Epicare org belongs to Epicare. Excluded, with
reasons in the discovery report: managed-package and package-owned components, secret-bearing custom metadata
records (config 'secretRecords'), content assets, territory models and record data.

Usage (from Epicare/):  python scripts/build_manifest.py
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
import projlib  # noqa: E402

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
    "Territory2Model": "Territory models: no Epicare source or requirement references them yet. Pending a decision.",
    "SharingSet": "", "PlatformEventSubscriberConfig": "",
}
NOT_RETRIEVABLE = {}  # object name -> reason, for objects the Metadata API cannot return by name


def listing(alias, mtype):
    try:
        res = projlib.sf_json(["org", "list", "metadata", "--target-org", alias, "--metadata-type", mtype]) or []
    except projlib.ProjectError as exc:
        return {"error": str(exc)}
    return [res] if isinstance(res, dict) else res


def unmanaged(items):
    """Components authored in the org. 'installedEditable' = owned by a package without a namespace (excluded)."""
    return [i for i in items if not i.get("namespacePrefix") and i.get("manageableState") not in ("installed", "installedEditable")]


def package_owned(items):
    return sorted(i["fullName"] for i in items if not i.get("namespacePrefix") and i.get("manageableState") == "installedEditable")


FOLDERED = {"Report": "ReportFolder", "Dashboard": "DashboardFolder", "EmailTemplate": "EmailTemplateFolder"}


def foldered_members(alias, lists):
    """Folder names + 'Folder/Item' members for folder-based types, from unmanaged public folders."""
    out, notes = {}, {}
    for mtype, ftype in FOLDERED.items():
        folders = [] if isinstance(lists[ftype], dict) else sorted(i["fullName"] for i in unmanaged(lists[ftype]))
        items = []
        with ThreadPoolExecutor(max_workers=6) as pool:
            for res in pool.map(lambda f: projlib.sf_json(["org", "list", "metadata", "--target-org", alias,
                                                            "--metadata-type", mtype, "--folder", f]) or [], folders):
                res = [res] if isinstance(res, dict) else res
                items += [i["fullName"] for i in unmanaged(res)]
        out[mtype] = sorted(set(folders) | set(items))
        notes[mtype] = (len(folders), len(items))
    return out, notes


def referenced_email_templates():
    """Email templates named by retrieved automation (workflow alerts, approval/assignment/auto-response/escalation rules)."""
    src = os.path.join(projlib.PROJECT_DIR, "force-app", "main", "default")
    refs = set()
    for folder in ("workflows", "approvalProcesses", "assignmentRules", "autoResponseRules", "escalationRules",
                   "entitlementProcesses"):
        for path in glob.glob(os.path.join(src, folder, "*.xml")):
            with open(path, encoding="utf-8", errors="replace") as fh:
                refs |= set(re.findall(r"<(?:template|emailTemplate|replyToTemplate|notifyCcRecipients)>([^<]+/[^<]+)</", fh.read()))
    return sorted(refs)


def main():
    cfg = projlib.load_config()
    ident = projlib.verify_org(cfg)
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
            if secret_prefixes:
                excluded, reason = len(sec), "credential-bearing records (" + ", ".join(sorted(set(secret_prefixes))) + "): org only"
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
         "; ".join(f"{k}: {v}" for k, v in NOT_RETRIEVABLE.items()) or "")

    lay = [i["fullName"] for i in unmanaged(lists["Layout"]) if i["fullName"].split("-", 1)[0] in objects]
    members["Layout"] = sorted(lay)
    note("Layout", lists["Layout"], len(lay), len(unmanaged(lists["Layout"])) - len(lay), "layouts of objects outside scope")

    shr = [i["fullName"] for i in unmanaged(lists["SharingRules"]) if i["fullName"] in objects]
    members["SharingRules"] = sorted(set(shr))
    note("SharingRules", lists["SharingRules"], len(members["SharingRules"]),
         len(unmanaged(lists["SharingRules"])) - len(members["SharingRules"]), "objects outside scope")

    fold, fnotes = foldered_members(alias, lists)
    for mtype, names in fold.items():
        if names:
            members[mtype] = names
        report.append(f"| {mtype} | {fnotes[mtype][1]} in {fnotes[mtype][0]} folders | | {len(names)} (incl. folders) | | "
                      "public folders only; private/personal folders are not retrievable |")

    for mtype in WILDCARD:
        members[mtype] = ["*"]
    for mtype, reason in REPORT_ONLY.items():
        items = lists[mtype]
        if isinstance(items, dict) or items:
            note(mtype, items, 0, len(unmanaged(items)) if not isinstance(items, dict) else "", reason)

    counts = {}
    for label, soql in [("Reports", "SELECT COUNT() FROM Report WHERE NamespacePrefix = null"),
                        ("Dashboards", "SELECT COUNT() FROM Dashboard WHERE NamespacePrefix = null"),
                        ("Email templates", "SELECT COUNT() FROM EmailTemplate WHERE NamespacePrefix = null")]:
        try:
            counts[label] = projlib.sf_json(["data", "query", "--target-org", alias, "--query", soql])["totalSize"]
        except (projlib.ProjectError, KeyError, TypeError):
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
    changed = projlib.write_if_changed(os.path.join(projlib.PROJECT_DIR, "manifest", "package.xml"), "\n".join(lines) + "\n")

    total = sum(len(v) for v in members.values() if v != ["*"])
    doc = ["# Metadata discovery — UTDEV", "",
           f"_Generated by `scripts/build_manifest.py` from metadata listings of the verified org "
           f"({ident['organizationName']}, `{ident['orgId']}`, sandbox). Rebuild it to refresh._", "",
           f"**In scope: {total} named components** plus all custom labels, written to "
           "[`manifest/package.xml`](../../manifest/package.xml). Scope rules: [Metadata-Scope.md](../Metadata-Scope.md).", "",
           "| Type | Listed in org | Managed (excluded) | In scope | Other exclusions | Notes |",
           "|---|---|---|---|---|---|", *sorted(report), "",
           "## Org-wide counts (SOQL), including private folders", "",
           "| Item | Unmanaged count in org |", "|---|---|", *[f"| {k} | {v} |" for k, v in counts.items()], "",
           "## Package-owned components without a namespace (not retrieved)", "",
           "These come from installed packages that have no namespace (for example flow screen-component and collection-action "
           "packages). They are not Epicare-authored and package upgrades replace them, so they are treated as dependencies, not source.", "",
           "| Type | Component |", "|---|---|", *(sorted(set(pkg_owned)) or ["| — | none found |"]), "",
           "Reports and dashboards in private folders cannot be retrieved through the Metadata API. Unmanaged packages "
           "without a namespace (for example report/dashboard packs) leave ordinary org metadata that cannot be told "
           "apart from Epicare-authored metadata."]
    projlib.write_if_changed(os.path.join(projlib.PROJECT_DIR, "07-Technical-Documents", "Retrieval", "Discovery.md"), "\n".join(doc) + "\n")
    print(f"{'Wrote' if changed else 'Unchanged'} manifest/package.xml: {total} named members in {len(members)} types")


if __name__ == "__main__":
    try:
        main()
    except projlib.ProjectError as exc:
        projlib.fail(str(exc))
