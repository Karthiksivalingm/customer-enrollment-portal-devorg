# Manifests

| File | Use |
|---|---|
| `package.xml` | Default project manifest |
| `retrieve/pkg_full_sync_20261013.xml` | **Full sync**: retrieves every class, trigger, flow, page and CMDT record, plus the Sales Channel / Sector / Shopify objects, fields, value sets and email templates. Use it to bring `force-app/` back in line with the sandbox |
| `retrieve/pkg_*.xml` (others) | Manifests used for the October 2026 retrieves and comparisons (including the production checks) |

```bash
sf project retrieve start -x manifest/retrieve/pkg_full_sync_20261013.xml -o GDRSAND --api-version 68.0 --ignore-conflicts
git diff --stat      # shows what changed in the org since the last sync
```
Always keep `<version>68.0</version>` (or the org's current version) in a manifest. Older versions silently drop newer flow and page elements.
