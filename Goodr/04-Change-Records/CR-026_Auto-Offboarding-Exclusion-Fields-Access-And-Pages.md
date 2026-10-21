# CR-026 — Auto-Offboarding Exclusion: fields, field access and pages

| | |
|---|---|
| **Change ID** | CR-026 |
| **Date** | 2026-10-21 (21 Oct 11:23 and 11:35 IST) |
| **Requirement** | [REQ-035](../03-Requirements/REQ-035_Auto-Offboarding-Exclusion.md) |
| **Org** | GDRSAND |
| **Deploy ID** | `0Afdx00000GQ6wcCAD` (fields, pages, first 3 profiles; validated by `0Afdx00000GQ82LCAT`) · `0Afdx00000GQ8WzCAL` (field access for all profiles, with CR-027) |
| **By** | Assistant (VS Code deploy) |
| **Status** | Done in sandbox |

## What changed
| Component | Type | Change |
|---|---|---|
| `Account.Exclude_From_Auto_Offboarding__c` | Custom field | **New.** Checkbox "Exclude from Auto-Offboarding", default unticked, help text, field history tracking on |
| `Account.Auto_Offboarding_Exclusion_Reason__c` | Custom field | **New.** Text (255) "Auto-Offboarding Exclusion Reason", optional, no history tracking |
| `Account_Company_Record_Page` | Lightning page | Both fields added to the Shopify Offboarding section under Active. The reason shows only when the box is ticked |
| `Account_Store_Location_Record_Page1` | Lightning page | Same as above |
| Field access | Profiles | Read and edit on both fields for the 21 profiles that can edit `Active__c`: Account Management, System Administrator, Standard User, Contract Manager, End User, Executive Sponsor, Marketing User, Read Only, Service Agent, Service Supervisor, Solution Manager, Minimum Access - Salesforce, Analytics Cloud Integration User, Analytics Cloud Security User, Anypoint Integration, CPQ Integration User, Identity User, Minimum Access - API Only Integrations, Salesforce API Only System Integrations, Sales Insights Integration User, SalesforceIQ Integration User. Guest-site profiles (GoodR, Zendesk, Guest License) are not included |

**Not changed:** no validation rule, trigger or flow reacts to the new fields themselves, so ticking or unticking the box is a plain save.

**Notes**
- Account field history tracking is now at 19 of the 20 allowed fields. That is why the reason field is not tracked.
- The pages were built from the live sandbox copies. The repository working copy also has an unrelated, uncommitted visibility rule on `Is_Saved_Record__c` (already in the sandbox); it is not part of this change and was not committed here.
- Field access is set in the org only. Profiles are not kept in the repository.

## Verification
- `FieldPermissions`: 21 profiles with read and edit on each field.
- `FieldDefinition`: checkbox tracked, reason not tracked.
- 0 accounts with the box ticked after the deploy.

## Rollback
Redeploy both pages from the previous commit, then delete the two fields (deleted fields stay recoverable for 15 days). Remove CR-027 first, because the batch and the flow reference the checkbox.
