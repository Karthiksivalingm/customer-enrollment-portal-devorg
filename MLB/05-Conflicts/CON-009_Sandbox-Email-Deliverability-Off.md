# CON-009 — No emails received from the sandbox

| | |
|---|---|
| **ID** | CON-009 |
| **Status** | ✅ Resolved 2026-10-07 |

## Findings (three causes)
1. **Deliverability off:** `Messaging.reserveSingleEmailCapacity` returned "The organization is not permitted to send email". → The user set **Deliverability = All email**.
2. **No trigger yet:** recent signed agreements were Contact (Vendor Activation) agreements, which the Ticket Office flow ignores by design. Opportunity agreements hadn't changed status since sync was fixed.
3. **`Opportunity_Owner_Manager__c` blank** on all test Opportunities, so the Sales Manager gets nothing. Still open: [CON-012](CON-012_Open-Data-And-Access-Items.md).
