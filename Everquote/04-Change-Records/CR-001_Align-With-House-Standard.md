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
| Production My Domain URL | `yoursage--unitedtech.sandbox.my.salesforce.com` | 2 connected apps, 3 auth providers |
| Production Lightning URL | `yoursage--unitedtech.sandbox.lightning.force.com` | 31 email templates, 1 flow |
| Production file URL | `yoursage--unitedtech.sandbox.file.force.com` | 5 flows (embedded images) |
| Production Salesforce Sites URL | `yoursage--unitedtech.sandbox.my.salesforce-sites.com` | 1 custom metadata record (unsubscribe link) |
| Production instance Visualforce URL | `/apex/…` (relative, works in any org) | 5 custom buttons/links |
| Production managed-package Visualforce URLs | `yoursage--unitedtech--<namespace>.sandbox.vf.force.com` | 4 remote site settings |
| Production instance Visualforce wildcard | `*.sandbox.vf.force.com` | 1 CSP trusted site (click to call) |

- Removed the marketing data source named after the production org ID.
- `sfdx-project.json` login URL changed from `login.salesforce.com` to `test.salesforce.com`.

**Kept on purpose:**
- Generic `login.salesforce.com` OAuth/login links inside connected apps and email templates (not specific to the EverQuote production org).
- Chili Piper booking links in 8 email templates and Slack workspace links (third-party services, not Salesforce).
- Employee email addresses in dashboards, queues and workflow alerts.

## Verification
- A search of `Everquote/` finds no production Salesforce domain, no production instance URL and no production org ID.
- Line counts of every edited file are unchanged (lines replaced one for one).

## Notes
- Images in the 5 flows point to file IDs from production; they show in the sandbox only if those files exist there.
- A fresh retrieve from the sandbox can bring back production links stored in the sandbox; repeat this replacement before committing.

## Rollback
Revert this commit in `sfdcut/SFDC`. Everything changed is still in git history.
