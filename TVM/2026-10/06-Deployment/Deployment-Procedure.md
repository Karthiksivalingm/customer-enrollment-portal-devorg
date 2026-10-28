# Deployment Procedure

Applies to every metadata deployment from this repository. The only target is the TVM Fullsandbox (`Fullsandbox`,
`00DVa000006Eh6TMAS`). Production is out of scope: it follows a separate, human-controlled release process.

## Statuses are separate
Each DEP record tracks four statuses independently, each with its own evidence: **Preparation → Approval → Execution → Verification**.
A completed preparation is not an approval. An approval covers only the exact components and target it names.

## Steps
1. **Create the record:** `python scripts/new_doc.py DEP "<what is being deployed>"`. Link the approved REQ records.
2. **Component inventory:** list every component (type, API name, action, source path) in dependency order. Write the release manifest
   `manifest/releases/DEP-NNN-package.xml` (and `destructiveChanges.xml` for deletions).
3. **Pre-deployment checks:** work through [Pre-Deployment-Checklist.md](Pre-Deployment-Checklist.md) and record each result.
4. **Backup:** retrieve the current version of every component from the target into `06-Deployment/Backups/DEP-NNN/` (source format)
   so it can be redeployed for rollback.
5. **Validate (check-only):**
   `python scripts/sf_safe.py project deploy validate --manifest manifest/releases/DEP-NNN-package.xml --test-level RunSpecifiedTests --tests <T1> --tests <T2>`.
   Record the validation ID, test results and coverage.
6. **Ask for approval.** State the exact operation, components and target. Record who approved it and when.
7. **Execute:** `python scripts/sf_safe.py --approved DEP-NNN project deploy start --manifest manifest/releases/DEP-NNN-package.xml --test-level RunSpecifiedTests --tests <T1>`
   (or quick-deploy the validated ID). Record the deploy ID and result.
8. **Manual configuration:** [Manual-Configuration-Checklist.md](Manual-Configuration-Checklist.md).
9. **Verify:** [Post-Deployment-Verification.md](Post-Deployment-Verification.md). Record evidence.
10. **If something is wrong:** create a CF record and follow [Rollback-Procedures.md](Rollback-Procedures.md) after approval.
11. **Close:** update the REQ records, `2026-10/07-Technical/` documents, `Change-History.md` and the Knowledge Base.

A Git push never deploys anything. Flow activation changes and destructive changes are listed explicitly and approved separately.

## History
| Date | Change |
|---|---|
| 2026-10-14 | Procedure created with the TVM setup. |
