# 04 · Integration (Salesforce ↔ Swoogo)

## Connection

| Item | Value |
| --- | --- |
| Base URL | `https://api.swoogo.com/api/v1` (`SwoogoApiClient.BASE_URL`) |
| Auth | `POST /oauth2/token`, `grant_type=client_credentials`, header `Basic base64(urlencode(key):urlencode(secret))` |
| Credentials | `SwoogoConfig__mdt` (`ConsumerKey__c`, `ConsumerSecret__c`), first record |
| Token | Cached in a static for the transaction; on HTTP 401 the token is cleared and the call retried once |
| Timeouts | Token 10 s, API calls 30 s |
| Remote site | `Swoogi` |
| Salesforce id field in Swoogo | `c_8598114` (`SwoogoApiClient.SF_EXTERNAL_ID_FIELD`) |

## Swoogo endpoints used

| Method | Endpoint | Used by | Purpose |
| --- | --- | --- | --- |
| GET | `/events.json?fields=…` (+ `&search=status%3Ddraft`, `&updated_after=`) | Pass 1 | All events (first run, incl. drafts) or changed events |
| GET | `/events/{id}.json` | Pass 1 | Single event when not cached |
| GET | `/sessions.json?event_id=&fields=…&status=any` (+ `updated_after`) | Pass 2 | Sessions (`date` renamed to `session_date`; `body` used if no `description`) |
| GET | `/registrants.json?event_id=&fields=id,first_name,last_name,email,job_title,mobile_phone,work_phone,registration_status,contact_id,deleted,event_id,session_ids,c_8598114[,c_…]` | Pass 2 | Registrants (always full fetch) |
| GET | `/session-attendances.json?event_id=` | Pass 2 | Attendance / check-ins (full fetch) |
| GET | `/event-questions.json?event_id=&per_page=100&fields=id,name,attribute` | Pass 2 | Custom question map |
| GET | `/invitation-lists.json?event_id=&fields=id,name,event_id` | Pass 2, outbound | Lists per event |
| GET | `/invitation-lists/{listId}/contacts.json?fields=contact_id,status,created_at,updated_at` | Pass 2 | List membership + status |
| GET | `/contacts.json?fields=id,email&search=email%3D{email}` | Outbound | Find contact by email |
| POST | `/contacts/create` (form: email, first_name, last_name, c_8598114) | Outbound | Create contact |
| PUT | `/cfs-contacts/update/{contactId}` (form: c_8598114) | Outbound | Stamp Salesforce id on an existing contact |
| POST | `/invitation-lists/{listId}/contact/{contactId}` | Outbound | Add main guest to list |
| GET | `/registrants.json?event_id=&fields=id,email&search=email%3D{email}` | Outbound | Reuse existing registrant |
| GET | `/reg-types.json?event_id=&fields=id,name&per_page=50` | Outbound | Find registration type by Guest Tiers |
| POST | `/reg-types/create` (form: event_id, name, capacity=9999) | Outbound | Create missing registration type |
| POST | `/registrants/create.json` (JSON) | Outbound | Register accompanying guest |
| POST | `/registrants/{registrantId}/groups/{groupId}` | Outbound | Add to main guest's group |

Pagination: `page` + `per_page=50`; loop ends when `page >= _meta.pageCount`, `totalCount = 0`, empty `items`, or 93 callouts used.

## Outbound: Salesforce → Swoogo

### Trigger: `GuestListTrigger` (after update on `Guest_List__c`)

1. Exit unless `Swoogo_Settings__c.getInstance().Enable_Guest_List_Trigger__c = true`.
2. For each record whose `Approval__c` changed to `Approved`:
   - Main guest (`Main_Guest__c` null): queue if `Import_from_Swoogo__c = false`.
   - Accompanying guest: queue if the main guest's `Invitation_Status__c = 'Accepted'`; otherwise set `Swoogo_Push_Status__c = 'Pending - waiting for main guest invitation acceptance'`.
