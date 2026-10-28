"""Claude Code PreToolUse hook (Bash | PowerShell): block unsafe Git and Salesforce commands.

Exit 2 blocks the tool call and the stderr text is shown to Claude.
The rules mirror 01-Instructions/Project-Rules.md.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lib"))
import projlib  # noqa: E402

_CFG = projlib.load_config()
ALIAS = _CFG["salesforce"]["alias"]
BRANCH = _CFG["git"]["workingBranch"]
OTHER_BRANCHES = "|".join(re.escape(b) for b in _CFG["git"]["protectedBranches"] if b != BRANCH) or "a^"

GIT_RULES = [
    (r"\bgit\b[^;&|]*\bpush\b[^;&|]*(\s--force\b|\s-f\b|--force-with-lease|--mirror|\s--delete\b|\s\+\S)",
     "force-push, mirror or delete pushes are never allowed."),
    (r"\bgit\b[^;&|]*\bpush\b[^;&|]*\b(" + OTHER_BRANCHES + r")\b",
     f"pushing to a protected branch is not allowed. Epicare pushes go to '{BRANCH}' only."),
    (r"\bgit\b[^;&|]*\badd\b\s+(-A\b|--all\b|\.(\s|$|;|&)|\*|-u\b|--update\b)",
     "broad staging (git add . / -A / -u) is not allowed. Use scripts/autocommit.py, which stages Epicare paths explicitly."),
    (r"\bgit\b[^;&|]*\bcommit\b[^;&|]*\s-(a|am|-all)\b", "git commit -a stages everything. Use scripts/autocommit.py."),
    (r"\bgit\b[^;&|]*\bremote\b\s+(set-url|add|remove|rm|rename)\b", "changing Git remotes is not allowed."),
    (r"\bgit\b[^;&|]*\breset\b[^;&|]*--hard", "git reset --hard can discard user work."),
    (r"\bgit\b[^;&|]*\bclean\b[^;&|]*-[a-zA-Z]*f", "git clean -f deletes untracked files."),
    (r"\bgit\b[^;&|]*\b(checkout|restore)\b[^;&|]*\s(--\s+)?\.(\s|$)", "discarding working-tree changes is not allowed."),
    (r"\bgit\b[^;&|]*\b(rebase|filter-branch|filter-repo)\b", "history rewriting is not allowed."),
    (r"\bgit\b[^;&|]*\bconfig\b[^;&|]*\b(core\.hooksPath|remote\.)", "repository-wide Git configuration needs the user's explicit approval."),
]

SF_ALLOWED_DIRECT = [r"org\s+list\b", r"--version\b", r"version\b", r"help\b", r"plugins\b", r"project\s+generate\b",
                     r"config\s+(get|list)\b", r"org\s+display\s+(--target-org|-o)\s+" + ALIAS + r"\b"]


def check(cmd):
    for rx, why in GIT_RULES:
        if re.search(rx, cmd, re.I):
            return f"Blocked by Epicare guard: {why}"
    # Direct Salesforce CLI use must go through scripts/sf_safe.py (org verification + approval gate).
    for m in re.finditer(r"(?:^|[;&|(\s])(sfdx|sf)(?:\.cmd)?\s+([^;&|]*)", cmd):
        rest = m.group(2)
        if any(re.match(a, rest.strip()) for a in SF_ALLOWED_DIRECT):
            continue
        return ("Blocked by Epicare guard: run Salesforce CLI commands through `python scripts/sf_safe.py <sf args>` "
                "(from Epicare/). It verifies the UTDEV identity, forces --target-org " + ALIAS +
                " and refuses org changes without --approved <ID>.")
    for m in re.finditer(r"(--target-org|-o)[\s=]+(\S+)", cmd):
        if "sf_safe.py" in cmd and m.group(2).strip("\"'") != ALIAS:
            return f"Blocked by Epicare guard: target org must be {ALIAS}."
    return None


def main():
    try:
        data = json.loads(sys.stdin.read() or "{}")
    except ValueError:
        return 0
    cmd = (data.get("tool_input") or {}).get("command") or ""
    why = check(cmd)
    if why:
        print(why, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
