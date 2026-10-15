# CON-008: Cleanup backlog and over-broad access

| Field | Value |
|---|---|
| Status | ⚠ Open |
| Severity | 🟡 Low (cleanup) / 🔴 High (access) |
| Found | 2026-10-13 |
| Related | [TECH-020](../07-Technical/TECH-020_Security-and-Access.md) |

## Access
- Seven permission sets grant **Modify All Data**, several under misleading names (Classic_Access, Lightning_and_Classic_View, Permission_for_merging_leads).
- The EQ Cross-Functional profile is effectively admin: ModifyMetadata, AuthorApex, ManageUsers, AssignPermissionSets.
- "Temp" permission sets remain, for example `Temp_Modify_all_to_download_Dataloader`.
- Debug statements write personal data (DOB, phone, health answers) to the logs in the ODA request builders.

## Cleanup
- 26 inactive triggers, 81 inactive workflow rules, and several active rules with no actions.
- `LeadTriggerHandler` is unused and untested. `Rider` has no logic. The cheat-sheet callout code is duplicated.
- There are four separate round-robin mechanisms. Consolidate them.
- Classes with no test: `CrossUpsellInfoController`, `LeadTriggerHandler`, `Rider`. Seven test classes have no asserts.
