# CON-005 — Adobe Sign agreement status not syncing in the sandbox

| | |
|---|---|
| **ID** | CON-005 |
| **Status** | ✅ Resolved 2026-10-06 by the user (manual) |

## Conflict
In the sandbox, agreements were sent but their status stayed Draft, Pre-Send or Created. Production worked.

## Findings
- No "Adobe Acrobat Sign" OAuth connection existed in the sandbox, so Adobe couldn't push status changes.
- The `echosign_dev1__SIGN_Settings__c` org default was empty and no Site existed (both checked).
- Production has no Sites and no Adobe scheduled jobs. So the callback-site approach that was tried ([CR-005](../04-Change-Records/CR-005_Adobe-Sign-Callback-Setup-And-Revert.md)) wasn't how production works, and it was reverted.

## Resolution
In the sandbox's **Adobe Acrobat Sign Admin** tab, the user ran **Enable Automatic Status Updates** and authorised it, matching production.

## Lesson / runbook
After **every sandbox refresh**: re-enable Automatic Status Updates. Check **Setup → Connected Apps OAuth Usage** for "Adobe Acrobat Sign".