3. For each record whose `Invitation_Status__c` changed to `Accepted`: queue every accompanying guest with `Approval__c = 'Approved'` whose push status does not start with `Success`.
4. `System.enqueueJob(new GuestListRegistrantQueueable(ids))`.

### Queueable: `GuestListRegistrantQueueable`

Per guest (skips non-Approved and already-successful guests):

1. Validate: event id (`Invitation__r.External_Event_Id__c`), Contact with Email, `Guest_Tiers__c`.
2. Resolve Swoogo contact id: Contact `contact_external_id__c` → else `findContactIdByEmail` (and `updateContactExternalId` to stamp `c_8598114`) → else `createContact` (with `c_8598114`). Back-fill `contact_external_id__c` when it was blank.
3. **Accompanying guest**: requires the main guest's `Swoogo_Registrant_Id__c`; `createRegistrant` (reuses an existing registrant with the same email; `reg_type_id` from `getOrCreateRegTypeId(Guest_Tiers__c)`; sends company, job title, mobile, `c_8598114`), then `addRegistrantToGroup(registrantId, mainRegistrantId)`; saves `Swoogo_Registrant_Id__c`.
4. **Main guest**: get invitation lists for the event (cached per event per run), match name to `Guest_Tiers__c` (trim, case-insensitive), `addContactToInvitationList`.
5. Write `Swoogo_Push_Status__c`; update Contacts with `Database.update(…, false)`.
6. HTTP 429 → status `Retry Pending …`, then schedule `GuestListRegistrantRetryScheduler` after `ceil((X-Rate-Limit-Reset or 120) + 15 s)` minutes (not from batch or future context).

## Inbound: Swoogo → Salesforce

### Schedule

`SwoogoSyncScheduler.execute` → `SwoogoSyncBatch.run()` (batch size 1) unless a sync is already running or a `SwoogoP2Chunk%` job is pending.

### Pass 1 – `SwoogoSyncBatch` (events)

| Mode | Condition | Scope |
| --- | --- | --- |
| FULL | `Swoogo_Sync_State__c.Last_Sync_Time__c` is null | All Swoogo events (+ drafts) |
| DELTA | Otherwise | Events updated after last sync + every `Invitation__c` with an External Event Id |
| SPECIFIC | `SwoogoSyncBatch.run('id1,id2')` | Listed events |
| Always | `SwoogoConfig__mdt.EventIds__c` | Pinned events |

Per event: upsert `Invitation__c` by `External_Event_Id__c`; mark dirty (every event on DELTA). `finish()` logs to `Webhook_Log_c__c` (`SwoogoSync-P1-<mode>-<timestamp>`), builds the Pass 2 scope from dirty events whose Invitation was resolved, sorts newest first (Swoogo `created_at`), and starts Pass 2. Events sorted to the end when `created_at` is unknown.

### Pass 2 – `SwoogoSessionSyncBatch` (per event, 6 events per chunk)

| Phase | Step | FULL run | DELTA run |
| --- | --- | --- | --- |
| Callouts | Sessions | Full fetch | Full for new events, otherwise `updated_after` |
| | Registrants | — | Full fetch; re-fetched with custom question fields when the question map has any |
| | Question map | — | `/event-questions.json` (cached per event) |
| | Attendance | — | Full fetch when the event has sessions |
| | Invitation tiers | — | Lists + members |
| DML | `SwoogoSubEventSyncService.upsertSubEvents` | Yes | Yes |
| | `SwoogoRegistrantSyncService.syncRegistrants` | — | Yes |
| | `SwoogoAttendanceSyncService.syncAttendances` | — | Yes |
| | `SwoogoInvitationTierSyncService.applyInvitationTiers` | — | Yes |

`finish()`: logs `SwoogoSync-P2-<mode>-<timestamp>`; emails the running user if any non-429 error; schedules the next chunk 1 minute later; after the last chunk sets `Last_Sync_Time__c = batchStartTime`. HTTP 429 on an event is logged and skipped (no retry); the event is picked up on the next 15-minute run.

### Webhooks

