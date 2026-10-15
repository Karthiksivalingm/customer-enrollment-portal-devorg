"""Claude Code SessionStart / UserPromptSubmit hook: add Epicare context for Claude.

Usage: python scripts/hooks/session_context.py start|prompt
Plain stdout becomes context Claude can see. Offline and fast: it never calls Salesforce.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lib"))
import projlib  # noqa: E402

ROUTING = (
    "Epicare documentation routing (01-Instructions/Documentation-Rules.md): new task/requirement -> "
    "`python scripts/new_doc.py REQ \"<title>\"`; actual record change -> CR (with verified before/after values); "
    "error or conflict -> CF; deployment prep/execution/verification -> DEP; metadata change -> update its "
    "07-Technical-Documents doc and add a dated row to 07-Technical-Documents/Change-History.md; material behaviour change -> 02-Knowledge-Base; "
    "standing-rule change -> 01-Instructions. Salesforce CLI only via `python scripts/sf_safe.py` (UTDEV). "
    "When you finish, the Stop hook validates, commits and pushes Epicare files to the configured branch; write a one-line commit "
    "subject to .project-state/commit-message.txt first."
)


def git_line(*args):
    try:
        return subprocess.run(["git", *args], cwd=projlib.PROJECT_DIR, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "prompt"
    cfg = projlib.load_config()
    branch = git_line("rev-parse", "--abbrev-ref", "HEAD")
    lines = []
    if branch != cfg["git"]["workingBranch"]:
        lines.append(f"WARNING: current Git branch is '{branch}', not '{cfg['git']['workingBranch']}'. "
                     "Automatic Epicare commits are disabled until the user switches branch.")
    if mode == "start":
        pending = git_line("status", "--porcelain", "--", ".")
        last = ""
        p = os.path.join(projlib.STATE_DIR, "last-result.txt")
        if os.path.exists(p):
            with open(p, encoding="utf-8") as fh:
                last = fh.read().strip().replace("\n", " — ")
        lines.append(f"Epicare project. Branch {branch}. Org alias {cfg['salesforce']['alias']} "
                     f"({cfg['salesforce']['orgId']}, sandbox only). Read CLAUDE.md first.")
        lines.append(f"Uncommitted Epicare paths: {len(pending.splitlines()) if pending else 0}." +
                     (f" Last auto-commit result: {last}" if last else ""))
    lines.append(ROUTING)
    print("\n".join(lines))


if __name__ == "__main__":
    main()
