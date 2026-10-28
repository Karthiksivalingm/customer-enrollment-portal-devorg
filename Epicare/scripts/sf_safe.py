"""Run a Salesforce CLI command against the verified Epicare org only.

Usage (from Epicare/):
  python scripts/sf_safe.py project retrieve start --manifest manifest/package.xml
  python scripts/sf_safe.py project deploy validate --source-dir force-app/main/default/classes/Foo.cls --test-level RunSpecifiedTests --tests FooTest
  python scripts/sf_safe.py --approved DEP-001 project deploy start --source-dir ...

What it does:
  1. Verifies the alias resolves to the Epicare UTDEV (org ID, username, IsSandbox).
  2. Rejects any --target-org/-o that is not the configured alias, then appends it.
  3. Refuses org-changing commands (real deploys, deletes, data writes, anonymous Apex,
     Flow activation through deploys) unless --approved <ID> names the approval record.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import projlib  # noqa: E402

READ_ONLY_PREFIXES = [
    "project retrieve", "project deploy validate", "project deploy preview", "project deploy report",
    "project retrieve preview", "org display", "org list", "data query", "data export",
    "apex list", "apex get", "apex run test", "apex get test", "sobject describe", "sobject list",
    "limits api display", "package installed list",
]
CHANGING_PREFIXES = [
    "project deploy start", "project deploy quick", "project delete", "data create", "data update",
    "data delete", "data upsert", "data import", "apex run", "org assign", "org create", "org delete",
    "project deploy resume", "data record", "data bulk",
]


def main(argv):
    approved = None
    if argv[:1] == ["--approved"]:
        if len(argv) < 2:
            projlib.fail("--approved needs an approval ID, e.g. DEP-001 or CR-003.")
        approved, argv = argv[1], argv[2:]
    if not argv:
        projlib.fail(__doc__)

    cfg = projlib.load_config()
    alias = cfg["salesforce"]["alias"]
    cmd_text = " ".join(a for a in argv if not a.startswith("-"))

    for i, arg in enumerate(argv):
        if arg in ("--target-org", "-o", "--target-dev-hub", "-v"):
            value = argv[i + 1] if i + 1 < len(argv) else ""
            if value != alias:
                projlib.fail(f"Refused: target '{value}' is not the Epicare org alias '{alias}'.")
        if arg.startswith("--target-org=") and arg.split("=", 1)[1] != alias:
            projlib.fail(f"Refused: target is not the Epicare org alias '{alias}'.")

    is_dry = "--dry-run" in argv or "--check-only" in argv
    changing = any(cmd_text.startswith(p) for p in CHANGING_PREFIXES) and not (
        cmd_text.startswith("project deploy start") and is_dry)
    if cmd_text.startswith("apex run test"):
        changing = False  # Apex tests roll back their own data.
    known = changing or any(cmd_text.startswith(p) for p in READ_ONLY_PREFIXES)
    if not known:
        projlib.fail(f"Refused: 'sf {cmd_text}' is not on the Epicare allow-list. Add it to scripts/sf_safe.py "
                    "and 01-Instructions/Project-Rules.md if it is needed.")
    if changing and not approved:
        projlib.fail(f"Refused: 'sf {cmd_text}' changes the org. Re-run with --approved <ID> only after the user "
                    "approved this exact operation and target (see 01-Instructions/Project-Rules.md).")

    try:
        ident = projlib.verify_org(cfg)
    except projlib.ProjectError as exc:
        projlib.fail(f"ORG NOT VERIFIED, nothing was run: {exc}")
    print(f"[sf_safe] {ident['organizationName']} {ident['orgId']} sandbox={ident['isSandbox']}"
          + (f" approval={approved}" if approved else ""), file=sys.stderr)

    if "--target-org" not in argv and "-o" not in argv and not any(a.startswith("--target-org=") for a in argv):
        argv = argv + ["--target-org", alias]
    sf = projlib._sf_executable()
    return subprocess.call([sf, *argv], cwd=projlib.PROJECT_DIR)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