`POST /services/apexrest/swoogo/webhook` (`SwoogoWebhookHandler`) always returns 200, logs the raw body to `Webhook_Log_c__c` (Status *Received*) and extracts `event_id`, but triggers no sync. Legacy endpoints `/swoogo/events` and `/swoogo/registrations` exist but have no confirmed live use.

## Field mappings

### Events (Swoogo → `Invitation__c`)

| Swoogo | Salesforce | Rule |
| --- | --- | --- |
| `id` | `External_Event_Id__c` | Key |
| `name` | `Name` | Blank → "Swoogo Event <id>" |
| `start_date`, `end_date` | `Event_Start_Date__c`, `Event_End_Date__c` | |
| `location` / `event_venue_type` | `Location__c` | Location, else venue type |
| `status` | `Status__c` | draft→Draft; active/published/live→Active; deleted/archived/closed→Cancelled; other values copied |
| `updated_at` | `Swoogo_Updated_At__c` | |

### Sessions (Swoogo → `Sub_Event__c`)

| Swoogo | Salesforce | Rule |
| --- | --- | --- |
| `id` | `Sub_Event_ID__c` | Key (within the event) |
| `name` | `Sub_Event_Name__c` | Blank → "Session <id>" |
| `date` | `Date__c` | |
| `date` + `start_time` / `end_time` | `Start_DateTime__c` / `End_DateTime__c` | `Datetime.valueOf(date + ' ' + time)` |
| `description` (or `body`) | `Description__c` | HTML tags and common entities removed |
| `updated_at` | `Swoogo_Updated_At__c` | |

### Registrants (Swoogo → Contact / `Guest_List__c`)

Contact match order: `contact_external_id__c = contact_id`, then email against `Email`, `Email_Office__c`, `Admin_Email__c`, `Email_2__c`, `Private_Email__c`. Deleted registrants ignored. Contacts are never created.

| Swoogo | Salesforce | Rule |
| --- | --- | --- |
| `contact_id` | Contact `contact_external_id__c` | Only when blank |
| `first_name` | `FirstName` | Truncated to 40 |
| `last_name`, `job_title`, `mobile_phone`, `work_phone` | `LastName`, `Title`, `MobilePhone`, `Phone` | When different |
| `email` | `Email_Office__c` (Email - 4) | When different |
| `id` | `Guest_List__c.Swoogo_Registrant_Id__c` | Guest List matched by Contact + event |
| `registration_status` | `RSVP__c` | First letter upper, rest lower |
| `session_ids` | `Session_Attendance__c.Registered__c` | |

### Custom questions (question map)

`SwoogoQuestionMapService` matches question **names** (lower-case, contains):

| Salesforce field | Keywords |
| --- | --- |
| `Hotel_Name__c` | hotel, accommodation, room |
| `Relationship_to__c` | relationship, relation to |
| `Inbound_Date_Time__c` (date) | i/b dep, i/b date, inbound dep, inbound date, i/b departure, ib dep, ib date |
| `Inbound_Date_Time__c` (time) | i/b t/o, i/b time, inbound t/o, inbound time, i/b to time, ib t/o, ib time, i/b to |
| `Outbound_Date_Time__c` (date) | o/b date, outbound date, o/b dep, outbound dep, o/b departure, ob date, ob dep |
| `Outbound_Date_Time__c` (time) | o/b to time, o/b time, outbound t/o, outbound time, o/b t/o, ob to time, ob time, o/b to |

Date and time are combined; missing time = 00:00:00. `X1_of_invited_guest__c` and `Reason_for_Inviting__c` are deliberately not mapped (the first is a lookup and caused MALFORMED_ID failures).

### Invitation lists (Swoogo → `Guest_List__c`)

Membership keyed by Swoogo `contact_id` → Contact `contact_external_id__c`. If a contact is on several lists, the most recent `updated_at`/`created_at` wins.

| Swoogo | Salesforce | Mapping |
| --- | --- | --- |
| list `name` | `Invitation_Tier__c` | Copied |
| member `status` | `Invitation_Status__c` | not_sent/notsent/unsent/pending/no_email_sent → Bounced Email; sent/invited/no_response → No Response; visited/viewed/opened → Visited; accepted/confirmed/registered → Accepted; declined/rejected/denied → Declined; unknown → unchanged |

