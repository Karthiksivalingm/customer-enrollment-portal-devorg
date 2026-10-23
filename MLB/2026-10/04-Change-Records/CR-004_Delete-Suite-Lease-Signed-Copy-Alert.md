# CR-004 — Delete the "Suite Lease Agreement Signed Copy" alert

| | |
|---|---|
| **Change ID** | CR-004 |
| **Date** | 2026-10-06 |
| **Requested by** | Client: the Ticket Office Agreement Details email already covers all agreements |
| **Org** | utdev sandbox |
| **Deploy ID** | 0AfiV0000007mcbSAA |

## Why
The alert used an unrelated Dispatcher template. Its only reference was an **inactive** approval process.

## What changed
| Component | Type | Action |
|---|---|---|
| `Opportunity.Suite_Lease_Agreement` | Approval process (inactive) | Modified: removed only the alert action from step "If Total>50k" |
| `Opportunity.Suite_Lease_Agreement_Signed_Copy` | Workflow alert | **Deleted** (post-destructive change) |
| `dispatcherapp__Dispatcher_Opportunity_owner_change` | Email template (managed package) | Not touched |

## Verification
No reference to the alert remains in the workflow or the approval process (retrieved and checked).

## Rollback
Recreate the alert (recipient billymarlin@marlins.com, Dispatcher template) and re-add the approval step action.
