# Retrieval report — Fullsandbox baseline

_Written by hand at the first push (2026-10-14, about 22:50 IST) because the batched retrieval was still running. Replace it by running
`python scripts/check_retrieval.py` after a complete `python scripts/retrieve.py` run._

## Status at the first push
| Batch | Types | Status | Components returned |
|---|---|---|---|
| code | Apex classes, triggers, pages, components, LWC, Aura, static resources, message channels, labels | **Succeeded** (196s) | 454 |
| automation | Flows, workflows, approval / assignment / auto-response / escalation rules, entitlement processes, milestones, notification types, duplicate / matching rules | **Succeeded** (291s) | 682 |
| datamodel | Custom objects (with fields, record types, validation rules, list views…), global value sets, sharing rules, custom metadata, custom permissions | **Succeeded** (201s) | 8,726 |
| ui | Lightning pages, layouts, tabs, apps, letterheads, report types, 131 automation-referenced email templates | **Running**: not included in its refreshed form | — |
| routing | Queues, routing configs, service channels, presence configs, call centers, groups, roles, named / external credentials, remote sites, external service, connected apps | **Pending** | — |
| access | Profiles, permission sets, permission set groups (with their companion components) | **Pending** | — |

Notes:
- **Earlier copies included.** Lightning pages, layouts, tabs, apps, queues, routing configs, permission sets, named/external credentials
  and remote sites were already present from the first single-request retrieval (2026-10-14, about 21:58). Those copies are pushed.
  They are not yet refreshed by the batched run.
- **Not yet in source:** profiles, permission set groups, roles, groups, call centers, connected apps, external service registration,
  letterheads, report types and the 131 email templates. They will arrive with the remaining batches.
- **Not retrievable:** `CustomObject ActionCadence` ("cannot be found").
- **Excluded on purpose:** package-owned components without a namespace, credential-bearing files ([CF-001](../../05-Conflicts/2026-10-14-CF-001-hardcoded-credentials-in-org-apex-and-external-credential-so.md)),
  `TouchPoint_Callout` records, reports, dashboards, other email templates, content assets ([Metadata-Scope.md](../Metadata-Scope.md)).
- **Result logs lost:** the per-component result logs of the first three batches were lost when `.tvm-state/` was deleted ([CF-002](../../05-Conflicts/2026-10-14-CF-002-batched-retrieval-interrupted-state-folder-deleted.md)).
  The counts above come from the run's console output.
