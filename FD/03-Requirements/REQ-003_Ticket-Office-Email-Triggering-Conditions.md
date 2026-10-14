# REQ-003 — When the Ticket Office email is sent

| | |
|---|---|
| **ID** | REQ-003 |
| **Status** | ✅ Built and deployed to sandbox (utdev) |
| **Requested** | 2026-10-06; "first send" clarified 2026-10-07 |
| **Related** | REQ-002 · REQ-005 · CR-006 · CR-008 · CR-016 · TECH-002 |

## Business need (client's three rules, exactly)
1. If the Sales Manager **approves or denies** the agreement, the Ticket Office is notified.
2. If the agreement total is **$50k or greater**, the Ticket Office is notified **(on the first send)**.
3. Once the customer **signs or declines**, the Ticket Office is notified.

The client asked for **these three only, nothing added**.

## Functional behaviour (as built)
Trigger: an Adobe Sign agreement's status changes, the agreement is linked to an Opportunity, and that Opportunity has an Agreement Type.

| Rule | Status change that fires it |
|---|---|
| 1. Manager approves | Out for Approval / Waiting for Counter-Approval → Out for Signature or Approved |
| 1. Manager denies | Out for Approval / Waiting for Counter-Approval → Cancelled / Declined |
| 2. First send at $50k+ | Draft / Pre-Send / Send in Progress / Created / blank → Out for Approval or Out for Signature, **and** agreement value ≥ 50,000 |
| 3. Customer signs | → Signed (sent with the signed PDF; see REQ-005) |
| 3. Customer declines | Out for Signature / Waiting for Counter-Signature → Cancelled / Declined |

- One email at most per status change.
- **Status line in the email:** taken directly from the Adobe agreement. The client declined to add a new Opportunity field for it.

## Acceptance criteria (all passed in sandbox simulation)
| Scenario | Expected |
|---|---|
| First send ≥ $50k (from Draft, or from Created) | Email |
| First send ≥ $50k with no approver step | Email |
| Re-entering approval ≥ $50k | No email |
| First send < $50k | No email |
| Manager approved / declined | Email |
| Customer signed / declined | Email |
| Pre-Send → Out for Signature, < $50k | No email |

## Assumptions
- Approvers come before the signer in every Opportunity agreement template (confirmed from the Adobe recipient templates).
- A decline shows as "Declined" whether the manager or the customer declined, because Adobe uses one status for both.