### Attendance (Swoogo → `Session_Attendance__c`)

Key = Guest List (`Swoogo_Registrant_Id__c` = `registrant_id`) + Sub Event (`Sub_Event_ID__c` = `session_id`). Duplicate rows merged. `Attended__c` = has `check_in_date`; `Registered__c` = session in registrant's `session_ids` (or = attended if registrant not in this fetch). Existing rows always overwritten.

### Outbound payloads (Salesforce → Swoogo)

| Salesforce | Swoogo | Main guest | Accompanying |
| --- | --- | --- | --- |
| Contact `Email`, `FirstName`, `LastName` | contact / registrant fields | ✓ | ✓ |
| Contact Id | `c_8598114` | ✓ (create or update) | ✓ |
| `Guest_Tiers__c` | invitation list (by name) / `reg_type_id` | list | reg type |
| `Company__c`, `Title__c`, Contact `MobilePhone` | `company`, `job_title`, `mobile_phone` | | ✓ |
| `Invitation__r.External_Event_Id__c` | `event_id` | ✓ | ✓ |
| Main guest `Swoogo_Registrant_Id__c` | group id | | ✓ |

## ID linking summary

| Salesforce field | Holds | Set by |
| --- | --- | --- |
| Contact `contact_external_id__c` | Swoogo contact id | Outbound queueable (if blank); inbound registrant sync (if blank) |
| `Guest_List__c.Swoogo_Registrant_Id__c` | Swoogo registrant id | Outbound (accompanying); inbound registrant sync (all) |
| `Invitation__c.External_Event_Id__c` | Swoogo event id | Pass 1 |
| `Sub_Event__c.Sub_Event_ID__c` | Swoogo session id | Pass 2 |
| Swoogo `c_8598114` | Salesforce Contact Id | Outbound only; never re-sent once Contact External Id exists |

## Error handling

| Situation | Behaviour |
| --- | --- |
| HTTP 401 | Token refreshed, call retried once |
| HTTP 429 (outbound) | `Retry Pending` status + one-off retry job |
| HTTP 429 (sync) | Event logged and skipped; picked up next run; no email |
| Other HTTP errors | `SwoogoException` "METHOD path [code]: body"; outbound → `Failed - …` status; sync → logged, admin emailed |
| DML failures | Partial-success DML (`Database.update/insert(…, false)`), failures logged to debug |
| Sync errors | `Webhook_Log_c__c` Status *Processed with errors*; `Last_Error_Time__c` set |

## Operations runbook

Run in Execute Anonymous:

| Task | Apex |
| --- | --- |
| Start the 15-minute sync | `SwoogoSyncScheduler.scheduleAll();` |
| Stop the sync | `SwoogoSyncScheduler.abortAll();` |
| Run a delta sync now | `SwoogoSyncBatch.run();` |
| Sync specific events | `SwoogoSyncBatch.run('12345,67890');` |
| Full resync (events + sessions only) | `SwoogoSyncBatch.runFull();` |
| Pause outbound pushes | Set `Swoogo_Settings__c.Enable_Guest_List_Trigger__c = false` (org default) |
| Resend one guest | Change `Approval__c` away from Approved and back to Approved |
| Check sync health | `Swoogo_Sync_State__c` (Last Sync / Last Error) and latest `Webhook_Log_c__c` rows named `SwoogoSync-P1-…`, `SwoogoSync-P2-…` |
| See pending chunk jobs | `SELECT CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SwoogoP2Chunk%'` |

Note: a FULL run (`runFull`) syncs events and sessions only; registrants, attendance and tiers start on the following DELTA runs.

## Tests

All Swoogo tests use `SwoogoCalloutMock` (routes by endpoint; flags `forceRateLimitOnce`, `forceUnauthorizedOnce`). Precondition: at least one `SwoogoConfig__mdt` record deployed. `GuestListTriggerTest` inserts `Swoogo_Settings__c` with the trigger enabled.
