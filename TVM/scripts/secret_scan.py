"""Block credentials from entering Git.

Usage (from TVM/):
  python scripts/secret_scan.py <file> [<file> ...]     scan the given files
  python scripts/secret_scan.py --all                   scan every tracked-or-new file under TVM/
Exit 0 = clean, 1 = blocked. Matched values are never printed.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
import tvmlib  # noqa: E402

BLOCKED_PATHS = re.compile(
    r"(^|/)(\.env(\..*)?|\.sf/|\.sfdx/|.*\.(key|pem|p12|jks|pfx|crt)$|.*authurl.*|.*sfdxauthurl.*"
    r"|.*customMetadata/TouchPoint_Callout\..*)",
    re.IGNORECASE,
)
PATTERNS = [
    ("Salesforce session/access token", re.compile(r"00D[A-Za-z0-9]{12,15}![A-Za-z0-9._]{40,}")),
    ("SFDX auth URL", re.compile(r"force://[A-Za-z0-9._~-]+:[A-Za-z0-9._~-]*:[A-Za-z0-9._~-]+@")),
    ("Private key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("GitHub token", re.compile(r"\b(ghp|gho|ghu|ghs|ghr|github_pat)_[A-Za-z0-9_]{20,}")),
    ("Slack token", re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}")),
    ("Google API key", re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("Bearer token", re.compile(r"Bearer\s+[A-Za-z0-9._~+/-]{30,}")),
    ("JWT", re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}")),
    ("Password/secret assignment", re.compile(
        r"""(?i)\b(password|passwd|client_secret|clientsecret|secret_key|api_key|apikey|access_token|refresh_token)\b"""
        r"""\s*[:=]\s*['"][^'"\s]{8,}['"]""")),
    ("Secret value in metadata XML", re.compile(
        r"(?i)<(password|clientSecret|consumerSecret|privateKey|oauthToken|refreshToken)>[^<\s]{6,}</")),
    ("Quickbase user token", re.compile(r"QB-USER-TOKEN\s+[A-Za-z0-9_]{12,}")),
    ("Hardcoded Authorization header (Apex)", re.compile(
        r"""(?i)setHeader\(\s*['"]Authorization['"]\s*,\s*['"][^'"]{12,}['"]""")),
    ("Hardcoded Authorization header value (metadata)", re.compile(
        r"(?is)<parameterName>Authorization</parameterName>.{0,300}?<parameterValue>[^<{]{12,}</parameterValue>"
        r"|<parameterValue>\s*(Bearer|Basic|QB-USER-TOKEN)\s+[^<]{8,}</parameterValue>")),
    ("Custom metadata secret field", re.compile(
        r"(?is)<field>[A-Za-z_]*(token|secret|password|api_key|apikey)[A-Za-z_]*</field>\s*<value[^>]*>[^<]{8,}</value>")),
]
SKIP_EXT = (".png", ".jpg", ".jpeg", ".gif", ".ico", ".zip", ".pdf", ".xlsx", ".woff", ".woff2", ".ttf")
SELF = {"scripts/secret_scan.py"}
ALLOWLIST_PATH = os.path.join(tvmlib.TVM_DIR, "config", "secret-scan-allowlist.json")


def allowlist():
    """Reviewed false positives: {(path, rule)}. Blocked file paths can never be allowlisted."""
    try:
        with open(ALLOWLIST_PATH, encoding="utf-8") as fh:
            return {(e["path"], e["rule"]) for e in json.load(fh).get("entries", [])}
    except (OSError, ValueError, KeyError):
        return set()


def secret_files():
    """Org source files known to hold hardcoded credentials (never committed)."""
    try:
        with open(os.path.join(tvmlib.TVM_DIR, "config", "secret-files.json"), encoding="utf-8") as fh:
            return set(json.load(fh).get("files", []))
    except (OSError, ValueError):
        return set()


def scan_file(path):
    rel = os.path.relpath(path, tvmlib.TVM_DIR).replace("\\", "/")
    findings = []
    if rel in secret_files():
        findings.append("listed in config/secret-files.json (hardcoded credential; must stay out of Git)")
        return findings
    if BLOCKED_PATHS.search(rel):
        findings.append("file type/path must never be committed")
        return findings
    if rel in SELF or rel.lower().endswith(SKIP_EXT) or not os.path.isfile(path):
        return findings
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError:
        return findings
    allowed = allowlist()
    for label, rx in PATTERNS:
        if rx.search(text) and (rel, label) not in allowed:
            findings.append(label)
    return findings


def scan(paths):
    blocked = {}
    for p in paths:
        hits = scan_file(p)
        if hits:
            blocked[os.path.relpath(p, tvmlib.TVM_DIR).replace("\\", "/")] = hits
    return blocked


def all_files():
    out = []
    for root, dirs, files in os.walk(tvmlib.TVM_DIR):
        dirs[:] = [d for d in dirs if d not in (".git", ".sf", ".sfdx", "node_modules", ".tvm-state")]
        out += [os.path.join(root, f) for f in files]
    excluded = secret_files()  # known, git-ignored credential files are reported by CON-002, not here
    return [p for p in out if os.path.relpath(p, tvmlib.TVM_DIR).replace("\\", "/") not in excluded]


if __name__ == "__main__":
    args = sys.argv[1:]
    files = all_files() if args == ["--all"] else [os.path.abspath(a) for a in args]
    result = scan(files)
    if result:
        print("SECRET CHECK FAILED. Nothing was committed. Remove these values (keep them in the org only):")
        for f, hits in sorted(result.items()):
            print(f"  - {f}: {', '.join(hits)}")
        sys.exit(1)
    print(f"Secret check passed ({len(files)} files).")
