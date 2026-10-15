"""Retrieve manifest/package.xml from the verified UTDEV in manageable batches.

Usage (from Epicare/):
  python scripts/retrieve.py                    all batches
  python scripts/retrieve.py --batch code ui    selected batches
  python scripts/retrieve.py --baseline         allow writing into a force-app that has never been committed

Safety:
  * Verifies the org before every batch (through projlib.verify_org), and always passes --target-org.
  * Refuses to run when tracked files under force-app/ have uncommitted changes (they would be overwritten),
    or, unless --baseline, when untracked source files exist.
  * Read-only against the org. Retries each failed batch up to 3 times.
Results (component list, warnings) are saved to .project-state/retrieve/<batch>.json and summarised for
scripts/check_retrieval.py.
"""
import argparse
import json
import os
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import projlib  # noqa: E402

NS = "{http://soap.sforce.com/2006/04/metadata}"
BATCHES = {
    "code": ["ApexClass", "ApexTrigger", "ApexPage", "ApexComponent", "LightningComponentBundle",
             "AuraDefinitionBundle", "StaticResource", "LightningMessageChannel", "CustomLabels"],
    "automation": ["Flow", "Workflow", "ApprovalProcess", "AssignmentRules", "AutoResponseRules", "EscalationRules",
                   "EntitlementProcess", "MilestoneType", "CustomNotificationType", "DuplicateRule", "MatchingRules"],
    "datamodel": ["CustomObject", "GlobalValueSet", "SharingRules", "CustomMetadata", "CustomPermission"],
    "ui": ["FlexiPage", "Layout", "CustomTab", "CustomApplication", "Letterhead", "ReportType", "EmailTemplate",
           "Report", "Dashboard"],
    "routing": ["Queue", "QueueRoutingConfig", "ServiceChannel", "PresenceUserConfig", "CallCenter", "Group", "Role",
                "NamedCredential", "ExternalCredential", "RemoteSiteSetting", "ExternalServiceRegistration", "ConnectedApp"],
    # Profiles and permission sets only contain permissions for components retrieved in the same request.
    "access": ["Profile", "PermissionSet", "PermissionSetGroup", "ApexClass", "ApexPage", "CustomObject", "CustomTab",
               "CustomApplication", "Layout", "CustomPermission", "ExternalCredential"],
}
OUT_DIR = os.path.join(projlib.PROJECT_DIR, ".project-state", "retrieve")


def manifest_members():
    root = ET.parse(os.path.join(projlib.PROJECT_DIR, "manifest", "package.xml")).getroot()
    out = {}
    for t in root.findall(NS + "types"):
        out[t.find(NS + "name").text] = [m.text for m in t.findall(NS + "members")]
    return out, root.find(NS + "version").text


def write_batch_manifest(name, types, members, version):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', '<Package xmlns="http://soap.sforce.com/2006/04/metadata">']
    for t in types:
        if members.get(t):
            lines.append("    <types>")
            lines += [f"        <members>{m.replace('&', '&amp;')}</members>" for m in members[t]]
            lines += [f"        <name>{t}</name>", "    </types>"]
    lines += [f"    <version>{version}</version>", "</Package>"]
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, f"{name}-package.xml")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
    return path


def guard_local_work(baseline):
    root = projlib.repo_root()
    src = projlib.project_prefix() + "force-app/"
    modified = subprocess.run(["git", "diff", "--name-only", "HEAD", "--", src], cwd=root, capture_output=True,
                              text=True).stdout.split()
    if modified:
        projlib.fail(f"{len(modified)} tracked source file(s) have uncommitted changes (e.g. {modified[0]}). "
                    "Commit or set them aside first; retrieval would overwrite them.")
    untracked = subprocess.run(["git", "ls-files", "--others", "--exclude-standard", "--", src], cwd=root,
                               capture_output=True, text=True).stdout.split()
    if untracked and not baseline:
        projlib.fail(f"{len(untracked)} untracked source file(s) exist (e.g. {untracked[0]}). Commit them first, "
                    "or pass --baseline for the initial retrieval.")


def run_batch(name, manifest_path, alias):
    sf = projlib._sf_executable()
    for attempt in range(1, 4):
        projlib.verify_org()
        proc = subprocess.run([sf, "project", "retrieve", "start", "--manifest", manifest_path, "--target-org", alias,
                               "--ignore-conflicts", "--wait", "60", "--json"], cwd=projlib.PROJECT_DIR, capture_output=True,
                              text=True, encoding="utf-8", errors="replace")
        try:
            data = json.loads(proc.stdout)
        except ValueError:
            data = {"status": 1, "message": proc.stderr.strip()[:500]}
        result = data.get("result") or {}
        ok = data.get("status") == 0 and result.get("status", "Succeeded") in ("Succeeded", "SucceededPartial")
        if ok:
            files = result.get("files", [])
            msgs = result.get("messages") or []
            msgs = msgs if isinstance(msgs, list) else [msgs]
            summary = {
                "batch": name, "attempts": attempt, "timestamp": projlib.now_local(), "status": result.get("status", "Succeeded"),
                "components": sorted({(f.get("type"), f.get("fullName")) for f in files if f.get("state") != "Failed"}),
                "failed": [{"type": f.get("type"), "fullName": f.get("fullName"), "error": f.get("error")}
                           for f in files if f.get("state") == "Failed"],
                "warnings": [m.get("problem", str(m)) if isinstance(m, dict) else str(m) for m in msgs],
            }
            os.makedirs(OUT_DIR, exist_ok=True)
            with open(os.path.join(OUT_DIR, f"{name}.json"), "w", encoding="utf-8") as fh:
                json.dump(summary, fh, indent=1)
            return summary
        print(f"  batch {name} attempt {attempt} failed: {data.get('message', '')[:300]}", file=sys.stderr)
        time.sleep(10 * attempt)
    summary = {"batch": name, "attempts": 3, "timestamp": projlib.now_local(), "status": "Failed",
               "error": data.get("message", "")[:1000], "components": [], "failed": [], "warnings": []}
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, f"{name}.json"), "w", encoding="utf-8") as fh:
        json.dump(summary, fh, indent=1)
    return summary


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch", nargs="*", choices=list(BATCHES))
    ap.add_argument("--baseline", action="store_true")
    a = ap.parse_args()
    guard_local_work(a.baseline)
    cfg = projlib.load_config()
    ident = projlib.verify_org(cfg)
    print(f"Org verified: {ident['organizationName']} ({ident['orgId']}), sandbox={ident['isSandbox']}")
    os.makedirs(OUT_DIR, exist_ok=True)
    members, version = manifest_members()
    covered = {t for ts in BATCHES.values() for t in ts}
    missing = sorted(set(members) - covered)
    if missing:
        projlib.fail("manifest types not assigned to any batch: " + ", ".join(missing))
    failed = False
    for name in a.batch or list(BATCHES):
        path = write_batch_manifest(name, BATCHES[name], members, version)
        started = time.time()
        s = run_batch(name, path, ident["alias"])
        failed |= s["status"] == "Failed"
        print(f"  {name:11} {s['status']:16} {len(s['components']):5} components  {len(s['failed'])} failed  "
              f"{len(s['warnings'])} warnings  ({int(time.time() - started)}s, attempts {s['attempts']})", flush=True)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    try:
        main()
    except projlib.ProjectError as exc:
        projlib.fail(str(exc))
