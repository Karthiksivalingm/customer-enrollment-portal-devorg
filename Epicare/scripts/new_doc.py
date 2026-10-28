"""Create a numbered document in the current month folder (01-Instructions/Project-Rules.md, sections 2 and 4).

Usage (from the project folder):
  python scripts/new_doc.py REQ "Case routing for new dealers"
  python scripts/new_doc.py CR  "Case status correction"
  python scripts/new_doc.py CON "Flow fault on Case update"
  python scripts/new_doc.py TECH|DEP|ATR|MTC "<title>"
  python scripts/new_doc.py REQ "<title>" --month 2026-11      file in a specific month

The document goes in the month it is first created: YYYY-MM/<folder>/<PREFIX>-<NNN>_<Short-Title>.md.
The month folder (full structure + MONTH-INDEX.md) is created the first time something is filed in a new month.
Numbers run across all months and are never reused. If a document with the same prefix and title already exists in
any month, its path is printed and nothing new is created. Then DOCUMENT-INDEX.md and the month index are rebuilt.
"""
import argparse
import datetime
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import monthlib  # noqa: E402
import build_index  # noqa: E402

TEMPLATES = os.path.join(monthlib.ROOT, "config", "templates")


def create(prefix, title, month=None):
    prefix = prefix.upper()
    if prefix not in monthlib.PREFIX_DIR:
        raise SystemExit(f"Unknown type {prefix}. Use one of {', '.join(monthlib.PREFIX_DIR)}.")
    slug = monthlib.title_slug(title)
    for _, _, _, path in monthlib.all_docs(prefix):
        if os.path.basename(path).split("_", 1)[1][:-3].lower() == slug.lower():
            return path, False
    month = month or monthlib.current_month()
    base = monthlib.ensure_month(month)
    number = monthlib.next_number(prefix)
    doc_id = f"{prefix}-{number:03d}"
    # Templates are named <PREFIX>_Template.md: a file called "CON.md" is a reserved device name on Windows.
    with open(os.path.join(TEMPLATES, f"{prefix}_Template.md"), encoding="utf-8") as fh:
        body = fh.read()
    body = (body.replace("{{ID}}", doc_id).replace("{{DATE}}", datetime.date.today().isoformat())
                .replace("{{TITLE}}", title).replace("{{MONTH}}", month).replace("{{PROJECT}}", monthlib.project_name()))
    folder = os.path.join(base, monthlib.PREFIX_DIR[prefix])
    path = os.path.join(folder, f"{doc_id}_{slug}.md")
    with open(path, "x", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    monthlib.ensure_month(month)  # drops the .gitkeep now that the folder has a document
    return path, True


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("type")
    ap.add_argument("title")
    ap.add_argument("--month")
    a = ap.parse_args()
    path, created = create(a.type, a.title, a.month)
    build_index.build()
    rel = os.path.relpath(path, monthlib.ROOT).replace("\\", "/")
    print(("Created " if created else "Already exists (no duplicate created): ") + rel)
