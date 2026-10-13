# Goodr Salesforce: instructions for Claude

Read and follow [01_Instructions/Working_Instructions.md](01_Instructions/Working_Instructions.md) before making any change.

Key points:
- The sandbox is `GDRSAND` and production is `GDRPROD`. Treat production as read-only unless a deployment was approved.
- Retrieve, back up, make the minimal change, run a check-only deploy, then ask. Deploy only after the user says **"Deploy to Sandbox"**.
- Don't change record data unless asked. Existing working logic must not change.
- File everything in the numbered folders: 01 Instructions, 02 Knowledge Base, 03 Requirements, 04 Change Records,
  05 Conflicts, 06 Deployment, 07 Technical Documents.
- Project background: [02_Knowledge_Base/Project_Overview.md](02_Knowledge_Base/Project_Overview.md).
- New to the project? Read [01_Instructions/Developer_Onboarding.md](01_Instructions/Developer_Onboarding.md). The full dated history of changes is in [04_Change_Records/Change_Log.md](04_Change_Records/Change_Log.md).
- After every org change (a deploy, a Setup change or a data load), add a CHG entry to the change log the same day. Before production work, re-run `scripts/doc-builders/build_org_change_history.ps1`.
- Retrieve with API 68.0 (`<version>68.0</version>`). Older versions drop flow and page elements.
