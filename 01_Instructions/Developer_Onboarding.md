# Developer Onboarding: read this before you start

This guide is for a developer joining the Goodr Salesforce project. Work through it in order; it takes about an hour.

## 1. Set up your machine
| Tool | How to install | Check |
|---|---|---|
| Git | `winget install Git.Git` | `git --version` |
| GitHub CLI | `winget install GitHub.cli`, then `gh auth login` (choose browser / device code) | `gh auth status` |
| Salesforce CLI | https://developer.salesforce.com/tools/salesforcecli | `sf --version` |
| VS Code + Salesforce Extension Pack | VS Code Marketplace | n/a |
| Claude Code (optional) | VS Code extension | It loads `CLAUDE.md` automatically |

```bash
gh repo clone yogemani/GDRSandbox "C:/Microsoft VS Code/GDRSandbox"
cd "C:/Microsoft VS Code/GDRSandbox"
sf org login web --alias GDRSAND --instance-url https://test.salesforce.com      # the Goodr sandbox (partial copy)
sf org login web --alias GDRPROD                                                 # production: read-only unless approved
sf config set target-org GDRSAND
git config core.hooksPath scripts/git-hooks                                     # blocks commits containing credentials
```
Never commit org credentials. `.sf/` and `.sfdx/` are git-ignored.

## 2. Read in this order
1. [Working_Instructions.md](Working_Instructions.md): the rules (process, approvals, data, production, security).
2. [02_Knowledge_Base/Project_Overview.md](../02_Knowledge_Base/Project_Overview.md): business context, the Sales Channel / Sector mapping, clusters.
3. [02_Knowledge_Base/Shopify_At_Risk_Offboarding.md](../02_Knowledge_Base/Shopify_At_Risk_Offboarding.md): the Shopify automation.
4. [04_Change_Records/Change_Log.md](../04_Change_Records/Change_Log.md): what has changed and when, including production changes.
5. [05_Conflicts/Conflicts_Log.md](../05_Conflicts/Conflicts_Log.md): known problems and traps. **Read all of it.**
6. [07_Technical_Documents/](../07_Technical_Documents/): the cluster engine, integrations, and inventories of classes, triggers and flows.
7. [03_Requirements/Requirements_Log.md](../03_Requirements/Requirements_Log.md): what's open.

## 3. Your first task, step by step
1. Add the request to `03_Requirements/Requirements_Log.md`.
2. `git pull`, then **retrieve** the components you'll touch from GDRSAND. The org is the truth, not the repo.
   Use API 68.0 in your manifest (`<version>68.0</version>`): an older version silently drops newer elements from flows and pages.
3. Copy the retrieved files to `04_Change_Records/Metadata_Before_Snapshots/<date>_<change>/`.
4. Make the smallest change that does the job.
5. `sf project deploy start ... --dry-run --test-level RunSpecifiedTests --tests <TestClass>`
6. Get approval, deploy, and verify (`06_Deployment/Post_Deployment_Checklist.md`).
7. Add a CHG entry to `04_Change_Records/Change_Log.md`, re-run `scripts/doc-builders/build_technical_docs.ps1` if needed, then commit and push.

## 4. Lessons learned on this project
**Salesforce**
- Renaming a picklist value in Setup updates records, but **removes the old value from report filters** without warning. Re-check the reports afterwards.
- Pages can't reference **inactive** picklist values in visibility filters, and the deploy fails with "invalid field value".
  Production validation fails the same way until the values exist there.
- Production doesn't allow `NoTestRun`. Use `RunSpecifiedTests` and pass a separate `--tests` flag for each class (a comma list is rejected).
- Don't build production packages from sandbox files. The sandbox has unapproved work (R12, Fulfillment, Order Channel, Tiers fields) and sandbox users in the team records.
- `ClusterRuleEngine` applies the **first** matching rule, so cluster rules must never overlap.
- Several triggers on one object have no guaranteed order (Account, Lead, Contact, Case, EmailMessage).
- The flow on Typeform forms has no fault path, so a failure rolls back the Lead insert.
- Running the notice batch by hand sends real emails.

**Testing without leaving data behind**
- Anonymous Apex pattern: insert test records, collect the results, then `throw new StopAndRollbackException('RESULTS>>' + ... + '<<')`.
  The class name must end in `Exception`. Debug logs encode `|` as `&#124;`. Scripts: `scripts/apex/verification/`.

**Tooling on this machine**
- There's no Python or Node. Excel files are built with Excel 2007 COM from PowerShell (`scripts/doc-builders/`). Write cells one at a time with `.Formula`, and avoid em-dashes, which cut off cell text in Excel 2007.
- PowerShell aliases (`R`, `SC`) clash with short function names, so use longer names.
- Close a workbook in Excel before a script rewrites it.

**Records**
- Salesforce keeps deploy history for about 30 days and the Setup Audit Trail for 180 days. Run `scripts/doc-builders/build_org_change_history.ps1` regularly so the history is kept in git.
- Changes made by hand in Setup (picklists, formulas, config, data loads) don't show up in git. Log them in the change log yourself.
- Sector has no field history, so data-load timing can't be reconstructed afterwards. Keep the Data Loader success files.

## 5. Who and where
| Item | Value |
|---|---|
| Sandbox | `GDRSAND`: https://energy-enterprise-8976--partial.sandbox.my.salesforce.com |
| Production | `GDRPROD`: https://energy-enterprise-8976.my.salesforce.com |
| Repository | https://github.com/yogemani/GDRSandbox (private) |
| Approval phrase for sandbox deploys | "Deploy to Sandbox" |
