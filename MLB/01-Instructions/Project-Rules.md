# Project Rules

How every Salesforce project is run: where work happens, how it is documented, tested and stored, and what needs approval first. These rules apply to people and AI tools alike.

The process for building a change is in [AI-Workflow.md](AI-Workflow.md). The rules for the code itself are in [Coding-Standards.md](Coding-Standards.md). This file covers everything around them.

**Order of precedence:** an explicit instruction from the project lead for a specific task comes first, then these rules, then the other instruction files.

---

## 1. Environments

- **Work in the agreed sandbox only.** Every build, deployment, test and data change happens in the sandbox named for the project.
- **Never touch production** unless the project lead has approved that specific change for production. Approval for one change doesn't cover the next.
- **Confirm the target org before every deployment.** Check the org alias and URL first, every time.
- **Retrieve before you edit.** Before changing an existing component, retrieve it from the org and compare it with the local copy. If they differ, find out why before going further.
- **Know what's different about production.** Some configuration exists only in production (for example integration templates or scheduled jobs). Record those differences in the knowledge base and in the test documents, so testers know what can and can't be tested in the sandbox.

## 2. Project folders (monthly)

The instructions and the knowledge base are **common** and sit at the project root. All other documents are stored **by month**: each month folder (`YYYY-MM`, for example `2026-10`) has the same structure.

```
<project>/
├── 01-Instructions/          common: how work is done (read-only)
├── 02-Knowledge-Base/        common: project background, environments, users, guides
├── DOCUMENT-INDEX.md         master index: months, requirement lookup, next free numbers, knowledge base, living documents
├── force-app/ …              Salesforce metadata source and project config
└── YYYY-MM/                  one folder per month
    ├── MONTH-INDEX.md        the month's history: every requirement, its documents, components and status
    ├── 03-Requirements/  04-Change-Records/  05-Conflicts/  06-Deployment/
    └── 07-Technical/  08-QA/01-Automated-Testing/  08-QA/02-Manual-Testing/
```

| Folder | Prefix | What goes in it |
|---|---|---|
| `01-Instructions` (root) | — | How work is done: AI-Workflow, Coding Standards, Project Rules, QA Process. Read-only; change only when the project lead asks. |
| `02-Knowledge-Base` (root) | `KB-` | Background: project overview, business process, integrations, environments, users, user guides. Common to all months; update in place. |
| `YYYY-MM/03-Requirements` | `REQ-` | One document per requirement: need, scope, behaviour, acceptance criteria, assumptions, open questions |
| `YYYY-MM/04-Change-Records` | `CR-` | One record per change made to an org: what changed, when, deploy ID, verification, rollback |
| `YYYY-MM/05-Conflicts` | `CON-` | Problems, clashes with existing automation or standards, open risks |
| `YYYY-MM/06-Deployment` | `DEP-` | Deployment documents, created only when something is actually deployed to production |
| `YYYY-MM/07-Technical` | `TECH-` | Technical design and component detail |
| `YYYY-MM/08-QA` | `ATR-` / `MTC-` | Automated test reports and manual test case documents (see section 6 and [QA-Process.md](QA-Process.md)) |
| `force-app/` (root) | — | Salesforce metadata source |

**Which month a document belongs to:**
- A new document goes in the month it is **first created**. Create the month folder, with the full structure and a `MONTH-INDEX.md`, the first time something is filed in a new month.
- When an existing requirement changes in a later month, **update its documents where they are** (in their original month). New change records (CR), test retests and similar new documents for that change go in the **current** month, and both months' `MONTH-INDEX.md` files note the link.
- **Knowledge base documents** are not filed by month; they go in the root `02-Knowledge-Base` and are updated in place. Mention a new or changed KB document in the current month's `MONTH-INDEX.md` summary.
- **Living documents in month folders** (component inventory, open-items list) stay in the month they were created and are updated in place. `DOCUMENT-INDEX.md` lists where each one is.

## 3. Every requirement: read the instructions, then check the history first

For every requirement prompt, before any investigation or build:
1. **Read the instruction files** in `01-Instructions` and follow them.
2. **Check whether the requirement already exists:** search the **Requirement lookup** table in `DOCUMENT-INDEX.md` (title and keywords).
3. **If it exists,** open only that month's `MONTH-INDEX.md` and the documents it links to. Do not search through every month, folder or file; this keeps the work fast and avoids reading unrelated documents.
4. **If it is new,** treat it as a new requirement: take the next free numbers from `DOCUMENT-INDEX.md` and file its documents in the current month.
5. **Only if the lookup is inconclusive,** search the most likely month first, then widen.

## 4. Document control

