# KB-006 — Developer Onboarding

| | |
|---|---|
| **Document ID** | KB-006 |
| **Last updated** | 2026-10-19 |

This guide is for a developer joining the Goodr Salesforce project. Work through it in order; it takes about an hour.

## 1. Set up your machine
| Tool | How to install | Check |
|---|---|---|
| Git | `winget install Git.Git` | `git --version` |
| GitHub CLI | `winget install GitHub.cli`, then `gh auth login` | `gh auth status` |
| Salesforce CLI | https://developer.salesforce.com/tools/salesforcecli | `sf --version` |
| VS Code + Salesforce Extension Pack | VS Code Marketplace | n/a |

```bash
gh repo clone sfdcut/SFDC "C:/Microsoft VS Code/SFDC"     # shared repo, one folder per project
cd "C:/Microsoft VS Code/SFDC/Goodr"                         # open THIS folder in VS Code (File > Open Folder)
sf org login web --alias GDRSAND --instance-url https://test.salesforce.com
sf config set target-org GDRSAND
```
Never commit org credentials. `.sf/` and `.sfdx/` are git-ignored.

## 2. Read in this order
1. [Project-Rules.md](../01-Instructions/Project-Rules.md), [AI-Workflow.md](../01-Instructions/AI-Workflow.md), [Coding-Standards.md](../01-Instructions/Coding-Standards.md): how all work is done.
2. [Project Overview](Project-Overview.md): business context, the Sales Channel / Sector mapping, clusters.
3. [Business Process](Business-Process.md): the Shopify at-risk automation.
4. [Change records (CR)](../DOCUMENT-INDEX.md#04--change-records): what has changed in the sandbox, and when.
5. [Conflicts (CON)](../DOCUMENT-INDEX.md#05--conflicts): known problems and traps. **Read all of them.**
6. [07-Technical](../07-Technical/): the cluster engine and inventories of classes, triggers, flows and fields.
7. [08-QA](../08-QA/README.md): test reports and manual test cases.

## 3. Your first task
Follow [AI-Workflow.md](../01-Instructions/AI-Workflow.md) and [Project-Rules.md](../01-Instructions/Project-Rules.md). Specific to Goodr:
- Retrieve from GDRSAND with `<version>68.0</version>` in the manifest. An older version silently drops newer elements from flows and pages.
- Deploy to the sandbox only after the approval phrase "Deploy to Sandbox".

## 4. Lessons learned on this project
**Salesforce**
- Renaming a picklist value in Setup updates records, but **removes the old value from report filters** without warning. Re-check the reports afterwards.
- Pages can't reference **inactive** picklist values in visibility filters. The deploy fails with "invalid field value".
- Use `RunSpecifiedTests` with one `--tests` flag per class; a comma-separated list is rejected.
- `ClusterRuleEngine` applies the **first** matching rule, so cluster rules must never overlap.
- Several triggers on one object have no guaranteed order (Account, Lead, Contact, Case, EmailMessage).
- The Typeform lead flow has no fault path, so a failure rolls back the Lead insert.
- Running the at-risk notice batch by hand sends real emails.

**Testing without leaving data behind**
- Anonymous Apex pattern: insert test records, collect the results, then `throw new StopAndRollbackException('RESULTS>>' + ... + '<<')`.
  The class name must end in `Exception`. Debug logs encode `|` as `&#124;`.

**Tooling on this machine**
- There's no Python or Node. Excel files are built with Excel 2007 COM from PowerShell. Write cells one at a time with `.Formula`, and avoid em-dashes, which cut off cell text in Excel 2007.
- Close a workbook in Excel before a script rewrites it.

**Records**
- Changes made by hand in Setup (picklists, formulas, config, data loads) don't show up in source control. Record them in a CR document.
- Sector has no field history, so data-load timing can't be reconstructed afterwards. Keep the Data Loader success files.

## 5. Who and where
| Item | Value |
|---|---|
| Sandbox | `GDRSAND`: https://energy-enterprise-8976--partial.sandbox.my.salesforce.com |
| Repository | https://github.com/sfdcut/SFDC (private), folder `Goodr/` |
| Approval phrase for sandbox deploys | "Deploy to Sandbox" |
