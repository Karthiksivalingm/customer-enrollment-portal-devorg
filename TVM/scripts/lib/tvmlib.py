"""Shared helpers for TVM automation scripts.

Every TVM script imports this module. It locates the TVM project, loads
config/tvm-project.json, runs Salesforce CLI and Git commands, and verifies
the Salesforce org identity before any org operation.
"""
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

TVM_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CONFIG_PATH = os.path.join(TVM_DIR, "config", "tvm-project.json")
STATE_DIR = os.path.join(TVM_DIR, ".tvm-state")


class TvmError(Exception):
    """A check failed. The message is safe to show to the user."""


def load_config():
    with open(CONFIG_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def today():
    return datetime.date.today().isoformat()


def now_local():
    return datetime.datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z").strip()


def ensure_state_dir():
    os.makedirs(STATE_DIR, exist_ok=True)
    return STATE_DIR


# ---------------------------------------------------------------- processes

def _sf_executable():
    for name in ("sf.cmd", "sf"):
        path = shutil.which(name)
        if path:
            return path
    raise TvmError("Salesforce CLI (sf) was not found on PATH.")


def run(cmd, cwd=None, check=True, input_text=None):
    proc = subprocess.run(
        cmd, cwd=cwd or TVM_DIR, input=input_text, capture_output=True,
        text=True, encoding="utf-8", errors="replace",
    )
    if check and proc.returncode != 0:
        raise TvmError(f"Command failed ({proc.returncode}): {' '.join(cmd[:4])} ...\n{proc.stderr.strip()[:2000]}")
    return proc


def sf_json(args):
    """Run an sf command with --json and return the parsed 'result'."""
    proc = run([_sf_executable(), *args, "--json"], check=False)
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        raise TvmError(f"sf {' '.join(args[:3])} returned no JSON: {proc.stderr.strip()[:500]}")
    if data.get("status", 1) != 0:
        raise TvmError(f"sf {' '.join(args[:3])} failed: {data.get('message', 'unknown error')}")
    return data.get("result")


def git(*args, check=True):
    return run(["git", *args], cwd=repo_root(), check=check)


_repo_root = None


def repo_root():
    global _repo_root
    if _repo_root is None:
        proc = run(["git", "rev-parse", "--show-toplevel"], cwd=TVM_DIR)
        _repo_root = os.path.normpath(proc.stdout.strip())
    return _repo_root


# ---------------------------------------------------------------- org identity

def verify_org(cfg=None):
    """Confirm the configured alias resolves to the expected sandbox.

    Returns a dict of non-secret identity fields. Raises TvmError on any
    mismatch so the caller stops before touching the org.
    """
    cfg = cfg or load_config()
    sfc = cfg["salesforce"]
    alias = sfc["alias"]
    info = sf_json(["org", "display", "--target-org", alias])
    if not info:
        raise TvmError(f"Alias '{alias}' did not resolve to an org.")
    org_id = (info.get("id") or "")[:15]
    if org_id != sfc["orgId"][:15]:
        raise TvmError(f"Alias '{alias}' points to org {info.get('id')}, expected {sfc['orgId']}. Stopping.")
    if info.get("username") != sfc["username"]:
        raise TvmError(f"Alias '{alias}' uses username {info.get('username')}, expected {sfc['username']}. Stopping.")
    if info.get("connectedStatus") not in ("Connected", None):
        raise TvmError(f"Org '{alias}' is not connected: {info.get('connectedStatus')}. Re-authenticate it first.")
    rows = sf_json(["data", "query", "--target-org", alias, "--query",
                    "SELECT Id, Name, IsSandbox FROM Organization"])
    rec = (rows or {}).get("records", [{}])[0]
    if sfc.get("mustBeSandbox", True) and rec.get("IsSandbox") is not True:
        raise TvmError(f"Org {org_id} reports IsSandbox={rec.get('IsSandbox')}. TVM works in the sandbox only. Stopping.")
    return {
        "alias": alias,
        "username": info.get("username"),
        "orgId": info.get("id"),
        "instanceUrl": info.get("instanceUrl"),
        "organizationName": rec.get("Name"),
        "isSandbox": rec.get("IsSandbox"),
    }


# ---------------------------------------------------------------- paths

def rel_to_repo(path):
    return os.path.relpath(os.path.abspath(path), repo_root()).replace("\\", "/")


def tvm_prefix():
    """Repo-relative path of TVM/ (e.g. 'TVM/'). Asked from Git, so 8.3 short paths on Windows don't matter."""
    prefix = run(["git", "rev-parse", "--show-prefix"], cwd=TVM_DIR).stdout.strip()
    if not prefix:
        raise TvmError("TVM must be a subfolder of the repository, not its root.")
    return prefix if prefix.endswith("/") else prefix + "/"


def slugify(text, limit=60):
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug[:limit].rstrip("-") or "item"


def write_if_changed(path, content):
    """Write only when content differs, so generators stay idempotent."""
    old = None
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            old = fh.read()
    if old == content:
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(content)
    return True


def fail(msg, code=1):
    print(f"TVM: {msg}", file=sys.stderr)
    sys.exit(code)
