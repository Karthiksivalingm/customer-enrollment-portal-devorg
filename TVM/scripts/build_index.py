"""Rebuild DOCUMENT-INDEX.md (master index) and the document lists in every YYYY-MM/MONTH-INDEX.md.

Usage (from the project folder):  python scripts/build_index.py

- DOCUMENT-INDEX.md is fully generated: months, requirement lookup (from each month's "Requirement history" table),
  naming and next free numbers, knowledge base, living documents, instructions.
- In each MONTH-INDEX.md only the block between AUTO-DOCUMENTS markers is generated (the documents filed that
  month). The Summary and Requirement history sections are written by hand when a requirement is approved.
Writes only when content changes. The monthly Excel tracker is built separately with
scripts/tracker/Build-MonthTracker.ps1 -Month YYYY-MM (only after the project lead approves).
"""
import datetime
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import monthlib  # noqa: E402

ROOT = monthlib.ROOT
plib = monthlib.plib
# Requirements are listed in the hand-written "Requirement history" table (the tracker reads it), not here.
SECTION_NAMES = [("04-Change-Records", "04 — Change Records"),
                 ("05-Conflicts", "05 — Conflicts"), ("06-Deployment", "06 — Deployment"), ("07-Technical", "07 — Technical"),
                 ("08-QA/01-Automated-Testing", "08 — QA: automated test reports"),
                 ("08-QA/02-Manual-Testing", "08 — QA: manual test cases")]
INSTRUCTIONS = [("AI-Workflow.md", "Workflows A, B and C; required document structures"),
                ("Coding-Standards.md", "Rules every change must meet"),
                ("Project-Rules.md", "Environments, monthly folders, history lookup, document control, QA, test data, approvals, version control, reporting"),
                ("QA-Process.md", "When QA runs, file locations, test IDs, how tests are run, ATR and MTC structure")]
PREFIX_ROWS = [("`02-Knowledge-Base` (root, common)", "KB", "Background: overview, process, integrations, environment, users, guides"),
               ("`YYYY-MM/03-Requirements`", "REQ", "One per requirement"),
               ("`YYYY-MM/04-Change-Records`", "CR", "One per change made to an org"),
               ("`YYYY-MM/05-Conflicts`", "CON", "Problems, clashes, open risks"),
               ("`YYYY-MM/06-Deployment`", "DEP", "Only when something is actually deployed to production"),
               ("`YYYY-MM/07-Technical`", "TECH", "Technical design and component detail"),
               ("`YYYY-MM/08-QA/01-Automated-Testing`", "ATR", "Automated test reports"),
               ("`YYYY-MM/08-QA/02-Manual-Testing`", "MTC", "Manual test cases, with `MTC-###_screenshots/`")]


def rel(path, start):
    return os.path.relpath(path, start).replace("\\", "/")


def clean(cell):
    return re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", cell).strip()


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def month_summary(text):
    """The bold headline of each Summary bullet, e.g. 'Project setup; Case skill-based routing QA'."""
    m = re.search(r"^## Summary\s*\n(.*?)(?=^## )", text, re.S | re.M)
    items = [l.strip() for l in (m.group(1).splitlines() if m else []) if l.strip().startswith(("-", "*"))]
    heads = []
    for i in items:
        b = re.search(r"\*\*(.+?)\*\*", i)
        heads.append(clean(b.group(1)) if b else clean(re.sub(r"^[-*]\s+", "", i))[:80])
    return "; ".join(heads) or "—"


