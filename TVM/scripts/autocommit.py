"""Validate, commit and push TVM changes to the authorized TVM branch.

Usage (from TVM/):
  python scripts/autocommit.py                      validate, commit and push all pending TVM changes
  python scripts/autocommit.py -m "Add REQ-004"     same, with a commit subject
  python scripts/autocommit.py --check              run every check, change nothing in Git
  python scripts/autocommit.py --no-push            commit but do not push
  python scripts/autocommit.py --hook               Claude Code Stop hook mode (reads hook JSON on stdin)

Commit subject: -m, else the first line of .tvm-state/commit-message.txt (Claude writes it before
finishing; it is deleted after a successful commit), else a generated summary.

Safety rules enforced here (see 01-Instructions/Git-Automation-Rules.md):
  * Only paths under TVM/ are ever staged, and always by explicit path (never `git add .` / `-A`).
  * Stops if the remote URL, branch, or pre-staged files are not as expected, or a merge/rebase is in progress.
  * Never force-pushes, never pushes to a protected branch, never changes the remote.
  * Secret scan, JSON/XML validation and documentation checks must pass before anything is staged.
  * A failed push leaves the commit in place; the next run pushes it.
  * Never runs any Salesforce command. A push never deploys anything.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import tvmlib  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
TRAILER = "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
RECORD_DIRS = {"03-Requirements": "REQ", "04-Change-Records": "CR", "05-Conflicts": "CF", "06-Deployment": "DEP"}
GENERATED = ("07-Technical-Documents/Metadata-Inventory/", "DOCUMENT-INDEX.md")


class Blocked(Exception):
    """Validation failed; Claude (or the user) must fix something before committing."""


class Stop(Exception):
    """Environment is not safe for automatic Git operations; report and do nothing."""


# ---------------------------------------------------------------- helpers

def git(*args, check=True):
    env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
    proc = subprocess.run(["git", *args], cwd=tvmlib.repo_root(), capture_output=True, text=True,
                          encoding="utf-8", errors="replace", env=env)
    if check and proc.returncode != 0:
        raise Stop(f"git {' '.join(args[:2])} failed: {proc.stderr.strip()[:800]}")
    return proc


def run_script(name):
    proc = subprocess.run([sys.executable, os.path.join(HERE, name)], cwd=tvmlib.TVM_DIR, capture_output=True,
                          text=True, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        raise Blocked(f"{name} failed:\n{(proc.stdout + proc.stderr).strip()[:1500]}")
    return proc.stdout.strip()


class Lock:
    def __init__(self):
        self.path = os.path.join(tvmlib.ensure_state_dir(), "autocommit.lock")

    def __enter__(self):
        if os.path.exists(self.path) and time.time() - os.path.getmtime(self.path) > 900:
            os.remove(self.path)  # stale lock from a crashed run
        try:
            self.fd = os.open(self.path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            raise Stop("another TVM auto-commit is already running (lock .tvm-state/autocommit.lock).")
        os.write(self.fd, str(os.getpid()).encode())
        return self

    def __exit__(self, *exc):
        os.close(self.fd)
        os.remove(self.path)


def tvm_changes(prefix):
    """Changed, added, deleted and untracked paths under TVM/ (repo-relative), excluding ignored files."""
    out = git("status", "--porcelain=v1", "-z", "--untracked-files=all", "--", prefix).stdout
    entries, paths = out.split("\0"), []
    i = 0
    while i < len(entries):
        e = entries[i]
        if len(e) > 3:
            code, path = e[:2], e[3:]
            if "R" in code or "C" in code:
                i += 1
                paths.append(entries[i])  # original path of a rename/copy
            paths.append(path)
        i += 1
    return sorted({p for p in paths if p.startswith(prefix)})


def to_local(repo_path):
    return os.path.join(tvmlib.repo_root(), repo_path)


# ---------------------------------------------------------------- environment checks

def check_environment(cfg):
    gcfg = cfg["git"]
    url = git("remote", "get-url", gcfg["remoteName"], check=False).stdout.strip()
    if url.rstrip("/").removesuffix(".git") != gcfg["remoteUrl"].rstrip("/").removesuffix(".git"):
        raise Stop(f"remote '{gcfg['remoteName']}' is '{url}', expected {gcfg['remoteUrl']}. Not committing.")
    branch = git("rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch == "HEAD":
        raise Stop("detached HEAD. Switch to the TVM working branch first.")
    if branch in gcfg["protectedBranches"]:
        raise Stop(f"current branch is '{branch}' (protected). TVM automation never commits to it. "
                   f"Run: git switch {gcfg['workingBranch']}")
    if branch != gcfg["workingBranch"]:
        raise Stop(f"current branch is '{branch}', the authorized TVM branch is '{gcfg['workingBranch']}'. Not committing.")
    gitdir = git("rev-parse", "--git-dir").stdout.strip()
    gitdir = gitdir if os.path.isabs(gitdir) else os.path.join(tvmlib.repo_root(), gitdir)
    for marker in ("MERGE_HEAD", "rebase-merge", "rebase-apply", "CHERRY_PICK_HEAD", "REVERT_HEAD"):
        if os.path.exists(os.path.join(gitdir, marker)):
            raise Stop(f"a Git operation is in progress ({marker}). Finish it by hand first.")
    return branch


# ---------------------------------------------------------------- validation

def component_of(rel):
    """Map a force-app path (relative to force-app/main/default) to a component label."""
    parts = rel.split("/")
    folder, name = parts[0], parts[-1]
    if folder == "objects" and len(parts) >= 3:
        if len(parts) == 3:
            return parts[1]
        child = re.sub(r"\.[A-Za-z]+-meta\.xml$", "", name)
        return f"{parts[1]}.{child}"
    if folder in ("lwc", "aura", "experiences", "staticresources") and len(parts) >= 2:
        return re.sub(r"\.(resource)(-meta\.xml)?$", "", parts[1])
    name = re.sub(r"-meta\.xml$", "", name)
    return re.sub(r"\.[A-Za-z]+$", "", name)


def added_text(repo_path):
    """Text added to a file in the working tree compared with HEAD (whole file if new)."""
    tracked = git("ls-files", "--error-unmatch", "--", repo_path, check=False).returncode == 0
    if not tracked:
        try:
            with open(to_local(repo_path), encoding="utf-8", errors="replace") as fh:
                return fh.read()
        except OSError:
            return ""
    diff = git("diff", "HEAD", "-U0", "--", repo_path, check=False).stdout
    return "\n".join(l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++"))


def validate(paths, prefix):
    problems = []
    existing = [p for p in paths if os.path.isfile(to_local(p))]

    # 1. Secrets (also blocks forbidden file types)
    sys.path.insert(0, HERE)
    import secret_scan
    hits = secret_scan.scan([to_local(p) for p in paths])
    if hits:
        raise Blocked("Secret check failed (values not shown):\n" +
                      "\n".join(f"  - {f}: {', '.join(h)}" for f, h in sorted(hits.items())) +
                      "\nRemove the values (keep them in the org only) or add the file to .gitignore.")

    # 2. Well-formed JSON / XML
    for p in existing:
        lp = to_local(p)
        try:
            if p.endswith(".json"):
                with open(lp, encoding="utf-8") as fh:
                    json.load(fh)
            elif p.endswith(".xml"):
                ET.parse(lp)
        except (ValueError, ET.ParseError) as exc:
            problems.append(f"{p}: invalid {'JSON' if p.endswith('.json') else 'XML'} ({str(exc)[:120]})")

    # 3. Dated records: filename and front matter agree
    for p in existing:
        rel = p[len(prefix):]
        folder = rel.split("/")[0]
        if folder in RECORD_DIRS and rel.count("/") == 1 and rel.endswith(".md"):
            name = os.path.basename(rel)
            m = re.match(r"^(\d{4}-\d{2}-\d{2})-([A-Z]+)-(\d{3,})-[a-z0-9-]+\.md$", name)
            if not m:
                if re.match(r"^\d{4}-\d{2}-\d{2}-", name):
                    problems.append(f"{p}: dated record name must be YYYY-MM-DD-{RECORD_DIRS[folder]}-NNN-slug.md")
                continue
            with open(to_local(p), encoding="utf-8") as fh:
                head = fh.read(800)
            fid = re.search(r"^id:\s*(\S+)", head, re.M)
            fdate = re.search(r"^date:\s*(\S+)", head, re.M)
            if m.group(2) != RECORD_DIRS[folder]:
                problems.append(f"{p}: {m.group(2)} record in the {folder} folder (expected {RECORD_DIRS[folder]}).")
            if not fid or fid.group(1) != f"{m.group(2)}-{m.group(3)}":
                problems.append(f"{p}: front matter 'id' must be {m.group(2)}-{m.group(3)}.")
            if not fdate or fdate.group(1) != m.group(1):
                problems.append(f"{p}: front matter 'date' must match the filename date {m.group(1)}.")

    # 4. Every changed Salesforce component is documented in 07-Technical-Documents/Change-History.md
    src_prefix = prefix + "force-app/main/default/"
    components = sorted({component_of(p[len(src_prefix):]) for p in paths if p.startswith(src_prefix)})
    if components:
        history = prefix + "07-Technical-Documents/Change-History.md"
        added = added_text(history) if history in paths else ""
        if not re.search(r"\[bulk:[^\]]+\]", added):
            missing = [c for c in components if c not in added]
            if missing:
                problems.append(
                    "Salesforce source changed but 07-Technical-Documents/Change-History.md has no new entry naming: "
                    + ", ".join(missing[:25]) + (" …" if len(missing) > 25 else "")
                    + ". Add a dated row per component (or one row with [bulk: <manifest>] for a bulk retrieval), "
                    "and update the component's technical document and any affected Knowledge Base page.")
    if problems:
        raise Blocked("Documentation/validation check failed:\n" + "\n".join(f"  - {x}" for x in problems))
    return components


# ---------------------------------------------------------------- commit and push

def commit_subject(explicit, paths, prefix, components):
    if explicit:
        return explicit.strip().splitlines()[0], None
    msg_file = os.path.join(tvmlib.STATE_DIR, "commit-message.txt")
    if os.path.exists(msg_file):
        with open(msg_file, encoding="utf-8") as fh:
            text = fh.read().strip()
        if text:
            return text.splitlines()[0][:100], msg_file
    areas = sorted({p[len(prefix):].split("/")[0] for p in paths})
    if components:
        return f"TVM: update {len(components)} Salesforce component(s) and documentation", None
    return "TVM: update " + ", ".join(areas)[:80], None


def push(cfg, branch):
    gcfg = cfg["git"]
    upstream = git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}", check=False)
    args = ["push"]
    if upstream.returncode != 0:
        args.append("--set-upstream")
    args += [gcfg["remoteName"], f"{branch}:refs/heads/{branch}"]
    proc = git(*args, check=False)
    if proc.returncode != 0:
        raise Stop("push failed; the commit is kept locally and the next run will push it.\n"
                   + proc.stderr.strip()[:800])


def unpushed(cfg, branch):
    remote_ref = f"refs/remotes/{cfg['git']['remoteName']}/{branch}"
    if git("rev-parse", "--verify", "--quiet", remote_ref, check=False).returncode != 0:
        return int(git("rev-list", "--count", "HEAD", f"^refs/remotes/{cfg['git']['remoteName']}/main", check=False).stdout.strip() or 0)
    return int(git("rev-list", "--count", f"{remote_ref}..HEAD").stdout.strip() or 0)


def run(args):
    cfg = tvmlib.load_config()
    prefix = tvmlib.tvm_prefix()
    branch = check_environment(cfg)

    staged_elsewhere = [p for p in git("diff", "--cached", "--name-only").stdout.splitlines() if not p.startswith(prefix)]
    if staged_elsewhere:
        raise Stop("files outside TVM/ are already staged (" + ", ".join(staged_elsewhere[:5]) +
                   "). TVM automation will not commit next to them. Unstage or commit them yourself first.")

    paths = tvm_changes(prefix)
    if not paths:
        if not args.check and cfg["git"]["autoPush"] and not args.no_push and unpushed(cfg, branch):
            push(cfg, branch)
            return f"Pushed earlier TVM commit(s) to {branch}: {git('rev-parse', '--short', 'HEAD').stdout.strip()}"
        return None

    # Regenerate derived documents so they always match source and records.
    if any(p.startswith(prefix + "force-app/") for p in paths):
        run_script("build_inventory.py")
    run_script("build_index.py")
    paths = tvm_changes(prefix)

    components = validate(paths, prefix)
    if args.check:
        return f"Check passed: {len(paths)} TVM path(s) ready to commit on {branch}."

    with open(os.path.join(tvmlib.ensure_state_dir(), "pathspec.txt"), "w", encoding="utf-8", newline="") as fh:
        fh.write("\0".join(paths))
    git("add", "--pathspec-from-file=" + os.path.join(tvmlib.STATE_DIR, "pathspec.txt"), "--pathspec-file-nul")
    staged = git("diff", "--cached", "--name-only").stdout.splitlines()
    outside = [p for p in staged if not p.startswith(prefix)]
    if outside:
        git("restore", "--staged", "--", *staged)
        raise Stop("staging produced paths outside TVM/ (" + ", ".join(outside[:5]) + "); everything was unstaged.")
    if not staged:
        return None

    subject, msg_file = commit_subject(args.message, staged, prefix, components)
    body = [f"{len(staged)} file(s) under {prefix}"]
    if components:
        body.append("Components: " + ", ".join(components[:30]) + (" …" if len(components) > 30 else ""))
    message = subject + "\n\n" + "\n".join(body) + ("\n\n" + TRAILER if args.hook else "")
    proc = subprocess.run(["git", "commit", "--quiet", "-F", "-"], input=message, cwd=tvmlib.repo_root(),
                          capture_output=True, text=True, encoding="utf-8")
    if proc.returncode != 0:
        raise Stop("git commit failed (changes stay staged under TVM/ only):\n" + (proc.stdout + proc.stderr).strip()[:800])
    if msg_file:
        os.remove(msg_file)
    sha = git("rev-parse", "--short", "HEAD").stdout.strip()
    if not cfg["git"]["autoPush"] or args.no_push:
        return f"Committed {sha} on {branch} ({len(staged)} TVM file(s)); push skipped."
    push(cfg, branch)
    return f"Committed and pushed {sha} to {cfg['git']['remoteName']}/{branch} ({len(staged)} TVM file(s)): {subject}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-m", "--message")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--no-push", action="store_true")
    ap.add_argument("--hook", action="store_true")
    args = ap.parse_args()

    hook_input = {}
    if args.hook:
        try:
            hook_input = json.loads(sys.stdin.read() or "{}")
        except ValueError:
            hook_input = {}
    second_attempt = bool(hook_input.get("stop_hook_active"))

    try:
        with Lock():
            result = run(args)
    except Blocked as exc:
        if args.hook and not second_attempt:
            # Exit 2: Claude Code feeds stderr back to Claude, which completes the documentation and stops again.
            print(f"TVM auto-commit blocked. Fix this, then finish your turn:\n{exc}", file=sys.stderr)
            sys.exit(2)
        report(args, f"TVM auto-commit NOT done (changes kept, nothing staged): {exc}", error=True)
        return
    except (Stop, tvmlib.TvmError) as exc:
        report(args, f"TVM auto-commit stopped: {exc}", error=True)
        return
    if result:
        report(args, result)


def report(args, text, error=False):
    with open(os.path.join(tvmlib.ensure_state_dir(), "last-result.txt"), "w", encoding="utf-8") as fh:
        fh.write(f"{tvmlib.now_local()}\n{text}\n")
    if args.hook:
        print(json.dumps({"systemMessage": text}))
    else:
        print(text, file=sys.stderr if error else sys.stdout)
        if error:
            sys.exit(1)


if __name__ == "__main__":
    main()
