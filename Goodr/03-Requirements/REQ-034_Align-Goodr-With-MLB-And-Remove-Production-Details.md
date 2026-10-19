# REQ-034 — Align Goodr with the MLB folder structure and remove production details

| | |
|---|---|
| **ID** | REQ-034 |
| **Status** | ✅ Done |
| **Requested** | 2026-10-19 |
| **Related** | [CR-025](../04-Change-Records/CR-025_Align-With-House-Standard-And-Remove-Production-Details.md) |

## Business need
The Goodr folder in the shared repository must follow the same folder names and layout as the MLB project, with no unwanted folders. It must contain no production details.

## Scope
- **In:** folder and file names, removal of non-standard folders, removal of every production reference in documents and workbooks.
- **Out:** other project folders; the Salesforce metadata in `force-app/`.

## Acceptance criteria
1. Every folder in `Goodr/` has the same name and sub-structure as in `MLB/`.
2. `01-Instructions` contains the same three files as MLB.
3. No production org alias, URL, username, package or production record remains in `Goodr/`.

## Output
[CR-025](../04-Change-Records/CR-025_Align-With-House-Standard-And-Remove-Production-Details.md)

## Open questions
- Git history still contains the earlier production material. Removing it from history would mean rewriting the shared repository's history.
