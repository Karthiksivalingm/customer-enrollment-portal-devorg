# Arizona scripts (Node.js)

Run from the `Arizona/` folder. None of these scripts change the org, and none run Git commands.

| Script | Purpose |
|---|---|
| `verify-org.js` | Checks alias `Arizona` → Org ID `00DWH000005wW9V2AU`, expected username, `IsSandbox = true`. Exit 1 on mismatch. |
| `list-org-metadata.js` | Verifies the org, then lists unmanaged components of the in-scope types into `.arizona-state/org-listing.json` (Git-ignored). |
| `build-manifest.js` | Builds `manifest/package.xml` and `manifest/batches/*.xml` from the listing and the scope rules in `config/arizona-project.json`. |
| `build-inventory.js` | Generates `07-Technical-Documents/Metadata-Inventory.md` from the local source and rebuilds `DOCUMENT-INDEX.md`. |
| `secret-scan.js` | Scans for credential-like values; prints file, line and rule only. Allow-list: `config/secret-scan-allowlist.json`. |
| `new-doc.js` | Creates a dated REQ / CR / CF / DEP record from `config/templates/` with the next free ID. |
| `lib/org.js` | Shared paths, config, `sf --json` wrapper and the org guard. |
