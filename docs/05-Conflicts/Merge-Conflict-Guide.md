# Git and Metadata Merge Conflict Guide

## Avoiding conflicts
- Use one feature branch per requirement (`feature/REQ-xxxx-short-name`) and merge or rebase from `main` often.
- Retrieve only the components you are changing, not the whole wildcard manifest. A full retrieve reorders XML and creates noisy diffs.
- Run `npm run prettier` before committing so formatting doesn't cause conflicts.
- Tell the team before editing shared, high-traffic files: `LeadTriggerHandler`, `LeadTriggerHelper`, `OpportunityTriggerHandler`, `TaskHandler`, `TriggerHandler`, the profiles, and `Lead.workflow-meta.xml`.

## Resolving conflicts by file type
| File type | Approach |
|---|---|
| `.cls` / `.trigger` | Merge the logic by hand, then run the related test classes. |
| `*-meta.xml` (apiVersion) | Keep the higher API version (the project uses 64.0). |
| `.profile-meta.xml` / `.permissionset-meta.xml` | These are long sorted lists. Keep **both** sides' permission entries, remove duplicates, and keep the alphabetical order. Never just "take theirs" for a whole profile. |
| `.flow-meta.xml` | Don't hand-merge flow XML. Pick one version, then rebuild the other person's change in Flow Builder and retrieve it again. |
| `.workflow-meta.xml` | Merge rule by rule. Each `<rules>`, `<fieldUpdates>` and `<alerts>` block is independent. |
| `.queue-meta.xml` | Merge the member lists, and confirm the members still exist in the target org. |

## After resolving
1. `sf project deploy validate` against the sandbox.
2. Run the related tests.
3. Log the conflict in [Conflict-Log.md](Conflict-Log.md) if it took more than a trivial fix.
