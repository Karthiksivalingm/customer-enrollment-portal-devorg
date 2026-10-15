/**
 * SwoogoSessionSyncBatch — Pass 2
 *
 * Runs AFTER SwoogoSyncBatch (Pass 1) completes.
 * Processes events in chunks of CHUNK_SIZE, ordered newest-first (the
 * ordering is decided by SwoogoSyncBatch.finish() before this batch is
 * ever constructed). On 429 the event is logged as a (non-genuine) error
 * and skipped — no retry/reschedule. Because the newest events are always
 * processed first, a rate limit only ever costs us older, lower-priority
 * events, and those are picked back up automatically on the next
 * scheduled 15-min run via the normal delta sync.
 *
 * Sync strategy:
 *   FULL SYNC (first run)        — Sessions only. No registrants/attendance.
 *   DELTA SYNC (every run after) — Sessions: updated_after delta.
 *                                  Registrants + Attendance: always full fetch.
 */
public with sharing class SwoogoSessionSyncBatch
    implements Database.Batchable<String>,
               Database.AllowsCallouts,
               Database.Stateful
{
    // Lowered from 10 → 6: fewer events processed per scheduler tick means
    // fewer callouts fired in a short burst, which spreads load out more
    // evenly across Swoogo's 10-min rate-limit window and reduces the
    // chance of hitting 429 in the first place.
    private static final Integer CHUNK_SIZE = 6;

    private List<String> eventIds;
    private List<String> remainingAfterThis;
    private Boolean      isFirstRun;
    private Datetime     syncSince;
    private Datetime     batchStartTime;
    private Boolean      isLastChunk;

    private Integer      totalSubEventsSync   = 0;
    private Integer      totalRegistrantsSync = 0;
    private Integer      totalAttendancesSync = 0;
    private List<String> allErrors            = new List<String>();
    private List<String> eventLog             = new List<String>();

    // ── Constructor ───────────────────────────────────────────────────────

    // Called by SwoogoSyncBatch.finish() (first chunk) and by
    // SwoogoSessionSyncChunkScheduler (subsequent chunks). 429s are no
    // longer retried (see execute()/finish()), so there's no longer a
    // separate retry-attempt code path — every call looks the same.
    public SwoogoSessionSyncBatch(
        List<String> allEventIds,
        Boolean isFirstRun,
        Datetime syncSince,
        Datetime batchStartTime)
    {
        this.isFirstRun     = isFirstRun;
        this.syncSince      = syncSince;
        this.batchStartTime = batchStartTime;

        if (allEventIds == null) allEventIds = new List<String>();

        // Safety net: de-dupe defensively. The 2026-07 "Batchable instance
        // is too big" incident was caused by the same event ids being
        // appended repeatedly on every 429 in a chunk (fixed below in
        // execute()) — de-duping here is a cheap guard against that same
        // failure mode recurring from any other path.
        Set<String> deduped = new Set<String>(allEventIds);
        allEventIds = new List<String>(deduped);

        // Hard cap: this org's real event catalog is nowhere near this
        // size. If the event list is ever this large, something upstream
        // is duplicating/runaway again — better to fail loud and log than
        // to silently try to enqueue a batch too big to serialize.
        Integer MAX_SANE_EVENT_COUNT = 5000;
        if (allEventIds.size() > MAX_SANE_EVENT_COUNT) {
            System.debug(LoggingLevel.ERROR,
                'SwoogoSessionSyncBatch: event list size ' + allEventIds.size()
                + ' exceeds sane cap ' + MAX_SANE_EVENT_COUNT
                + ' — truncating to prevent a runaway batch. Investigate the'
                + ' caller for duplicate accumulation.');
            try {
                insert new Webhook_Log_c__c(
                    Name        = 'SwoogoSync-P2-RUNAWAY-GUARD-'
                                + Datetime.now().format('yyyyMMdd-HHmmss'),
                    Raw_Body__c = 'Event list size ' + allEventIds.size()
                                + ' exceeded cap ' + MAX_SANE_EVENT_COUNT
                                + '; truncated. Investigate caller for duplicate accumulation.',
                    Status__c   = 'Processed with errors'
                );
            } catch (Exception e) {}
            List<String> fromSet   = new List<String>(deduped);
            List<String> truncated = new List<String>();
            for (Integer i = 0; i < MAX_SANE_EVENT_COUNT && i < fromSet.size(); i++) {
                truncated.add(fromSet[i]);
            }
            allEventIds = truncated;
        }

        if (allEventIds.size() <= CHUNK_SIZE) {
            this.eventIds           = allEventIds;
            this.remainingAfterThis = new List<String>();
            this.isLastChunk        = true;
        } else {
            this.eventIds           = new List<String>();
            this.remainingAfterThis = new List<String>();
            for (Integer i = 0; i < allEventIds.size(); i++) {
                if (i < CHUNK_SIZE) this.eventIds.add(allEventIds[i]);
                else this.remainingAfterThis.add(allEventIds[i]);
            }
            this.isLastChunk = false;
        }
    }

    // ── start() ───────────────────────────────────────────────────────────

    public Iterable<String> start(Database.BatchableContext bc) {
        System.debug('SwoogoSessionSyncBatch START'
            + ' mode='     + (isFirstRun ? 'FULL' : 'DELTA')
            + ' events='   + eventIds.size()
            + ' remaining=' + remainingAfterThis.size());
        return eventIds;
    }

    // ── execute() ─────────────────────────────────────────────────────────

    public void execute(Database.BatchableContext bc, List<String> scope) {
        for (String eventId : scope) {
            eventId = eventId.trim();
            Integer calloutsAtStart = Limits.getCallouts();

            try {
                // ── Resolve SF Invitation__c ──────────────────────
                List<Invitation__c> invList = [
                    SELECT Id FROM Invitation__c
                    WHERE External_Event_Id__c = :eventId LIMIT 1
                ];
                if (invList.isEmpty()) {
                    eventLog.add('Event ' + eventId + ' | SKIPPED: no Invitation__c');
                    continue;
                }
                Id invId = invList[0].Id;

                // Count existing Sub_Event__c to detect new events and
                // correctly gate attendance fetching
                Integer existingSubEventCount = [
                    SELECT COUNT() FROM Sub_Event__c WHERE Invitation__c = :invId
                ];
                Boolean isNewEventToSF       = (existingSubEventCount == 0);
                Boolean eventHasSessionsInSF = (existingSubEventCount > 0);

                // ══════════════════════════════════════════════
                // PHASE 1: ALL CALLOUTS — no DML until all done
                // ══════════════════════════════════════════════

                // 1a. Sessions
                // FULL or brand-new event → full fetch (catches imported
                // sessions with stale/missing timestamps).
                // DELTA existing event    → updated_after delta fetch only.
                List<SwoogoApiClient.SwoogoSession> sessions =
                    new List<SwoogoApiClient.SwoogoSession>();
                try {
                    sessions = (isFirstRun || isNewEventToSF)
                        ? SwoogoApiClient.getSessionsForEvent(eventId)
                        : SwoogoApiClient.getSessionsUpdatedAfter(eventId, syncSince);
                } catch (Exception ex) {
                    String msg = ex.getMessage();
                    allErrors.add('Event ' + eventId + ' sessions fetch: ' + msg);
                    eventLog.add('Event ' + eventId + ' | SESSIONS FETCH FAILED: ' + msg);
                    // 429s are no longer retried. We process events newest
                    // first (see SwoogoSyncBatch.start()/finish()), so by
                    // the time a rate limit is hit it lands on an older,
                    // lower-priority event — that event's sessions/
                    // registrants/attendance just pick up on the next
                    // scheduled run (15 min later) via the normal delta
                    // sync. No special handling needed.
                    continue;
                }

                // 1b–1d: Registrants + Attendance — DELTA runs only.
                // FULL run is Event + Sessions only per spec.
                List<SwoogoApiClient.SwoogoRegistrant> registrants =
                    new List<SwoogoApiClient.SwoogoRegistrant>();
                SwoogoQuestionMapService.EventQuestionMap questionMap = null;
                List<Map<String,Object>> rawRegistrantMaps =
                    new List<Map<String,Object>>();
                List<SwoogoApiClient.SessionAttendance> attendances =
                    new List<SwoogoApiClient.SessionAttendance>();
                Map<String, SwoogoInvitationTierSyncService.InvitationMembership> invitationTierMap =
                    new Map<String, SwoogoInvitationTierSyncService.InvitationMembership>();

                if (!isFirstRun) {
                    // 1b. Registrants — always full fetch on delta
                    try {
                        registrants = SwoogoApiClient.getRegistrantsForEvent(
                            eventId, new List<String>());
                    } catch (Exception ex) {
                        allErrors.add('Event ' + eventId + ' registrants fetch: ' + ex.getMessage());
                    }

                    // Warn if Swoogo returned 0 registrants but we know
                    // this event has Guest_List__c records in SF — likely
                    // a transient Swoogo API issue; next run will retry.
                    if (registrants.isEmpty()) {
                        Integer existingGuests = [
                            SELECT COUNT() FROM Guest_List__c WHERE Invitation__c = :invId
                        ];
                        if (existingGuests > 0) {
                            eventLog.add('Event ' + eventId
                                + ' | WARN: 0 registrants from Swoogo but '
                                + existingGuests + ' Guest_List__c exist in SF '
                                + '— likely transient API issue, will retry next run');
                        }
                    }

                    // 1c. Question map — only if registrants exist
                    if (!registrants.isEmpty()) {
                        try {
                            questionMap = SwoogoQuestionMapService.getMapForEvent(eventId);
                        } catch (Exception ex) {
                            System.debug('QuestionMap error event=' + eventId + ': ' + ex.getMessage());
                        }
                        if (questionMap != null && questionMap.hasAnyMapping) {
                            try {
                                List<String> extraFields = questionMap.customFieldsList;
                                registrants = SwoogoApiClient.getRegistrantsForEvent(
                                    eventId, extraFields);
                                rawRegistrantMaps = SwoogoApiClient.getRawRegistrants(
                                    eventId, extraFields, null);
                            } catch (Exception ex) {
                                allErrors.add('Event ' + eventId + ' registrants re-fetch: ' + ex.getMessage());
                            }
                        }
                    }

                    // 1d. Attendance — full fetch on delta.
                    // Gate on eventHasSessionsInSF OR sessions fetched this
                    // run — do NOT gate on `sessions` (delta fetch) alone,
                    // since that's empty when no sessions changed even if the
                    // event has 100+ existing sessions with new check-ins.
                    if (eventHasSessionsInSF || !sessions.isEmpty()) {
                        try {
                            attendances = SwoogoApiClient.getSessionAttendances(eventId);
                        } catch (Exception ex) {
                            allErrors.add('Event ' + eventId + ' attendances fetch: ' + ex.getMessage());
                        }
                    }

                    // 1e. Invitation list membership (fetch only — DML
                    // happens in Phase 2 below, see 2d). Keeps
                    // Guest_List__c.Invitation_Tier__c and
                    // Guest_List__c.Invitation_Status__c in sync with
                    // whichever list/status the contact actually has in
                    // Swoogo, covering the case where someone is moved
                    // between lists or their invitation status changes
                    // directly in Swoogo, outside the SF approval flow.
                    try {
                        invitationTierMap =
                            SwoogoInvitationTierSyncService.fetchInvitationTierMap(eventId);
                    } catch (Exception ex) {
                        allErrors.add('Event ' + eventId + ' invitation tier fetch: ' + ex.getMessage());
                    }
                }

                System.debug('Event ' + eventId
                    + ' fetched: sessions=' + sessions.size()
                    + ' regs=' + registrants.size()
                    + ' att=' + attendances.size()
                    + ' callouts=' + Limits.getCallouts());

                // ══════════════════════════════════════════════
                // PHASE 2: ALL DML — no callouts after this point
                // ══════════════════════════════════════════════

                // 2a. Sub_Event__c
                Integer sessionCount = sessions.size();
                if (!sessions.isEmpty()) {
                    try {
                        SwoogoSubEventSyncService.upsertSubEvents(
                            eventId, invId, sessions, isFirstRun ? 'FULL' : 'DELTA');
                        totalSubEventsSync += sessionCount;
                    } catch (Exception ex) {
                        allErrors.add('Event ' + eventId + ' sessions DML: ' + ex.getMessage());
                    }
                }

                // 2b. Contact + Guest_List__c
                Integer regCount = registrants.size();
                if (!registrants.isEmpty()) {
                    try {
                        SwoogoRegistrantSyncService.syncRegistrants(
                            registrants, invId, questionMap, rawRegistrantMaps);
                        totalRegistrantsSync += regCount;
                    } catch (Exception ex) {
                        allErrors.add('Event ' + eventId + ' registrants DML: ' + ex.getMessage());
                    }
                }

                // 2c. Session_Attendance__c
                Integer attCount = attendances.size();
                if (!attendances.isEmpty()) {
                    try {
                        SwoogoAttendanceSyncService.syncAttendances(
                            attendances, registrants, invId);
                        totalAttendancesSync += attCount;
                    } catch (Exception ex) {
                        allErrors.add('Event ' + eventId + ' attendances DML: ' + ex.getMessage());
                    }
                }

                // 2d. Guest_List__c.Invitation_Tier__c / Invitation_Status__c
                if (!invitationTierMap.isEmpty()) {
                    try {
                        SwoogoInvitationTierSyncService.applyInvitationTiers(invId, invitationTierMap);
                    } catch (Exception ex) {
                        allErrors.add('Event ' + eventId + ' invitation tier DML: ' + ex.getMessage());
                    }
                }

                eventLog.add(
                    'Event ' + eventId
                    + ' | newToSF='       + isNewEventToSF
                    + ' | startCallouts=' + calloutsAtStart
                    + ' | subEvents='     + sessionCount
                    + ' | regs='          + regCount
                    + ' | att='           + attCount
                    + ' | callouts='      + Limits.getCallouts()
                );

            } catch (Exception e) {
                allErrors.add('Event ' + eventId + ': ' + e.getMessage());
                eventLog.add('Event ' + eventId + ' | ERROR: ' + e.getMessage());
                System.debug('Pass 2 Event ' + eventId + ' error: '
                    + e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
    }

    // ── finish() ──────────────────────────────────────────────────────────

    public void finish(Database.BatchableContext bc) {
        String  mode   = isFirstRun ? 'FULL' : 'DELTA';
        Boolean hasErr = !allErrors.isEmpty();

        // 429s are expected and self-healing — they just mean this event
        // waits for the next scheduled run instead of getting retried
        // immediately. Don't count them toward the "should we email
        // someone" decision, or every rate-limit hit sends an alert for
        // something that isn't actually a problem.
        Boolean hasGenuineErr = false;
        for (String err : allErrors) {
            if (err == null || !err.contains('429')) {
                hasGenuineErr = true;
                break;
            }
        }

        String summary =
            '[SwoogoSync Pass 2 - ' + mode + ']'
            + ' SubEvents='   + totalSubEventsSync
            + ' Registrants=' + totalRegistrantsSync
            + ' Attendances=' + totalAttendancesSync
            + ' Errors='      + allErrors.size()
            + ' Remaining='   + remainingAfterThis.size();

        String fullLog = summary
            + '\n\n--- EVENT DETAILS ---\n'
            + String.join(eventLog, '\n');
        if (hasErr)
            fullLog += '\n\n--- ERRORS ---\n' + String.join(allErrors, '\n');

        System.debug(fullLog);

        try {
            insert new Webhook_Log_c__c(
                Name        = 'SwoogoSync-P2-' + mode + '-'
                            + Datetime.now().format('yyyyMMdd-HHmmss'),
                Raw_Body__c = fullLog,
                Status__c   = hasErr ? 'Processed with errors' : 'Processed'
            );
        } catch (Exception e) {}

        if (hasGenuineErr) {
            try {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
                mail.setSubject('Swoogo Sync [' + mode + '] Errors — ' + Date.today().format());
                mail.setPlainTextBody(summary + '\n\n' + String.join(allErrors, '\n'));
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            } catch (Exception e) {}
        }

        // ── Schedule next chunk if more events remain ───────────────────
        // 429s are no longer retried (see execute()) — an event that hit a
        // rate limit already fell through to allErrors/eventLog above and
        // gets picked up again on the next scheduled 15-min run.
        if (!remainingAfterThis.isEmpty()) {
            scheduleChunk(remainingAfterThis, 1);
            return;
        }

        // ── Last chunk: advance sync state ─────────────────────────────
        try {
            Swoogo_Sync_State__c state = Swoogo_Sync_State__c.getOrgDefaults();
            state.Last_Sync_Time__c  = batchStartTime;
            state.Last_Error_Time__c = hasErr
                ? Datetime.now() : state.Last_Error_Time__c;
            upsert state;
        } catch (Exception e) {}
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private void scheduleChunk(List<String> events, Integer delayMinutes) {
        Datetime runAt = Datetime.now().addMinutes(delayMinutes);
        String cronExp = runAt.second() + ' ' + runAt.minute() + ' '
            + runAt.hour() + ' ' + runAt.day() + ' ' + runAt.month()
            + ' ? ' + runAt.year();
        System.schedule(
            'SwoogoP2Chunk-' + Datetime.now().getTime(),
            cronExp,
            new SwoogoSessionSyncChunkScheduler(
                events, isFirstRun, syncSince, batchStartTime));
        System.debug('Scheduled ' + events.size()
            + ' events in ' + delayMinutes + ' min at ' + runAt);
    }
}