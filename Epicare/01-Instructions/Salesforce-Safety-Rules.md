# Salesforce Safety Rules

## 1. The only org

| Alias | Org | Org ID | Username | Type |
|---|---|---|---|---|
| `UTDEV` | Epicare Insurance (`https://epicareinsurance--utdev.sandbox.my.salesforce.com`) | `00DWB000008ALkv2AG` | `sandipp@epicareinsurance.com.utdev` | Sandbox, Enterprise Edition (`IsSandbox = true`) |

Verified 2026-10-15 with `sf org display --target-org UTDEV` and `SELECT Id, Name, IsSandbox FROM Organization`.
These values are stored in [`config/project.json`](../config/project.json). Tokens and session IDs are never recorded.

- Never use any other org for Epicare: not production, not another sandbox, not the CLI default org.
- **`PROD` (`sandipp@epicareinsurance.com`, Org ID `00DKc00000BEveDMAT`) is the Epicare production org. It is never used by this
  project: no retrieval, no queries, no data operations and no deployment.
- Never rely on the CLI default org. Every command names `--target-org UTDEV`.

## 2. Verification before every org operation

`python scripts/sf_safe.py <sf arguments>` is the only supported way to run Salesforce CLI commands. It:
1. Checks that `UTDEV` still resolves to Org ID `00DWB000008ALkv2AG` and the expected username.
2. Queries `Organization.IsSandbox` and stops unless it is `true`.
3. Rejects any `--target-org` other than `UTDEV` and adds `--target-org UTDEV` when missing.
4. Refuses commands that change the org unless `--approved <ID>` names the approval record.
5. Refuses commands that are not on its allow-list.

The Claude Code `PreToolUse` hook (`scripts/hooks/guard.py`) blocks direct `sf`/`sfdx` commands, except a few harmless ones such as
`sf org list`, so Claude always goes through `sf_safe.py`.

If verification fails, if the alias is missing, ambiguous or expired, or if the org is not a sandbox, stop and report. Never fall back.

## 3. What is allowed without further approval

Read-only and non-persistent operations: metadata listing and retrieval, `project deploy validate` (check-only), `deploy preview`,
SOQL queries (`data query`), `apex run test` (tests roll back their own data), describes and limits.

Retrieval must not overwrite local work that has not been committed. Check `git status` first.

## 4. What needs explicit approval of the exact operation and target

| Operation | Approval record | Command form |
|---|---|---|
| Metadata deployment (any non-check-only deploy) | DEP record listing the components; user's approval noted | `sf_safe.py --approved DEP-NNN project deploy start ...` |
| Record create / update / delete / import | CR record with the scope; user's approval noted | `sf_safe.py --approved CR-NNN data update record ...` |
| Anonymous Apex (`apex run`) | CR or DEP record | `sf_safe.py --approved <ID> apex run --file ...` |
| Destructive changes, Flow activation or deactivation | DEP record | as above |

An approval covers only the operation and target it names. A deployment plan or a DEP record by itself is not an approval.
Approval in one conversation does not carry over to the next.

## 5. Never

- Deploy to production, or treat this repository as a release path to production. Production follows a separate, human-controlled
  release process.
- Deploy as a side effect of a Git push. `scripts/autocommit.py` never runs Salesforce commands.
- Change records, activate Flows or deploy during initial setup or retrieval.
- Store credentials, tokens, session IDs or auth URLs anywhere in the repository.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Rules created with the Epicare setup. |
