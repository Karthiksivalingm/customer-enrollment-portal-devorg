"""Create a dated Epicare record from its template, with the next free ID.

Usage (from Epicare/):
  python scripts/new_doc.py REQ "Case routing for new dealers" [--key <stable-event-key>] [--date YYYY-MM-DD]
  python scripts/new_doc.py CR  "Case status correction"      --key case-500xx-status-2026-10-14
  python scripts/new_doc.py CF  "Flow fault on Case update"
  python scripts/new_doc.py DEP "Sandbox validation of REQ-001"

Types: REQ -> 03-Requirements, CR -> 04-Change-Records, CF -> 05-Conflicts, DEP -> 06-Deployment.
Filename: <YYYY-MM-DD>-<TYPE>-<NNN>-<slug>.md. IDs are never reused.

Idempotent: if a record with the same --key (or, without a key, the same type, date
and slug) already exists, its path is printed and nothing new is created.
Prints the path of the record. Then rebuilds DOCUMENT-INDEX.md.
"""
import argparse
import glob
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import projlib  # noqa: E402
import build_index  # noqa: E402

FOLDERS = {
    "REQ": "03-Requirements",
    "CR": "04-Change-Records",
    "CF": "05-Conflicts",
    "DEP": "06-Deployment",
}
NAME_RX = re.compile(r"^(\d{4}-\d{2}-\d{2})-([A-Z]+)-(\d{3,})-(.+)\.md$")


def existing(prefix):
    folder = os.path.join(projlib.PROJECT_DIR, FOLDERS[prefix])
    out = []
    for path in glob.glob(os.path.join(folder, "*.md")):
        m = NAME_RX.match(os.path.basename(path))
        if m and m.group(2) == prefix:
            out.append((int(m.group(3)), m.group(1), m.group(4), path))
    return out


def find_by_key(prefix, key):
    for _, _, _, path in existing(prefix):
        with open(path, encoding="utf-8") as fh:
            head = fh.read(1500)
        if re.search(rf"^event_key:\s*{re.escape(key)}\s*$", head, re.M):
            return path
    return None


def create(prefix, title, key=None, date=None):
    prefix = prefix.upper()
    if prefix not in FOLDERS:
        raise projlib.ProjectError(f"Unknown type {prefix}. Use one of {', '.join(FOLDERS)}.")
    date = date or projlib.today()
    if not re.match(r"^\d{4}-\d{2}-\d{2}$", date):
        raise projlib.ProjectError("Date must be YYYY-MM-DD.")
    slug = projlib.slugify(title)
    if key:
        hit = find_by_key(prefix, key)
        if hit:
            return hit, False
    for _, d, s, path in existing(prefix):
        if d == date and s == slug:
            return path, False
    nums = [n for n, *_ in existing(prefix)]
    number = (max(nums) + 1) if nums else 1
    doc_id = f"{prefix}-{number:03d}"
    with open(os.path.join(projlib.PROJECT_DIR, "config", "templates", f"{prefix}.md"), encoding="utf-8") as fh:
        body = fh.read()
    body = (body.replace("{{ID}}", doc_id).replace("{{DATE}}", date).replace("{{TITLE}}", title)
                .replace("{{EVENT_KEY}}", key or f"{doc_id.lower()}-{slug}")
                .replace("{{TIMESTAMP}}", projlib.now_local()))
    path = os.path.join(projlib.PROJECT_DIR, FOLDERS[prefix], f"{date}-{doc_id}-{slug}.md")
    with open(path, "x", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    return path, True


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("type")
    ap.add_argument("title")
    ap.add_argument("--key")
    ap.add_argument("--date")
    a = ap.parse_args()
    try:
        path, created = create(a.type, a.title, a.key, a.date)
    except projlib.ProjectError as exc:
        projlib.fail(str(exc))
    build_index.build()
    rel = os.path.relpath(path, projlib.PROJECT_DIR).replace("\\", "/")
    print(("Created " if created else "Already exists (no duplicate created): ") + rel)