- **Naming:** `PREFIX-###_Short-Title-With-Hyphens.md`, for example `REQ-005_Signed-Agreement-Email.md`. Word documents use the same name with `.docx`.
- **Serial numbers are never reused.** A cancelled or reverted item keeps its number and is marked as such.
- **Update or create:** update an existing document when its topic changes; use the next free number for a new topic.
- **Link everything.** Every document links to its related REQ, CR, TECH, CON, DEP and QA documents.
- **Serial numbers run across months.** REQ-019 can follow REQ-018 in a new month; numbers are not restarted per month.
- **Keep the indexes current, in the same change as the document:**
  - the month's `MONTH-INDEX.md`: the requirement history row (REQ, title, keywords, objects and main components, status, related CR / CON / TECH / ATR / MTC) and the document lists
  - the root `DOCUMENT-INDEX.md`: the requirement lookup row (REQ, title, keywords, month, status), the month summary, the next free numbers, the knowledge-base list and the living-documents list
- **Write for the reader.** Requirement and user documents use the client's terms. Don't mention internal tools, other clients or other projects' environments in a project's documents.

## 5. When documents are written

- **Only after the requirement is confirmed working.** While a requirement is being built or changed, don't write its documents. When the project lead confirms it works (for example "all good"), document it as the next step.
- **What to write on confirmation:**
  1. a change record (CR) for each change made
  2. the requirement (REQ), technical design (TECH) and any conflicts (CON) created or updated
  3. the knowledge base (KB) updated if the background changed
  4. the QA documents (section 6)
  5. the month's `MONTH-INDEX.md` and the root `DOCUMENT-INDEX.md` updated
- **Deployment documents (DEP)** are written only when a deployment to production actually happens.
- **Finish with a list** of the documents created or updated.

## 6. Quality assurance

Run on the same confirmation as the documents. The full process, file layouts and test-case columns are in [QA-Process.md](QA-Process.md). Each scenario has one ID used in both QA documents, for example `TC-014-03` (requirement REQ-014, scenario 3).

**Automated testing**: `YYYY-MM/08-QA/01-Automated-Testing/ATR-###_<Requirement>.md`
- Run every scenario against the sandbox: positive, negative, bulk (200 records) and permission cases, as an administrator and as the real user profiles.
- Record for each scenario: test ID, scenario, type of test, user it ran as, input, expected result, actual result, pass or fail.
- Include the evidence: deploy IDs, Apex test results and coverage, query output.
- Record the test data created and confirm it was removed.

**Manual test cases**: `YYYY-MM/08-QA/02-Manual-Testing/MTC-###_<Requirement>.md`, with screenshots in `MTC-###_screenshots/`
- Written for the manual QA tester, one table row per scenario, with these columns:

| Test ID | Scenario | Preconditions | Front-end steps (with screenshots) | Backend check | Test data | Expected result | Actual result | Status |
|---|---|---|---|---|---|---|---|---|

- The **expected result** is the verified outcome from the automated run.
- **Actual result** and **Status** are left blank for the tester.
- End with a summary of all scenarios and a sign-off section.

## 7. Test data in the sandbox

- **Create the minimum test data** you need, and delete or restore it as soon as the test is finished.
- **Restore anything you change** on existing records to its original value, and confirm the restore with a query.
- **Don't trigger real outbound actions** while testing: no emails to real people, no agreements sent for signature, no external calls, unless the test needs it and the project lead has approved it.
- **When capturing screenshots,** stop before the final Save or Submit unless that step is what's being shown. If something is saved by mistake, report it straight away and restore it.
- **Keep personal data out of documents** wherever possible. Use test records, and blur or crop real customer details.

## 8. Actions that need approval first

Ask the project lead before doing any of these, even in a sandbox:

- changing user records (emails, passwords, managers, activation) or anything that sends email to real people
- deleting data or updating many records at once
- changing permissions, profiles or permission set assignments for groups of users
- deactivating or deleting existing automation, or changing automation built by others
- anything outward-facing: sending documents, posting to external systems, publishing links
- deploying anything to production

## 9. Version control

- **One shared repository, one folder per project.** Each project lives in its own top-level folder. Change only your project's folder; never add, edit, delete or commit anything in another project's folder.
- **Use the agreed branch.** Don't create branches unless the project lead asks.
- **Pull before you push** so other people's work is never overwritten.
- **Commit after every document is created or updated,** together with the source changes it describes.
- **Write clear commit messages:** start with the project name, then say what changed and why, for example `MLB: REQ-013 Suite Lease MVP label and 40-game option`.
- **Never commit** org login or cache folders (`.sf/`, `.sfdx/`), personal tool settings, credentials or secrets.
- **Check before committing.** Review the list of staged files and confirm nothing outside your project folder is included.

## 10. Reporting

- **Report outcomes as they are.** Say what was done and verified, what failed (with the error), and what was skipped.
- **List the components changed** in every update: created, modified, deleted or deactivated.
- **Flag assumptions and open questions** instead of guessing, and record the unresolved ones in a CON document.
- **Raise conflicts early.** If a requirement clashes with existing automation, a platform limit or another rule, explain the trade-off and recommend an option before building around it.
