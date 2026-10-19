# REQ-001 — Align Everquote with the MLB folder standard (sandbox-only content)

| | |
|---|---|
| **ID** | REQ-001 |
| **Status** | ✅ Done |
| **Requested** | 2026-10-19 |
| **Related** | [CR-001](../04-Change-Records/CR-001_Align-With-House-Standard.md) |

## Business need
The Everquote folder in the shared repository must use the same folder names and layout as the MLB project, with no unwanted folders. It must contain no production details.

## Scope
- **In:** folder and file names, removal of non-standard folders, production org links in `force-app/` metadata, the project login URL.
- **Out:** other project folders; employee email addresses in dashboards, queues and workflow alerts (kept: they are sandbox configuration, not production data).

## Acceptance criteria
1. Every folder in `Everquote/` has the same name and sub-structure as in `MLB/`.
2. `01-Instructions` contains the same three files as MLB.
3. No production org domain, production instance URL or production org ID remains in `Everquote/`.

## Output
[CR-001](../04-Change-Records/CR-001_Align-With-House-Standard.md)

## Open questions
- Git history still contains the earlier production links. Removing them from history would mean rewriting the shared repository's history.
