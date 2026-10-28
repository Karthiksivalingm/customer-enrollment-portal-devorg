# MLB project — working guide for Claude Code

Loaded automatically at the start of every session. It is the short version of the rules in `01-Instructions/`; those files are the full, authoritative rules.

## 1. Org and safety

| Rule | Detail |
|---|---|
| Target org | Alias **`MLB Sandbox`** (utdev). Pass `--target-org "MLB Sandbox"` on every `sf` command; never rely on the CLI default. |
| Before each deploy | Confirm the alias and URL. Retrieve the component first and compare it with the local copy. |
| Production | **Never touch it.** Only with the project lead's approval for that specific change. |
| Validate first | Use `sf project deploy validate ... -l RunSpecifiedTests` for test runs, so nothing is saved. |
| Outbound actions | Never send real emails or Adobe agreements during tests. Stop before a final Save or Send unless that step is what's being tested. |
| Test data | Snapshot → test → restore → compare field by field (0 differences) → delete temporary records. |
| Ask first | Bulk data changes, user records, permissions for groups of users, deleting or deactivating automation, anything outward-facing. |

## 2. Every requirement prompt

| Step | What to do | Read |
|---|---|---|
| 1. Check the history | Search the **Requirement lookup** in `DOCUMENT-INDEX.md` by title and keywords. | `DOCUMENT-INDEX.md` |
| 2a. It exists | Open **only** that month's `MONTH-INDEX.md` row and the documents it links to. Don't search other months. | `YYYY-MM/MONTH-INDEX.md` |
| 2b. It's new | Take the next free numbers from `DOCUMENT-INDEX.md`; file it in the current month (create the month folder with the full structure if needed). | — |
| 3. Find components | For "what touches object X?", check the component inventory before searching the code. | `TECH-005_Component-Inventory.md` |
| 4. Investigate and build | Follow the workflow and coding rules. | `AI-Workflow.md`, `Coding-Standards.md` |
| 5. Report | What changed (created / modified / deleted), what was verified, what failed, open questions. | `Project-Rules.md` section 10 |

Re-read an instruction file in full whenever `git log` shows it changed since it was last read.

## 3. After the project lead says "all good" (never before)

| Order | Output | Where | Rule |
|---|---|---|---|
| 1 | CR for each change | `YYYY-MM/04-Change-Records` | Date, deploy ID, components, verification, rollback |
| 2 | REQ, TECH, CON created or updated | `YYYY-MM/03-Requirements`, `07-Technical`, `05-Conflicts` | Old requirement: update the original in place; new CR in the current month |
| 3 | KB if the background changed | root `02-Knowledge-Base` | Common to all months, updated in place |
| 4 | ATR: run every scenario in the backend | `YYYY-MM/08-QA/01-Automated-Testing` | Positive, negative, bulk (200), permissions; evidence; cleanup |
| 5 | MTC: manual test cases (.md + screenshots) | `YYYY-MM/08-QA/02-Manual-Testing` | Expected result = verified automated result; Actual and Status left blank |
| 6 | Indexes | `MONTH-INDEX.md`, `DOCUMENT-INDEX.md` | Requirement row, lookup row, next free numbers |
| 7 | Monthly tracker, **last** | `YYYY-MM/YYYY-MM_Tracker.xlsx` | `& scripts\tracker\Build-MonthTracker.ps1 -Month YYYY-MM`; never edit by hand |
| 8 | Commit and push | GitHub | Section 4 |
| — | DEP document | `YYYY-MM/06-Deployment` | Only when something is actually deployed to production |

Naming: `PREFIX-###_Short-Title.md`. Serial numbers run across months and are never reused. QA test IDs: `TC-<REQ number>-<scenario>`, the same in the ATR and the MTC.

## 4. GitHub

| Item | Value |
|---|---|
| Repository | `sfdcut/SFDC`, branch `main`; never create branches |
| Folder | `MLB/` only; never add, edit or delete anything in other teams' folders |
| Local clone | `C:\Users\UTIS\Documents\SFDC-repo` |
| 1. Sync | `robocopy C:\Users\UTIS\Documents\MLB C:\Users\UTIS\Documents\SFDC-repo\MLB /MIR /XD .git .sf .sfdx node_modules .claude /NFL /NDL /NJH /NP` |
| 2. Stage | `git add -A MLB 2>$null`, then check that nothing outside `MLB/` is staged |
| 3. Commit | Message starts `MLB:`; ends with the Co-Authored-By line |
| 4. Push | `git pull --ff-only origin main`, then `git push origin main` |
| When | After every document change, unless the project lead asks to see it first |
| Never commit | `.sf/`, `.sfdx/`, `.claude/`, credentials, secrets |

## 5. Saving tokens

| Habit | Why it saves tokens |
|---|---|
| Grep for the ID (for example `REQ-014`), then read only the matching lines with offset and limit | Indexes and documents run to 15–23 KB; one row is under 1 KB |
| Don't open ATR or MTC files unless doing a retest | They are the largest documents |
| Read each instruction file only at the step that needs it, once per session | The four files total about 11k tokens |
| Don't re-read a file just edited | The edit tool already confirms the change |
| Keep command output short: quiet flags, `Select-Object -First N`, `--json` with only the needed fields | Long tool output stays in context for the rest of the session |
| Hide git line-ending warnings with `2>$null` on `git add` | One sync otherwise prints 100+ warning lines |
| Screenshots only for MTC documents | Images cost far more than text |
| `/clear` after each finished requirement | The next requirement starts with only this file, memory and the indexes |
| Use absolute paths in .NET calls (`[IO.File]::...`) | Its current directory differs from PowerShell's; wrong paths waste retries |
