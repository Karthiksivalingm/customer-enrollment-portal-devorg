"""Claude Code SessionStart / UserPromptSubmit hook: add Epicare context for Claude.

Usage: python scripts/hooks/session_context.py start|prompt
Plain stdout becomes context Claude can see. Offline and fast: it never calls Salesforce.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lib"))
import projlib  # noqa: E402
import monthlib  # noqa: E402

ROUTING = (
    "Epicare: read 01-Instructions (Project-Rules, AI-Workflow, Coding-Standards, QA-Process) for every requirement. "
    "Check DOCUMENT-INDEX.md (Requirement lookup) first. Documents are filed by month: "
    "`python scripts/new_doc.py REQ|CR|CON|DEP|TECH|ATR|MTC \"<title>\"` files them in YYYY-MM/ (the month folder "
    "and MONTH-INDEX.md are created automatically when the month starts). Write documents only after the project lead approves (\"all good\"), "
    "then update MONTH-INDEX.md and rebuild the tracker: scripts/tracker/Build-MonthTracker.ps1 -Month YYYY-MM. "
    "Salesforce CLI only through `python scripts/sf_safe.py`."
)


def git_line(*args):
    try:
        return subprocess.run(["git", *args], cwd=projlib.PROJECT_DIR, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""


def new_month():
    """Create this month's folder the first time Claude runs in a new month, then rebuild the indexes."""
    month = monthlib.current_month()
    if os.path.isdir(os.path.join(projlib.PROJECT_DIR, month)):
        return None
    try:
        subprocess.run([sys.executable, os.path.join(projlib.PROJECT_DIR, "scripts", "build_index.py")],
                       cwd=projlib.PROJECT_DIR, capture_output=True, text=True, timeout=60)
    except Exception:
        monthlib.ensure_month(month)
    return f"New month: created {month}/ (03-Requirements to 08-QA and MONTH-INDEX.md). File this month's documents there."


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "prompt"
    cfg = projlib.load_config()
    branch = git_line("rev-parse", "--abbrev-ref", "HEAD")
    lines = [m for m in [new_month()] if m]
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
