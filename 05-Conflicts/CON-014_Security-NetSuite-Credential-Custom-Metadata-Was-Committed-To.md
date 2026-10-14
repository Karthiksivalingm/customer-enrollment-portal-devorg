# CON-014 — Security: NetSuite credential custom metadata was committed to git

| | |
|---|---|
| **ID** | CON-014 |
| **Status** | ⚠ Open (rotate NetSuite keys) |
| **Found** | 2026-10-12 |
| **Area** | Security |

## Conflict
NetSuite credential custom metadata was committed to git (first two commits, old IDs 88fb123 and 246a9f2)

## Resolution
2026-10-12: removed from tracking, git-ignored and force-ignored. 2026-10-13: placeholder templates and a pre-commit hook added. 2026-10-13: history purged and force-pushed (commit IDs changed). **Open: rotate the NetSuite sandbox keys; ask GitHub Support to purge the cached old commits**
