# Salesforce Safety Rules

## 1. The only org

| Alias | Org name | Org ID | Username | Instance URL | Type |
|---|---|---|---|---|---|
| `Arizona` | Azlionhearts | `00DWH000005wW9V2AU` | `sandipp@unitedtechno.com.az.arizonalh` | `https://azlionhearts--arizonalh.sandbox.my.salesforce.com` | Sandbox (`IsSandbox = true`), Enterprise Edition, instance USA766S |

Verified on 2026-10-15 with `sf org display --target-org Arizona` and
`SELECT Id, Name, IsSandbox, OrganizationType, InstanceName FROM Organization`.
These values are stored in [`config/arizona-project.json`](../config/arizona-project.json). Tokens and session IDs are never recorded.

- **`PROD` is the Arizona Production alias. Never use it** for retrieval, configuration, data changes or deployments.
  (On 2026-10-15 no `PROD` alias was authenticated on the setup machine.)
- Never rely on the CLI default org. Every command names `--target-org Arizona`.
- Never use another project's org (TVM `Fullsandbox`, `Devorg`, etc.) for Arizona.

## 2. Verification before every org operation

Run `node scripts/verify-org.js` first. It checks that `Arizona` still resolves to Org ID `00DWH000005wW9V2AU` and the expected
username, and that `Organization.IsSandbox` is `true`. The listing script runs the same check automatically.

If verification fails, if the alias is missing, ambiguous or expired, or if the org is not a sandbox, stop and report. Never fall back.

## 3. Allowed without further approval

Read-only and non-persistent operations: metadata listing and retrieval, `project deploy validate` (check-only), `deploy preview`,
SOQL queries (`data query`), describes and limits. Apex test runs are read-only in effect but consume org resources; run them only for a task.

Retrieval must not overwrite local work that has not been committed. Check `git status -- Arizona/` first.

## 4. Needs explicit approval of the exact operation and target

| Operation | Approval record |
|---|---|
| Metadata deployment (any non-check-only deploy) | DEP record listing the components; the user's approval noted |
| Record create / update / delete / import | CR record with the scope; the user's approval noted |
| Anonymous Apex (`apex run`) | CR or DEP record |
| Destructive changes, Flow activation or deactivation | DEP record |

An approval covers only the operation and target it names. A plan or a DEP record by itself is not an approval.
Approval in one conversation does not carry over to the next. **Metadata retrieval never authorizes business-data changes.**

## 5. Never

- Use Production, or treat this repository as a release path to Production.
- Deploy as a side effect of a Git push.
- Change records, activate Flows or deploy during setup or retrieval.
- Store credentials, tokens, session IDs or auth URLs anywhere in the repository.

## History
| Date | Change |
|---|---|
| 2026-10-15 | Rules created with the Arizona setup; org identity verified. |