def requirement_rows(text):
    """Rows of the hand-written 'Requirement history' table only."""
    rows = []
    m = re.search(r"^## Requirement history\s*\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    for line in (m.group(1).splitlines() if m else []):
        if re.match(r"^\|\s*\[?REQ-\d{3}", line):
            c = [x.strip() for x in line.strip().strip("|").split("|")]
            rows.append((clean(c[0]), clean(c[1]), clean(c[2]), clean(c[4]) if len(c) > 4 else ""))
    return rows


def month_documents_block(month):
    base = os.path.join(ROOT, month)
    out = []
    for sub, label in SECTION_NAMES:
        docs = sorted(p for p in (os.path.join(base, sub, f) for f in os.listdir(os.path.join(base, sub)))
                      if p.endswith(".md")) if os.path.isdir(os.path.join(base, sub)) else []
        out += ["", f"### {label}"]
        numbered = [p for p in docs if monthlib.DOC_RX.match(os.path.basename(p))]
        other = [p for p in docs if p not in numbered]
        if not docs:
            out.append("None.")
            continue
        out += ["| ID | Document | Status |", "|---|---|---|"]
        for p in numbered + other:
            m = monthlib.DOC_RX.match(os.path.basename(p))
            h = monthlib.doc_header(p)
            status = clean(next((v for k, v in h.items() if k.lower().startswith(("status", "result"))), "")) or "—"
            out.append(f"| {m.group(1) + '-' + m.group(2) if m else '— (living)'} | [{monthlib.doc_title(p)}]({rel(p, base)}) | {status[:120]} |")
        subdirs = sorted(d for d in os.listdir(os.path.join(base, sub)) if os.path.isdir(os.path.join(base, sub, d)))
        if subdirs:
            out.append("")
            out.append("Subfolders: " + " · ".join(f"[{d}]({sub}/{d}/)" for d in subdirs))
    return "\n".join(out).strip()


def update_month_index(month):
    path = os.path.join(ROOT, month, "MONTH-INDEX.md")
    text = read(path)
    block = monthlib.AUTO_START + "\n_Generated by `scripts/build_index.py` from the files in this month folder._\n\n" + \
        month_documents_block(month) + "\n" + monthlib.AUTO_END
    if monthlib.AUTO_START in text and monthlib.AUTO_END in text:
        text = re.sub(re.escape(monthlib.AUTO_START) + r".*?" + re.escape(monthlib.AUTO_END), lambda _: block, text, flags=re.S)
    else:
        text = text.rstrip() + "\n\n" + block + "\n"
    return plib.write_if_changed(path, text)


def build():
    cfg = plib.load_config()
    name = cfg.get("project", os.path.basename(ROOT))
    months = monthlib.months()
    for m in months:
        monthlib.ensure_month(m)  # a month folder created by hand gets its full structure and MONTH-INDEX.md
    changed = [m for m in months if update_month_index(m)]

    month_rows, req_rows = [], []
    for m in months:
        text = read(os.path.join(ROOT, m, "MONTH-INDEX.md"))
        tracker = f"[{m}_Tracker.xlsx]({m}/{m}_Tracker.xlsx)" if os.path.exists(os.path.join(ROOT, m, f"{m}_Tracker.xlsx")) else "Not built yet"
        month_rows.append(f"| {m} | {month_summary(text)} | [{m}/MONTH-INDEX.md]({m}/MONTH-INDEX.md) | {tracker} |")
        req_rows += [f"| {r[0]} | {r[1]} | {r[2]} | {m} | {r[3]} |" for r in requirement_rows(text)]

    kb = []
    for f in sorted(os.listdir(os.path.join(ROOT, "02-Knowledge-Base"))):
        if f.lower().endswith((".md", ".docx", ".html")) and f.lower() != "readme.md":
            p = os.path.join(ROOT, "02-Knowledge-Base", f)
            mm = monthlib.DOC_RX.match(f)
            title = monthlib.doc_title(p) if f.endswith(".md") else f
            kb.append(f"| {mm.group(1) + '-' + mm.group(2) if mm else '—'} | [{title}](02-Knowledge-Base/{f}) |")

    living = []
    for item in cfg.get("documents", {}).get("living", []):
        p = os.path.join(ROOT, item["path"])
        if os.path.exists(p):
            living.append(f"| {item['name']} | [{item['path']}]({item['path']}) |")

    lines = [f"# {name} Project — Document Index", "",
             "Master index. `01-Instructions` and `02-Knowledge-Base` are **common** and sit at the project root. All other documents "
             "are stored **by month**: each month folder has the same structure and its own `MONTH-INDEX.md` with the full history of "
             f"that month. **Last updated:** {datetime.date.today().isoformat()} (generated by `scripts/build_index.py`).", "",
             "## How to look something up",
             "1. Read the instruction files in `01-Instructions` (always, for every requirement).",
             "2. Look for the topic in the **Requirement lookup** table below (title and keywords).",
             "3. If it exists, open only that month's `MONTH-INDEX.md` and the documents it links to. Don't search the other months or folders.",
             "4. If it doesn't exist, it's a new requirement: use the next free numbers below and file it in the current month's folder "
             "(`python scripts/new_doc.py REQ \"<title>\"` creates the month folder the first time).", "",
             "## Months", "| Month | Summary | History | Tracker (Excel) |", "|---|---|---|---|", *month_rows, "",
             "## Requirement lookup", "| REQ | Title | Keywords | Month | Status |", "|---|---|---|---|---|",
             *(req_rows or ["| — | No requirements yet | | | |"]), "",
             "## Naming and numbering",
             "`<PREFIX>-<3-digit serial>_<Short-Title-With-Hyphens>.md`. Serial numbers run across all months and are never reused.", "",
             "| Folder | Prefix | What goes in it | Next free number |", "|---|---|---|---|",
             *[f"| {folder} | `{pfx}-` | {what} | {pfx}-{monthlib.next_number(pfx):03d} |"
               for folder, pfx, what in PREFIX_ROWS], "",
             "## 02 — Knowledge Base (common)", "Background for the whole project, not tied to a month. Update these in place.", "",
             "| ID | Document |", "|---|---|", *kb, "",
             "## Living documents in month folders", "Updated in place in the month they were created. Open them directly; no need to search.", "",
             "| Document | Location |", "|---|---|", *(living or ["| — | None |"]), "",
             "## 01 — Instructions", "| File | Purpose |", "|---|---|",
             *[f"| [{f}](01-Instructions/{f}) | {p} |" for f, p in INSTRUCTIONS if os.path.exists(os.path.join(ROOT, "01-Instructions", f))]]
    text = "\n".join(lines) + "\n"
    return plib.write_if_changed(os.path.join(ROOT, "DOCUMENT-INDEX.md"), text) or bool(changed)


if __name__ == "__main__":
    print("Indexes " + ("updated" if build() else "unchanged"))
