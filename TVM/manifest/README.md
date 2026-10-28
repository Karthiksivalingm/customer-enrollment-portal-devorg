# Manifests

| File | Purpose |
|---|---|
| `package.xml` | Baseline scope: every unmanaged component of the approved types, by explicit name. Rebuild with `python scripts/build_manifest.py`. |
| `releases/DEP-NNN-package.xml` | One manifest per deployment record (create when needed). |

Retrieve the baseline: `python scripts/sf_safe.py project retrieve start --manifest manifest/package.xml --ignore-conflicts --wait 60`
(check `git status` first so no uncommitted work is overwritten). Scope and exclusions: [2026-10/07-Technical/Metadata-Scope.md](../2026-10/07-Technical/Metadata-Scope.md).
