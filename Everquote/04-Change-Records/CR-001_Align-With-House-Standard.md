# CR-001 — Align with the house folder standard (sandbox-only content)

| | |
|---|---|
| **Change ID** | CR-001 |
| **Date** | 2026-10-19 |
| **Requirement** | [REQ-001](../03-Requirements/REQ-001_Align-Everquote-With-MLB-Standard.md) |
| **Org** | Repository only (no org change) |
| **Deploy ID** | n/a |
| **By** | Assistant |
| **Status** | Done |

## What changed
**Folders now match MLB:**
- `01-Instructions` holds exactly `AI-Workflow.md`, `Coding-Standards.md` and `Project-Rules.md`, copied from MLB.
- `08-QA` has `01-Automated-Testing` and `02-Manual-Testing`.
- `06-Deployment` was removed; it is created only when something is actually deployed.

**Production details replaced with EverQuote Sandbox values (`force-app/`):**

| Production value | Replaced with | Where |
|---|---|---|
| `yoursage.my.salesforce.com`, `everquote.my.salesforce.com` | `yoursage--unitedtech.sandbox.my.salesforce.com` | 2 connected apps, 3 auth providers |
| `yoursage.lightning.force.com` | `yoursage--unitedtech.sandbox.lightning.force.com` | 31 email templates, 1 flow |
| `yoursage.file.force.com` | `yoursage--unitedtech.sandbox.file.force.com` | 5 flows (embedded images) |
| `c.na24.visual.force.com/apex/…` | `/apex/…` (relative, works in any org) | 5 custom buttons/links |
| `sma.na24`, `yoursage--dsfs.na90`, `yoursage--uniqueentry.na152`, `yoursage--lexmagicmover` Visualforce domains | `yoursage--unitedtech--<namespace>.sandbox.vf.force.com` | 4 remote site settings |
| `*.na152.visual.force.com` | `*.sandbox.vf.force.com` | 1 CSP trusted site (click to call) |

- Removed the marketing data source named after the production org ID (`mktDataSources/SFDC_00D…JmrP`).
- `sfdx-project.json` login URL changed from `login.salesforce.com` to `test.salesforce.com`.

**Kept on purpose:**
- Generic `login.salesforce.com` OAuth/login links inside connected apps and email templates (not specific to the EverQuote production org).
- Chili Piper booking links (`everquote.chilipiper.com`) in 8 email templates (third-party scheduling, not Salesforce).
- Employee email addresses in dashboards, queues and workflow alerts.

## Verification
- A search of `Everquote/` finds no production Salesforce domain, no `na24`/`na90`/`na152` instance URL and no production org ID.
- Line counts of every edited file are unchanged (lines replaced one for one).

## Notes
- Images in the 5 flows point to file IDs from production; they show in the sandbox only if those files exist there.
- A fresh retrieve from the sandbox can bring back production links stored in the sandbox; repeat this replacement before committing.

## Rollback
Revert this commit in `sfdcut/SFDC`. Everything changed is still in git history.
