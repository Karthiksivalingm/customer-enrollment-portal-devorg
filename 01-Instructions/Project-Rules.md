# Working Instructions: Goodr Salesforce

These rules apply to anyone working in this repository, including Claude. `CLAUDE.md` at the repo root points here,
so Claude Code loads these rules automatically.

## 1. Orgs

| Alias | Org | Use |
|---|---|---|
| `GDRSAND` | Goodr sandbox | All development and testing. This repo mirrors this org. |
| `GDRPROD` | Goodr production | **Read-only** unless a production deployment has been approved. Only validate (check-only) here. |

## 2. Change process (follow for every change)

1. **Understand the requirement.** Create a REQ document in `03-Requirements/` (next free number in `DOCUMENT-INDEX.md`) before starting.
2. **Retrieve the latest version** of each component from the org. Never edit a stale local copy.
3. **Back it up.** Copy the retrieved files to `04-Change-Records/Before-Snapshots/<yyyy-mm-dd>_<Change>/`.
4. **Make the minimal change.** Existing working logic must not change. Don't refactor or rename beyond the request.
5. **Check-only deploy** (`--dry-run`), with the relevant tests. Then ask for confirmation.
6. **Deploy only after explicit approval.** The approval phrase for the sandbox is **"Deploy to Sandbox"**.
   Production needs its own separate approval.
7. **Verify after the deploy**: run tests, check a live record, cluster and team assignment, and page sections.
   Save the evidence in `06-Deployment/Post-Deployment-Verification/`.
8. **Record it.** Create a CR document in `04-Change-Records/` with the deploy ID, add a CON document for any conflict,
   and update `07-Technical/` if behaviour changed.

Work **component by component**. Don't combine unrelated changes in one deploy.

## 3. Data rules

- **Don't change record data unless it was explicitly approved.** Metadata changes and data loads are separate approvals.
- Before any data load, export the current values (before) and keep a rollback file.
- Run a pilot load (one record per mapping) before the full load.
- Before running a production load, the client takes a full data warehouse (DWH) download.

## 4. Production rules

- Build production packages from **production's own files**, not sandbox files. The sandbox has unapproved work, such as R12, Fulfillment and Tiers fields on pages.
- Production does not allow `NoTestRun`. Use `RunSpecifiedTests` and pass a separate `--tests` flag for each class.
- Create picklist values **before** deploying pages or filters that reference them.
- Every production package needs a matching `_ROLLBACK` package in `06-Deployment/Packages/`.

## 5. Security

- Never commit passwords, tokens, keys or org auth files. `NetSuite_Credential` and `NetSuite_Config` records are git-ignored and force-ignored; placeholder templates are in `07-Technical/Secure-Config-Templates/`.
- Enable the secret-blocking hook once per clone: `git config core.hooksPath Goodr/scripts/git-hooks`.
- Never paste credentials into chat, documents or commit messages. If one is exposed, rotate it.
- The repository is **private**. Keep it private.

## 6. Git conventions

- `main` always matches what's deployed in the sandbox. Do new work on a branch (`goodr/feature/REQ-0xx-name`, `goodr/fix/...`, `goodr/docs/...`; the `goodr/` prefix keeps Goodr branches apart from FD and MLB in the shared repo) and merge it with a pull request (template in `.github/`).
- Tags mark milestones: `goodr-sandbox-baseline-YYYY-MM-DD` (a full sync with GDRSAND) and `goodr-prod-YYYY-MM-DD-<name>` (each production deployment).
- Never force-push `main`. The one exception was the approved credential purge on 2026-10-13 (CR-022).
- One commit per logical change. Write the message in the imperative, e.g. "Add Planned to Company page filters".
- Put files in the correct numbered folder (see `Goodr/README.md` and `DOCUMENT-INDEX.md`). Keep Salesforce source in `force-app/` only.
- Push after each completed change so GitHub stays current.

## 7. Writing style for documents

- Use plain English and short sentences. Start with the result.
- Excel is for anything the client or QA team works through: test cases, record lists, component lists.
- Use Markdown (in this repo) for instructions, logs and technical reference.
