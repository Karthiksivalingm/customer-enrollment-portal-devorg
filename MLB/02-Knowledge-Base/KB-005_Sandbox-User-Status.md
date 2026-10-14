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
All **18** users in role `Sales_Managers` (11 active, 7 inactive) hold the four required permission sets: MLB Sales Manager Access, Adobe Sign User, Adobe Access and Acrobat Sign Document Builder User. See [TECH-007](../07-Technical/TECH-007_Sales-Manager-Access-Model.md) and [REQ-012](../03-Requirements/REQ-012_Sales-Managers-Role-Access.md).

## Fixing the .invalid emails
**Not done yet.** It sends emails to real inboxes, so it needs approval.
1. Remove `.invalid` from the three emails.
2. Each user clicks the Salesforce verification email.
3. Send password resets so they can log in.
