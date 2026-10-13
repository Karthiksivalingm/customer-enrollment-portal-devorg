# Change Log

Add the newest change at the top.

| CR ID | Date | Type | Title | Components / objects | Requirement | Made by | Commit | Deployed to |
|---|---|---|---|---|---|---|---|---|
| CR-0001 | 2026-10-13 | Repository | Initial baseline of EverquoteFullSandbox metadata in GitHub, plus the documentation structure | 764 files: 160 Apex classes, 33 triggers, 4 flows, 18 workflow files, 121 process flow migrations, 111 permission sets, 2 profiles, 103 queues | REQ-0001 | sasikumarm-web | f9c91cf | n/a |

## CR-0001 details

- **Before:** the metadata existed only in the local folder, with no version control.
- **After:** the metadata is in the private GitHub repository `sasikumarm-web/EverquoteFullSandbox` on the `main` branch.
- **Kept out of Git** (excluded by `.gitignore`): `*.xlsx`, `*.docx`, `ApexClass_BusinessSummary.csv`, `.sf/` and `.sfdx/`.
- **Rollback:** not applicable. No org metadata or data was changed.
