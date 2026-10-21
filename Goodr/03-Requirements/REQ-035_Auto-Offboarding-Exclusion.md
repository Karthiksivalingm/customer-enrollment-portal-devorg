# REQ-035 — Exclude an Account from the Automated Offboarding

| | |
|---|---|
| **ID** | REQ-035 |
| **Status** | 🔧 Built and tested in the sandbox (21 Oct 2026, [ATR-002](../08-QA/01-Automated-Testing/ATR-002_Auto-Offboarding-Exclusion.md): 30 / 30 pass). Waiting on client testing and the open decisions in [CON-034](../05-Conflicts/CON-034_Auto-Offboarding-Exclusion-Open-Decisions.md) |
| **Requested** | 2026-10-21 (Slack, follow-up to the Friday call on the Offboarding launch) |
| **Requested by** | Kayla (client) |
| **Related** | [CR-026](../04-Change-Records/CR-026_Auto-Offboarding-Exclusion-Fields-Access-And-Pages.md) · [CR-027](../04-Change-Records/CR-027_Auto-Offboarding-Exclusion-Batch-And-Flow.md) · [CON-034](../05-Conflicts/CON-034_Auto-Offboarding-Exclusion-Open-Decisions.md) · [CON-035](../05-Conflicts/CON-035_Offboarding-Behaviour-Vs-Client-Answers.md) · [KB-002](../02-Knowledge-Base/Business-Process.md) |

## Business need
The account manager needs a by-pass / exception for the offboarding automation: a box they can tick on an account so the automation does not remove (deactivate) that account. If the box is ticked, the account must not go through the automated offboarding.

## What the automation does today (for every store)
1. **Order tracking:** the last Shopify order date is updated daily.
2. **Sales health check (weekly):** R12 / YTD sales are calculated and the store is flagged **At Risk** when YTD is below 50% of last year.
3. **At-risk task:** when a store becomes At Risk, the owner gets a task "Shopify sales at risk — contact this store".
4. **Warm-off emails (daily):** emails to the store's contacts at 12, 15, 17 and 17½ months without an order; a follow-up task for the owner at 17 months.
5. **Automatic deactivation:** at 18 months the store is deactivated (reason "Store At Risk"), a final email is sent, and the Company is deactivated if no active stores remain.
6. **Manual offboarding:** a user unticks Active, enters a reason and notes; the date, user, Company status and Shopify ordering are updated.

## Behaviour
New checkbox **Exclude from Auto-Offboarding** (with an optional **Auto-Offboarding Exclusion Reason**) in the Shopify Offboarding section of the Company and Store Location pages. Ticking it on a Company covers all of its stores.

| Automation | When the box is ticked |
|---|---|
| At-risk task (3) | **Stopped** |
| Warm-off emails and the 17-month task (4) | **Stopped** |
| Automatic 18-month deactivation and final email (5) | **Stopped** |
| Order tracking, sales health check, At Risk flag (1, 2) | Keeps running, so figures and reports stay correct |
| Manual offboarding (6) | Keeps working; the account manager can still offboard by hand |
| Stores without the box ticked | No change |

When the box is unticked, the store goes back into the normal process from where it left off, based on its last order date.

## Scope
- **In:** the two fields, field access for all users, the two record pages, the warm-off batch, the at-risk task flow, tests.
- **Out:** any change to manual offboarding, the Company/store rollup and cascade, the Shopify integration, R12 calculations, or existing notices.

## Acceptance criteria
1. A store with the box ticked gets no warm-off email, no 17-month task and no at-risk task, and is not deactivated at 18 months.
2. A store under a Company with the box ticked behaves the same.
3. A store without the box ticked behaves exactly as before.
4. Ticking or unticking the box never shows an error and triggers no other automation.
5. Manual offboarding still works on an excluded store.
6. All users can see and edit the fields.

## Assumptions
- The exclusion stops the emails as well as the deactivation (no "you will be deactivated" email to a store that will not be).
- Nothing changes on existing notices; the history is kept.

## Open questions
See [CON-034](../05-Conflicts/CON-034_Auto-Offboarding-Exclusion-Open-Decisions.md): unticking after 18 months, manual Company offboarding, at-risk task confirmation.

## Client clarifications on offboarding (received 21 Oct 2026)
These answers were received with this request. The behaviour they describe is not changed by REQ-035; the gaps found are parked in [CON-035](../05-Conflicts/CON-035_Offboarding-Behaviour-Vs-Client-Answers.md).

| Question | Client answer |
|---|---|
| Company offboarded manually: copy Reason, Notes, Date and User to all its stores? | Yes |
| Last active store offboarded, Company becomes inactive: use that store's Reason and Notes? | Yes, using the last store is fine; they can adjust manually |
| Company with one store: copy both ways? | Yes |
| Stores offboarded earlier for other reasons, Company offboarded later: keep their reasons? | They keep their original reasons |
| Reactivation: is it possible, and are offboarding details cleared? | Re-ticking the box re-enables the account; the field data is kept for record keeping |
| Who can offboard a Company? | All roles currently |
| Offboarding directly in Shopify? | Should not happen; offboarding is done through Salesforce |

## Output
CR-026, CR-027, [ATR-002](../08-QA/01-Automated-Testing/ATR-002_Auto-Offboarding-Exclusion.md) (sandbox test report). Manual test cases (MTC) to follow.
