# Manifests

| File | Purpose |
|---|---|
| `package.xml` | Full Epicare scope: every unmanaged component of the in-scope types, by explicit name, plus reports, dashboards and email templates in public folders. Rebuild with `python scripts/build_manifest.py` (read-only against UTDEV). |
| `releases/DEP-NNN-package.xml` | One manifest per deployment record (create when needed). |

Retrieve: `python scripts/retrieve.py` (batches, verifies UTDEV before each batch, refuses to overwrite uncommitted source).
Then `python scripts/check_retrieval.py`. Scope: [07-Technical-Documents/Metadata-Scope.md](../07-Technical-Documents/Metadata-Scope.md).
