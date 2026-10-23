# KB-004 — Salesforce Environment and Tooling

| | |
|---|---|
| **Document ID** | KB-004 |
| **Last updated** | 2026-10-09 |

## 1. Org used for all work in this project

| Item | Value |
|---|---|
| CLI alias | `MLB Sandbox` |
| Sandbox name | `utdev` |
| Username | `billymarlin@marlins.com.utdev` (profile System Administrator) |
| Instance URL | https://miamimarlins--utdev.sandbox.my.salesforce.com |
| Lightning URL | https://miamimarlins--utdev.sandbox.lightning.force.com |
| Org ID | 00DiV00000040avUAA |
| Production | **Not connected and not touched** |


## 2. Sandbox configuration done by hand (not in metadata)

| Setting | State | Done by | Note |
|---|---|---|---|
| Email Deliverability | All email | User, 2026-10-07 | Required for any email to leave the sandbox |
| Adobe Sign: Enable Automatic Status Updates | Enabled | User | Required for agreement statuses to update ([CON-005](../2026-10/05-Conflicts/CON-005_Adobe-Sign-Status-Not-Syncing-In-Sandbox.md)) |
| Field-level security: COI / W-9 / Food Service Collected | Read-only for all profiles | Assistant, 2026-10-07 | Applied directly, not as deployable files ([CR-014](../2026-10/04-Change-Records/CR-014_Certificate-Fields-Locked-To-Flow-Only.md)) |
| FLS on new Ticketing Engagement / Opportunity fields | Removed with the fields | — | Reverted ([CR-022](../2026-10/04-Change-Records/CR-022_Revert-Ticketing-Engagement-Requirements.md)) |
| Adobe Sign Callback site | Exists, **inactive** | Assistant | Salesforce sites can't be deleted ([CR-005](../2026-10/04-Change-Records/CR-005_Adobe-Sign-Callback-Setup-And-Revert.md)) |

## 3. Local tooling

| Tool | State |
|---|---|
| Salesforce CLI | Updated 2.150.6 → **2.152.14** on 2026-10-05 (`sf update stable`; installed with the Windows installer, so use `sf update`, not npm) |
| Git | 2.56.0 installed. **The MLB folder is not a Git repository yet.** |
| GitHub CLI | 2.102.0 installed, **not logged in**. Login attempts timed out; on hold by user request. |
| Git global identity | `sfdc` / `sandipp@unitedtechno.com`, which doesn't match the current user; set a per-project identity before committing |

## 4. Handy local files

| File | Purpose |
|---|---|
| `email-preview/Ticket_Office_Email_Preview.html` | Ticket Office email rendered from the sandbox (desktop shortcut: *Ticket Office Email Preview*, opens in Chrome) |
| Desktop `Sandbox_User_Status.txt` | Shareable user-status message ([KB-005](KB-005_Sandbox-User-Status.md)) |
