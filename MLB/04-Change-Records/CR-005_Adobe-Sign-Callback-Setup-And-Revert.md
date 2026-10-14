# CR-005 — Adobe Sign callback site, settings and scheduled jobs (set up, then reverted)

| | |
|---|---|
| **Change ID** | CR-005 |
| **Date** | 2026-10-06 |
| **Related** | [CON-005](../05-Conflicts/CON-005_Adobe-Sign-Status-Not-Syncing-In-Sandbox.md) |
| **Org** | utdev sandbox |
| **Status** | **Reverted**, except the site, which Salesforce can't delete (left inactive) |

## Context
Agreement statuses weren't updating in the sandbox. A callback-site approach was tried first. It was reverted once the user confirmed production has no Sites and no Adobe scheduled jobs.

## Changes and final state
| Change | Deploy / method | Final state |
|---|---|---|
| Site `Adobe_Sign_Callback` (prefix `adobesign`, home page `echosign_dev1__EchoSignCallback`) | 0AfiV0000007n2PSAQ | **Inactive** (0AfiV0000007nFJSAY). Sites can't be deleted. |
| Guest profile access to Adobe callback classes and pages | Prepared, **blocked by a permission check, never deployed**; local file deleted | Not applied |
| `echosign_dev1__SIGN_Settings__c` org default: callback URL | Anonymous Apex | **Cleared**: record deleted, as it was empty originally |
| 4 scheduled jobs `Adobe Sign Callback Processor :00/:15/:30/:45` (`EchoSignScheduleCallback`) | `System.schedule` | **Aborted**; none left |

## Actual fix
The user enabled **Enable Automatic Status Updates** in the *Adobe Acrobat Sign Admin* tab ([CR-011](CR-011_Sandbox-Manual-Configuration.md)).
