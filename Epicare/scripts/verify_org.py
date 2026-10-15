"""Verify that the Epicare org alias still resolves to the Epicare UTDEV.

Usage (from Epicare/):  python scripts/verify_org.py [--json]
Exit 0 = verified, 1 = stop. Never prints tokens or session IDs.
"""
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import projlib  # noqa: E402

if __name__ == "__main__":
    try:
        ident = projlib.verify_org()
    except projlib.ProjectError as exc:
        projlib.fail(f"ORG NOT VERIFIED: {exc}")
    if "--json" in sys.argv:
        print(json.dumps(ident, indent=2))
    else:
        print(f"Verified: alias {ident['alias']} -> {ident['organizationName']} "
              f"({ident['orgId']}), sandbox={ident['isSandbox']}, user {ident['username']}")
