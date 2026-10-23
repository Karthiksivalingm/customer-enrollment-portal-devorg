# KB-005 — Sandbox User Status (utdev)

| | |
|---|---|
| **Document ID** | KB-005 |
| **Checked on** | 2026-10-08 |
| **Org** | utdev sandbox |

All four requested users are **active**.

| User | Username | Email | Email status | Profile | Role | Last login |
|---|---|---|---|---|---|---|
| Jason Liss | jliss@marlins.com.utdev | jliss@marlins.com.invalid | ⚠ Needs fix and verification | Marlins Sales Leadership | Sales Managers | Never |
| Sonja Colon | scolon@marlins.com.utdev | scolon@marlins.com.invalid | ⚠ Needs fix and verification | Marlins Sales Leadership | Sales Managers | Never |
| Ruben Smith | rsmith@marlins.com.utdev | rsmith@marlins.com.invalid | ⚠ Needs fix and verification | System Administrator | — | Never |
| Miles Robson | mrobson@marlins.com.utdev | mrobson@marlins.com | ✅ Valid | System Administrator | — | 2026-10-07 |

**Why it matters:** a sandbox refresh appends `.invalid` to user emails. Those users get no email from the sandbox: password resets, Adobe notices and Ticket Office copies are all blocked.

## Managers on user records (checked 2026-10-09)
| User | Manager |
|---|---|
| Billy Marlin (`billymarlin@marlins.com.utdev`, System Administrator) | Ruben Smith (`rsmith@marlins.com.utdev`; email still `.invalid`) |
| Sonja Colon | **None set**; to be confirmed |

## Sales Managers role access (2026-10-09)
All **18** users in role `Sales_Managers` (11 active, 7 inactive) hold the four required permission sets: MLB Sales Manager Access, Adobe Sign User, Adobe Access and Acrobat Sign Document Builder User. See [TECH-007](../2026-10/07-Technical/TECH-007_Sales-Manager-Access-Model.md) and [REQ-012](../2026-10/03-Requirements/REQ-012_Sales-Managers-Role-Access.md).

## Sales Manager checkbox (2026-10-21)
The User field **Sales Manager** decides who appears in the Sales Manager list of the Contact Create Agreement flow ([REQ-017](../2026-10/03-Requirements/REQ-017_User-Sales-Manager-Checkbox.md)). Ticked in the sandbox (2026-10-23): **Samantha MacIntosh, Jason Liss, Pierce Jefferson, Brandon Federico, Nathan Medrano**, plus **Billy Marlin** and **Ruben Smith** from the first setup. Roles are no longer used for this list.

## Sales users with full agreement access (2026-10-23)
| User | Profile / role | Access |
|---|---|---|
| Sonja Colon, Samantha MacIntosh, Jason Liss, Pierce Jefferson, Brandon Federico, Nathan Medrano | Marlins Sales Leadership / Sales Managers | Marlins Sales app, MLB Sales Manager Access, the three Adobe Sign sets |
| Antonio Diz, Chema Sanchez, Isaac Paladino, Keeley Himmelreich | Ticket Sales / Sales Reps | Same: MLB Sales Manager Access assigned on 2026-10-23 ([CR-037](../2026-10/04-Change-Records/CR-037_Sales-Manager-Ticks-And-Sales-User-Access.md)) |

## Fixing the .invalid emails
**Not done yet.** It sends emails to real inboxes, so it needs approval.
1. Remove `.invalid` from the three emails.
2. Each user clicks the Salesforce verification email.
3. Send password resets so they can log in.
