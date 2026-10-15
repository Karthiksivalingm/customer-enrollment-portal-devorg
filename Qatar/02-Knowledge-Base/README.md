# Knowledge Base: Salesforce ↔ Swoogo Guest Management

Knowledge base for the Qatar Museums (Chairperson's Office) Salesforce org and its integration with the Swoogo event platform. Written for the delivery team: developers, admins and consultants who build, support or hand over this solution.

**As of:** 2026-10-15. Built from the metadata and data in the `QM sandbox` org (`qatarmuseums2--qatarsand`), retrieved into this project.

## Files

| File | What it covers |
| --- | --- |
| [01-Project-Overview.md](01-Project-Overview.md) | Purpose, scope, users, systems, current state |
| [02-Technical-Architecture.md](02-Technical-Architecture.md) | Data model, components (Apex, LWC, flows, approval process, VF), configuration, scheduling, limits |
| [03-Business-Process.md](03-Business-Process.md) | End-to-end processes: event setup, adding guests, approval, accompanying guests, responses, attendance, reports |
| [04-Integration.md](04-Integration.md) | Swoogo API usage, outbound push, inbound sync, field mappings, ID linking, errors, operations runbook |
| [05-Known-Issues-and-Risks.md](05-Known-Issues-and-Risks.md) | Defects, gaps, unused code and go-live risks found during review |

## The solution in one paragraph

Events are created in Swoogo and synced into Salesforce every 15 minutes (`Invitation__c`, labelled **Events List**, with sessions as `Sub_Event__c`). The team adds guests to an event in Salesforce (`Guest_List__c`), sends them through a two-level approval, and on final approval Salesforce pushes the guest to Swoogo: main guests go onto the invitation list that matches their **Guest Tiers**; accompanying (+1) guests are registered directly and placed in the main guest's group once the main guest has accepted. Guest responses, registration details, travel and hotel answers, and session check-ins flow back from Swoogo on the same 15-minute sync.

## Quick facts

| Item | Value |
| --- | --- |
| Swoogo API | `https://api.swoogo.com/api/v1`, OAuth2 client credentials |
| Credentials | Custom metadata `SwoogoConfig__mdt` (record `Key_Secret`) |
| Outbound trigger | `GuestListTrigger` on `Guest_List__c` (after update), enabled by `Swoogo_Settings__c.Enable_Guest_List_Trigger__c` |
| Inbound sync | `SwoogoSyncScheduler` → `SwoogoSyncBatch` (Pass 1) → `SwoogoSessionSyncBatch` (Pass 2), every 15 minutes |
| Sync state | `Swoogo_Sync_State__c.Last_Sync_Time__c` (org default) |
| Logs | `Webhook_Log_c__c` (one row per sync pass and per webhook) |
| Link fields | Contact `contact_external_id__c` ↔ Swoogo contact id; Swoogo custom field `c_8598114` ↔ Salesforce Contact Id |
| Approval process | `Guest_List__c.Guest_List_Approval` (2 levels) |
