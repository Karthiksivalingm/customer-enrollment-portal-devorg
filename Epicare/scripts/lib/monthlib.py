"""Monthly document folders (01-Instructions/Project-Rules.md, section 2).

01-Instructions and 02-Knowledge-Base are common and sit at the project root. Every other document is filed in the
month it is first created: <project>/YYYY-MM/{03-Requirements,04-Change-Records,05-Conflicts,06-Deployment,
07-Technical,08-QA/01-Automated-Testing,08-QA/02-Manual-Testing}, with a MONTH-INDEX.md and a YYYY-MM_Tracker.xlsx.
Serial numbers (REQ-001, CR-001, ...) run across all months and are never reused.
"""
import datetime
import glob
import os
import re

try:
    import tvmlib as plib
    ROOT = plib.TVM_DIR
except ImportError:  # Epicare and other projects use projlib
    import projlib as plib
    ROOT = plib.PROJECT_DIR

MONTH_RX = re.compile(r"^\d{4}-\d{2}$")
FOLDERS = ["03-Requirements", "04-Change-Records", "05-Conflicts", "06-Deployment", "07-Technical",
           "08-QA/01-Automated-Testing", "08-QA/02-Manual-Testing"]
PREFIX_DIR = {"REQ": "03-Requirements", "CR": "04-Change-Records", "CON": "05-Conflicts", "DEP": "06-Deployment",
              "TECH": "07-Technical", "ATR": "08-QA/01-Automated-Testing", "MTC": "08-QA/02-Manual-Testing"}
DOC_RX = re.compile(r"^(REQ|CR|CON|DEP|TECH|ATR|MTC|KB)-(\d{3})_[A-Za-z0-9][A-Za-z0-9-]*\.md$")
AUTO_START, AUTO_END = "<!-- AUTO-DOCUMENTS:START -->", "<!-- AUTO-DOCUMENTS:END -->"


def project_name():
    return plib.load_config().get("project", os.path.basename(ROOT))


def current_month():
    return datetime.date.today().strftime("%Y-%m")


def months():
    return sorted(d for d in os.listdir(ROOT) if MONTH_RX.match(d) and os.path.isdir(os.path.join(ROOT, d)))


def living_month():
    """Month folder holding the living documents (inventory, change history, procedures)."""
    m = plib.load_config().get("documents", {}).get("livingMonth")
    return m or (months()[0] if months() else current_month())


def living_path(*parts):
    return os.path.join(ROOT, living_month(), *parts)


def month_index_skeleton(month):
    name = datetime.date(int(month[:4]), int(month[5:]), 1).strftime("%B %Y")
    return f"""# {month} — Month index

History of the project work in {name}: every requirement, the documents and components behind it, and its status. The master index is [DOCUMENT-INDEX.md](../DOCUMENT-INDEX.md). The tracking workbook for this month is [{month}_Tracker.xlsx]({month}_Tracker.xlsx).

## Summary
- Nothing filed yet this month.

## Requirement history
| REQ | Title | Keywords | Objects / main components | Status | Change records | Other documents |
|---|---|---|---|---|---|---|

## Documents created this month
The knowledge base is common to all months and lives in the root [02-Knowledge-Base](../02-Knowledge-Base) folder.

{AUTO_START}
{AUTO_END}

## Open items at month end
None yet.
"""


def ensure_month(month=None):
    """Create the month folder with the full structure and a MONTH-INDEX.md the first time it is used."""
    month = month or current_month()
    if not MONTH_RX.match(month):
        raise ValueError("Month must be YYYY-MM")
    base = os.path.join(ROOT, month)
    for sub in FOLDERS:
        d = os.path.join(base, sub)
        os.makedirs(d, exist_ok=True)
        keep = os.path.join(d, ".gitkeep")
        others = [f for f in os.listdir(d) if f != ".gitkeep"]
        if not others and not os.path.exists(keep):
            open(keep, "w").close()
        elif others and os.path.exists(keep) and os.path.getsize(keep) == 0:
            os.remove(keep)  # the folder is no longer empty
    idx = os.path.join(base, "MONTH-INDEX.md")
    if not os.path.exists(idx):
        with open(idx, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(month_index_skeleton(month))
    return base


def all_docs(prefix=None):
    """(prefix, number, month, path) for every numbered document in every month (and KB at the root)."""
    out = []
    for m in months():
        for sub in FOLDERS:
            for p in glob.glob(os.path.join(ROOT, m, sub, "*.md")):
                mm = DOC_RX.match(os.path.basename(p))
                if mm and (prefix is None or mm.group(1) == prefix):
                    out.append((mm.group(1), int(mm.group(2)), m, p))
    for p in glob.glob(os.path.join(ROOT, "02-Knowledge-Base", "*.md")):
        mm = DOC_RX.match(os.path.basename(p))
        if mm and (prefix is None or mm.group(1) == prefix):
            out.append((mm.group(1), int(mm.group(2)), "", p))
    return out


def next_number(prefix):
    nums = [n for _, n, _, _ in all_docs(prefix)]
    return (max(nums) + 1) if nums else 1


def title_slug(title):
    words = re.findall(r"[A-Za-z0-9]+", title)
    return "-".join(w[:1].upper() + w[1:] for w in words)[:70].rstrip("-") or "Item"


def doc_title(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if line.startswith("# "):
                return re.sub(r"^[A-Z]+-\d{3}\s*[—:-]\s*", "", line[2:].strip())
    return os.path.basename(path)


def doc_header(path):
    """The first '| **Key** | value |' table at the top of a document."""
    head, in_table = {}, False
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if line.startswith("|"):
                in_table = True
                m = re.match(r"^\|\s*\*\*(.+?)\*\*\s*\|\s*(.*?)\s*\|\s*$", line.rstrip("\n"))
                if m:
                    head[m.group(1).strip()] = m.group(2)
            elif in_table:
                break
    return head
