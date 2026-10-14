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
gh repo clone sfdcut/SFDC "C:/Microsoft VS Code/SFDC"          # shared repo: FD, MLB, Goodr ...
cd "C:/Microsoft VS Code/SFDC/Goodr"                              # open THIS folder in VS Code (File > Open Folder)
sf org login web --alias GDRSAND --instance-url https://test.salesforce.com      # the Goodr sandbox (partial copy)
sf org login web --alias GDRPROD                                                 # production: read-only unless approved
sf config set target-org GDRSAND
git config core.hooksPath Goodr/scripts/git-hooks                                     # blocks commits containing credentials
```
Never commit org credentials. `.sf/` and `.sfdx/` are git-ignored.

## 2. Read in this order
1. [Project-Rules.md](Project-Rules.md): the rules (process, approvals, data, production, security).
2. [02-Knowledge-Base/Project-Overview.md](../02-Knowledge-Base/Project-Overview.md): business context, the Sales Channel / Sector mapping, clusters.
3. [02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding.md](../02-Knowledge-Base/KB-002_Shopify-At-Risk-Offboarding.md): the Shopify automation.
4. [Change records (CR)](../DOCUMENT-INDEX.md#04--change-records): what has changed and when, including production changes.
5. [Conflicts (CON)](../DOCUMENT-INDEX.md#05--conflicts): known problems and traps. **Read all of it.**
6. [07-Technical/](../07-Technical/): the cluster engine, integrations, and inventories of classes, triggers and flows.
7. [Requirements (REQ)](../DOCUMENT-INDEX.md#03--requirements): what's open.

## 3. Your first task, step by step
1. Create a REQ document for the request (next free number in `DOCUMENT-INDEX.md`).
2. `git pull`, then **retrieve** the components you'll touch from GDRSAND. The org is the truth, not the repo.
   Use API 68.0 in your manifest (`<version>68.0</version>`): an older version silently drops newer elements from flows and pages.
3. Copy the retrieved files to `04-Change-Records/Before-Snapshots/<date>_<change>/`.
4. Make the smallest change that does the job.
5. `sf project deploy start ... --dry-run --test-level RunSpecifiedTests --tests <TestClass>`
6. Get approval, deploy, and verify (`06-Deployment/Post-Deployment-Checklist.md`).
7. Create a CR document, run `scripts/doc-builders/build_document_index.ps1`, re-run `scripts/doc-builders/build_technical_docs.ps1` if needed, then commit and push.

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
- Changes made by hand in Setup (picklists, formulas, config, data loads) don't show up in git. Record them in a CR document yourself.
- Sector has no field history, so data-load timing can't be reconstructed afterwards. Keep the Data Loader success files.

## 5. Who and where
| Item | Value |
|---|---|
| Sandbox | `GDRSAND`: https://energy-enterprise-8976--partial.sandbox.my.salesforce.com |
| Production | `GDRPROD`: https://energy-enterprise-8976.my.salesforce.com |
| Repository | https://github.com/sfdcut/SFDC (private), folder `Goodr/`. The earlier repo `yogemani/GDRSandbox` is kept but no longer updated |
| Approval phrase for sandbox deploys | "Deploy to Sandbox" |
