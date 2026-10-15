# 05 · Known Issues and Risks

Found during code and sandbox review (2026-10-13 to 2026-10-15). None of these are fixed yet.

## Go-live risks

| # | Item | Impact | Suggested action |
| --- | --- | --- | --- |
| R1 | Email link in flow `Send_email_for_guest_creation_in_swoogo` (`fx_RecordLink`) is hard-coded to `https://qatarmuseums2--qatarsand.sandbox.lightning.force.com` | "Click Here to View Record" opens the sandbox from production | Build the link from `$Api.Partner_Server_URL` / a custom label, or use a relative record URL |
| R2 | No Swoogo sync jobs scheduled in the sandbox; last sync 2026-08-25 19:15 UTC | Inbound data in sandbox is stale; production needs scheduling after deploy | Run `SwoogoSyncScheduler.scheduleAll();` in each org |
| R3 | **Mark as Approved** quick action (flow `Guest_list_Approval`) sets Approval Status = Approved with no checks | Bypasses both approval levels and pushes the guest to Swoogo | Restrict by profile/permission or add a guard (e.g. only accompanying guests) |
| R4 | Approval via the standard Salesforce approval screen does not set `Guest_Tiers__c` | Guest fails with *Failed - No Guest Tier set* | Approve only through Pending Approvals, or populate Guest Tiers in the approval's final action |
| R5 | `SwoogoConfig__mdt` holds consumer key/secret in custom metadata | Secret visible to admins and in metadata deployments | Consider a Named Credential / External Credential |
| R6 | Swoogo `c_8598114` is only sent when a contact is created or first found by email | Contacts already linked before this logic have no Salesforce id in Swoogo | One-off backfill if Swoogo-side reporting needs it |

## Functional gaps and inconsistencies

| # | Item |
| --- | --- |
| F1 | Pending Approvals: Stage 1 has no Reject action; reject message says "Submitters will be notified" but no notification is configured. |
| F2 | Approval process has no email alerts on submit, approve or reject. |
| F3 | Pending Approvals adds a hard-coded +2 hours to Inbound/Outbound Date & Time display. |
| F4 | Guest Invitation / Registration reports exclude guests with blank Guest Tiers or status, even with **Generate All**. |
| F5 | Guest Invitation Report "Tier" column shows Guest Tiers, not Invitation Tier. |
| F6 | `guestApproval` stores HE notes in HE Request **Name**; `approvedguestlist` stores them in `Feedback__c`. |
| F7 | `approvedguestlist` Job Title column is always blank (controller never fills it). |
| F8 | `upcomingEvents`: "This Month" = next 30 days; empty-state message never shows (`isNoEvents` getter missing). Not Swoogo-related. |
| F9 | Webhooks are logged but do not trigger a sync; everything waits for the 15-minute run. |
| F10 | Inbound sync never creates Contacts or Guest Lists; registrants without a matching Contact + Guest List are skipped silently (debug log only). |
| F11 | Flow `Update_Event_in_guest_list` compares a lookup to "true" in its entry condition; unclear whether it ever fires. |
| F12 | `eventreportbuttons` **Generate All** filters by event name though a comment says record id; report id `00OAe000007PbLJMA0` is hard-coded. |

## Broken or unused components

| Component | State |
| --- | --- |
| LWC `guestListApproval` (Sub Event page, quick action *Submit For Approval* on Guest List) | Controller `GuestListApprovalController` fully commented out |
| LWC `guestApprovalPage` | Controller `GuestApprovalController` commented out |
| LWC `guestlistrelatedlist` | Wires a non-cacheable method and expects a list but gets a map → "Failed to load guest list." |
| LWC `guestcategoryreportcontroller` | Calls `GuestCategoryReportController.getGuestCategoryValues`, which does not exist |
| `SwoogoSessionSyncContinuation` | Unused (replaced by `SwoogoSessionSyncChunkScheduler`) |
| `SwoogoContactFieldMapService` | Unused |
| `SwoogoEventProcessorQueueable`, `Swoogoeventsyncqueueable`, `GuestListSwoogoPushEmailHandler` | Empty stubs |
| `SwoogoEventService` (`/swoogo/events`), `SwoogoRegistrationService` (`/swoogo/registrations`) | Only referenced by tests; live use depends on Swoogo webhook config |
| `AbortSwoogoJobsBatch` | Manual admin tool (aborts `Swoogo%` scheduled jobs) |
| Flow `Send_email_for_guest_creation_in_swoogo` | Five keyword formulas (Design Doha, fta, october, Rubaiya, September) defined but unused |
| Flows Attendee, Event_Notification, Delete_Guest_List_*, Main_Contact_Update, Update_Session_Attendance_with_Contact_look_up | Obsolete; `Rsvp_Updated_Invitatin` invalid draft |

## Comments out of date in code

- `SwoogoApiClient.createContact()` comment says an existing contact's `c_8598114` is not backfilled; `updateContactExternalId()` now does this.
- `SwoogoSyncBatch` header still describes "dirty event" detection that was removed; every event is now synced in Pass 2 on DELTA runs.
