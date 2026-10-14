# CON-003 — System Administrators bypass read-only field-level security

| | |
|---|---|
| **ID** | CON-003 |
| **Status** | ✅ Resolved 2026-10-07 ([CR-014](../04-Change-Records/CR-014_Certificate-Fields-Locked-To-Flow-Only.md)) |

## Conflict
- After the certificate checkboxes were made read-only for all profiles, the user (System Administrator) could still edit them.
- Investigation: Standard User and Ticket Sales became read-only as expected. **System Administrator stayed editable** even with profile FLS `editable=false` (confirmed by profile metadata, Apex describe and the UI API). The profile has *Modify All Data*.
- Separate finding: setting FieldPermissions through DML didn't refresh access for the admin profile; a metadata deploy didn't change it either.

## Resolution
A validation rule (`Certificate_Fields_Flow_Only`) blocks manual changes for **everyone**. The upload flow passes by flipping the hidden `Certificate_Flow_Update__c`.

## Lesson
For "nobody may edit" requirements, FLS alone isn't enough for admins in this org. Use a validation rule.
