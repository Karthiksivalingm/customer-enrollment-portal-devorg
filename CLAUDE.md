# Goodr Salesforce: instructions for Claude

Read and follow [01-Instructions/Project-Rules.md](01-Instructions/Project-Rules.md) before making any change.

Key points:
- The sandbox is `GDRSAND` and production is `GDRPROD`. Treat production as read-only unless a deployment was approved.
- Retrieve, back up, make the minimal change, run a check-only deploy, then ask. Deploy only after the user says **"Deploy to Sandbox"**.
- Don't change record data unless asked. Existing working logic must not change.
- File everything in the numbered folders: 01 Instructions, 02 Knowledge Base, 03 Requirements, 04 Change Records,
  05 Conflicts, 06 Deployment, 07 Technical, as one numbered document per item (REQ-, CR-, CON-, DEP-, TECH-, KB-).
  Take the next free number from DOCUMENT-INDEX.md, then rebuild it with `scripts/doc-builders/build_document_index.ps1`.
- `01-Instructions/AI-Workflow.md` and `Coding-Standards.md` are shared across FD, MLB and Goodr: follow them, never edit them.
- Project background: [02-Knowledge-Base/Project-Overview.md](02-Knowledge-Base/Project-Overview.md).
- New to the project? Read [01-Instructions/Developer-Onboarding.md](01-Instructions/Developer-Onboarding.md). The full dated history of changes is in [DOCUMENT-INDEX.md#04--change-records](DOCUMENT-INDEX.md#04--change-records).
- After every org change (a deploy, a Setup change or a data load), create a CR document in `04-Change-Records/` the same day and rebuild `DOCUMENT-INDEX.md`. Before production work, re-run `scripts/doc-builders/build_org_change_history.ps1`.
- Retrieve with API 68.0 (`<version>68.0</version>`). Older versions drop flow and page elements.
