/**
 * SwoogoSyncBatch — Pass 1
 *
 * FIRST RUN (Last_Sync_Time__c == null):
 *   Scope = ALL events from Swoogo
 *   Pass 2 scope = ALL events
 *
 * SUBSEQUENT RUNS (delta):
 *   Pass 1 scope = events updated_after last sync + all SF events
 *   Pass 2 scope = ONLY events that had registrant/attendance changes
 *                  (events where Swoogo reports updated registrants)
 *   This keeps Pass 2 fast even with 2000 events — only dirty events
 *   are re-synced for sessions/registrants/attendances.
 *
 * ALWAYS synced (every run regardless of delta):
 *   Sessions (Sub_Event__c) — full fetch but only for Pass 2 scope events
 *   Attendances — full fetch but only for Pass 2 scope events
 *
 * ORDERING: both Pass 1 (here) and Pass 2 (SwoogoSessionSyncBatch) process
 * events newest-first (by Swoogo created_at). If a 429 or any other error
 * cuts a run short, it's the oldest/lowest-priority events that get
 * skipped, not the newest — and skipped events are simply retried on the
 * next scheduled 15-min run rather than being explicitly rescheduled.
 */
public with sharing class SwoogoSyncBatch
    implements Database.Batchable<String>,
               Database.AllowsCallouts,
               Database.Stateful
{
    private List<String> scopeEventIds;
    private Boolean      isFirstRun;
    private Datetime     syncSince;
    private Datetime     batchStartTime;

    private Integer      totalEventsProcessed = 0;
    private List<String> allErrors            = new List<String>();
    private List<String> eventLog             = new List<String>();

    // eventId → invId for ALL events (used to pass to Pass 2)
    private Map<String, Id> eventIdToInvId = new Map<String, Id>();
    private Map<String, SwoogoApiClient.SwoogoEvent> eventDataMap
        = new Map<String, SwoogoApiClient.SwoogoEvent>();

    // On delta: only events that had registrant/attendance changes
    // On full:  all events
    private Set<String> dirtyEventIds = new Set<String>();

    // ── Constructors ──────────────────────────────────────────

    public SwoogoSyncBatch() {
        this.scopeEventIds = null;
    }

    public SwoogoSyncBatch(String eventIdsCsv) {
        this.scopeEventIds = String.isBlank(eventIdsCsv)
            ? null : eventIdsCsv.split(',');
    }

    // ── start() ───────────────────────────────────────────────

    public Iterable<String> start(Database.BatchableContext bc) {
        batchStartTime = Datetime.now();

        Swoogo_Sync_State__c state = Swoogo_Sync_State__c.getOrgDefaults();
        isFirstRun = (state.Last_Sync_Time__c == null);
        syncSince  = isFirstRun ? null : state.Last_Sync_Time__c;

        System.debug('SwoogoSyncBatch (Pass 1) START'
            + ' mode='      + (isFirstRun ? 'FULL' : 'DELTA')
            + ' syncSince=' + syncSince);

        Set<String> allEventIds = new Set<String>();

        if (scopeEventIds != null && !scopeEventIds.isEmpty()) {
            // Specific events requested
            for (String eid : scopeEventIds) {
                allEventIds.add(eid.trim());
                dirtyEventIds.add(eid.trim()); // always fully sync specific events
            }

        } else if (isFirstRun) {
            // FULL: get all events from Swoogo
            try {
                for (SwoogoApiClient.SwoogoEvent e : SwoogoApiClient.getAllEvents()) {
                    String eid = String.valueOf(e.id);
                    allEventIds.add(eid);
                    dirtyEventIds.add(eid);   // all events dirty on first run
                    eventDataMap.put(eid, e); // cache to avoid getEventById callout
                }
                System.debug('FULL: ' + allEventIds.size() + ' events');
            } catch (Exception ex) {
                allErrors.add('getAllEvents: ' + ex.getMessage());
            }

        } else {
            // DELTA: get events updated since last sync for Pass 1 (event metadata)
            try {
                for (SwoogoApiClient.SwoogoEvent e :
                    SwoogoApiClient.getEventsUpdatedAfter(syncSince)) {
                    String eid = String.valueOf(e.id);
                    allEventIds.add(eid);
                    dirtyEventIds.add(eid);
                    eventDataMap.put(eid, e); // cache to avoid getEventById callout
                }
            } catch (Exception ex) {
                allErrors.add('getEventsUpdatedAfter: ' + ex.getMessage());
            }

            // Include all SF events in Pass 1 scope so Invitation__c stays updated
            for (Invitation__c inv : [
                SELECT External_Event_Id__c FROM Invitation__c
                WHERE External_Event_Id__c != null
            ]) allEventIds.add(inv.External_Event_Id__c);

            // DELTA dirty events: events with registrants updated since last sync
            // This is what limits Pass 2 to only events that need re-syncing
            // We check which events have had any registrant activity
            // Strategy: ask Swoogo for registrants updated_after across all events
            // But since we can't do that globally, we mark events that Swoogo
            // returned as having updated registrants in Pass 1's execute()
            // dirtyEventIds will be populated during execute() below
        }

        // Always include pinned event IDs
        try {
            SwoogoConfig__mdt cfg = [
                SELECT EventIds__c FROM SwoogoConfig__mdt LIMIT 1
            ];
            if (String.isNotBlank(cfg.EventIds__c))
                for (String id : cfg.EventIds__c.split(',')) {
                    allEventIds.add(id.trim());
                    dirtyEventIds.add(id.trim());
                }
        } catch (Exception ex) {}

        System.debug('Pass 1 scope: ' + allEventIds.size()
            + ' | dirty (Pass 2): ' + dirtyEventIds.size());

        // Newest events first — same reasoning Pass 2 already used for its
        // ordering: if Apex/Swoogo limits force us to stop partway through,
        // it's the oldest/lowest-priority events that get cut, not the
        // newest ones. Events we don't have created_at for yet at this
        // point (SF-only or pinned events not returned by this run's
        // Swoogo query) sort to the end rather than costing an extra
        // callout to look them up here.
        return sortByCreatedAtDesc(new List<String>(allEventIds));
    }

    // ── execute() — upsert Invitation__c + detect dirty events ──

    public void execute(Database.BatchableContext bc, List<String> scope) {
        for (String eventId : scope) {
            eventId = eventId.trim();
            try {
                // Use cached event data from start() if available.
                // Only fetch individually if not cached — saves 1 callout per event
                // which is critical at 1000+ events.
                SwoogoApiClient.SwoogoEvent swoEvent = eventDataMap.get(eventId);
                if (swoEvent == null) {
                    try {
                        swoEvent = SwoogoApiClient.getEventById(eventId);
                        if (swoEvent != null) eventDataMap.put(eventId, swoEvent);
                    } catch (Exception ex) {
                        System.debug('getEventById ' + eventId + ': ' + ex.getMessage());
                    }
                }

                // On delta: check if this event has updated registrants
                // NOTE: dirty-detection via separate updated_after probe calls
                // was removed. It was unreliable (Swoogo's updated_after
                // filtering on session-attendances/sessions doesn't always
                // mark records dirty the way registrant updates do — this
                // caused sessions and attendance changes to be silently
                // missed on delta runs). Every event in Pass 1 scope is now
                // also added to Pass 2 scope directly below, so sessions
                // and attendance are re-checked on every run for every
                // event Swoogo reports as active. This costs at most 2
                // extra lightweight callouts per event but guarantees
                // correctness.
                if (!isFirstRun && scopeEventIds == null) {
                    dirtyEventIds.add(eventId);
                }

                // Upsert Invitation__c
                Id     invId     = null;
                String invAction = '';

                List<Invitation__c> invList = [
                    SELECT Id, Name, External_Event_Id__c,
                           Event_Start_Date__c, Event_End_Date__c,
                           Location__c, Status__c, Swoogo_Updated_At__c
                    FROM Invitation__c
                    WHERE External_Event_Id__c = :eventId LIMIT 1
                ];

                if (invList.isEmpty()) {
                    Invitation__c newInv = new Invitation__c(
                        External_Event_Id__c = eventId,
                        Name = swoEvent != null && String.isNotBlank(swoEvent.name)
                               ? swoEvent.name : 'Swoogo Event ' + eventId,
                        Status__c            = swoEvent != null
                                              ? SwoogoEventSyncService.mapStatus(swoEvent.status)
                                              : null,
                        Event_Start_Date__c  = swoEvent != null && swoEvent.start_date != null
                                              ? Date.valueOf(swoEvent.start_date) : null,
                        Event_End_Date__c    = swoEvent != null && swoEvent.end_date != null
                                              ? Date.valueOf(swoEvent.end_date) : null,
                        Location__c          = swoEvent != null
                                              ? (String.isNotBlank(swoEvent.location)
                                                 ? swoEvent.location
                                                 : swoEvent.event_venue_type) : null,
                        Swoogo_Updated_At__c = swoEvent != null ? swoEvent.updated_at : null
                    );
                    Database.SaveResult sr = Database.insert(newInv, false);
                    if (sr.isSuccess()) {
                        invId     = newInv.Id;
                        invAction = 'INSERTED';
                        dirtyEventIds.add(eventId); // new event = always dirty
                    } else {
                        String err = sr.getErrors()[0].getMessage();
                        allErrors.add('Event ' + eventId + ' inv insert: ' + err);
                        eventLog.add('Event ' + eventId + ' | SKIPPED: ' + err);
                        continue;
                    }
                } else {
                    Invitation__c inv = invList[0];
                    invId = inv.Id;
                    Boolean changed = false;
                    if (swoEvent != null) {
                        String newName = String.isNotBlank(swoEvent.name)
                                         ? swoEvent.name : inv.Name;
                        if (inv.Name != newName)
                            { inv.Name = newName; changed = true; }
                        if (swoEvent.start_date != null) {
                            Date d = Date.valueOf(swoEvent.start_date);
                            if (inv.Event_Start_Date__c != d)
                                { inv.Event_Start_Date__c = d; changed = true; }
                        }
                        if (swoEvent.end_date != null) {
                            Date d = Date.valueOf(swoEvent.end_date);
                            if (inv.Event_End_Date__c != d)
                                { inv.Event_End_Date__c = d; changed = true; }
                        }
                        String newLocation = String.isNotBlank(swoEvent.location)
                            ? swoEvent.location
                            : swoEvent.event_venue_type;
                        if (String.isNotBlank(newLocation)
                            && inv.Location__c != newLocation)
                            { inv.Location__c = newLocation; changed = true; }
                        String sfStatus = SwoogoEventSyncService.mapStatus(swoEvent.status);
                        if (sfStatus != null && inv.Status__c != sfStatus)
                            { inv.Status__c = sfStatus; changed = true; }
                        if (swoEvent.updated_at != null
                            && inv.Swoogo_Updated_At__c != swoEvent.updated_at)
                            { inv.Swoogo_Updated_At__c = swoEvent.updated_at; changed = true; }
                    }
                    if (changed) {
                        Database.update(inv, false);
                        invAction = 'UPDATED';
                    } else {
                        invAction = 'NO_CHANGE';
                    }
                }

                eventIdToInvId.put(eventId, invId);
                totalEventsProcessed++;
                eventLog.add('Event ' + eventId
                    + ' | inv=' + invAction
                    + ' | dirty=' + dirtyEventIds.contains(eventId));

            } catch (Exception e) {
                allErrors.add('Event ' + eventId + ': ' + e.getMessage());
                eventLog.add('Event ' + eventId + ' | ERROR: ' + e.getMessage());
                System.debug('Event ' + eventId + ' error: ' + e.getMessage());
            }
        }
    }

    // ── finish() — chain Pass 2 with only dirty events ────────

    public void finish(Database.BatchableContext bc) {
        String  mode   = isFirstRun ? 'FULL' : 'DELTA';
        Boolean hasErr = !allErrors.isEmpty();

        System.debug('[Pass 1 DONE] mode=' + mode
            + ' total=' + totalEventsProcessed
            + ' dirty=' + dirtyEventIds.size()
            + ' errors=' + allErrors.size());

        try {
            insert new Webhook_Log_c__c(
                Name        = 'SwoogoSync-P1-' + mode + '-'
                            + Datetime.now().format('yyyyMMdd-HHmmss'),
                Raw_Body__c = '[Pass 1 - Events] total=' + totalEventsProcessed
                            + ' dirty=' + dirtyEventIds.size() + '\n'
                            + String.join(eventLog, '\n')
                            + (hasErr ? '\n\nERRORS:\n'
                                      + String.join(allErrors, '\n') : ''),
                Status__c   = hasErr ? 'Processed with errors' : 'Processed'
            );
        } catch (Exception e) {}

        // Pass 2: only dirty events (have registrant/attendance changes)
        // On first run = all events
        // On delta = only events with activity since last sync
        //
        // IMPORTANT: only include events whose Invitation__c was actually
        // resolved in Pass 1 (eventIdToInvId). Previously dirtyEventIds
        // could contain an event that failed during Invitation__c
        // creation/lookup in execute() (e.g. transient callout error) —
        // that event would still flow into Pass 2, which would then
        // silently skip it (no Invitation__c found) with no visible
        // error. New events created in Swoogo were affected by this:
        // if Invitation__c creation hiccuped even once, sessions for
        // that event would never sync on subsequent runs because the
        // event already existed in SF the next time around, so it
        // stopped showing up in getEventsUpdatedAfter unless Swoogo
        // also recorded another update to it.
        List<String> pass2Scope = new List<String>();
        for (String eid : dirtyEventIds) {
            if (eventIdToInvId.containsKey(eid) && eventIdToInvId.get(eid) != null) {
                pass2Scope.add(eid);
            } else {
                eventLog.add('Event ' + eid
                    + ' | EXCLUDED FROM PASS 2: Invitation__c not resolved in Pass 1');
            }
        }

        if (pass2Scope.isEmpty()) {
            System.debug('Pass 2: no dirty events — skipping');
            updateSyncState(hasErr);
            return;
        }

        // Sort pass2Scope: new events (no Sub_Event__c in SF yet) first,
        // existing events after. This ensures newly created events in
        // Swoogo get their sessions/registrants/attendance synced as
        // fast as possible — they appear at the front of chunk 1 rather
        // than potentially ending up in a later chunk behind existing events.
        Set<Id> invIdsInScope = new Set<Id>();
        for (String eid : pass2Scope) {
            Id invId = eventIdToInvId.get(eid);
            if (invId != null) invIdsInScope.add(invId);
        }
        Set<Id> invIdsWithSessions = new Set<Id>();
        for (Sub_Event__c se : [
            SELECT Invitation__c FROM Sub_Event__c
            WHERE Invitation__c IN :invIdsInScope
        ]) invIdsWithSessions.add(se.Invitation__c);

        List<String> newEvents      = new List<String>();
        List<String> existingEvents = new List<String>();
        for (String eid : pass2Scope) {
            Id invId = eventIdToInvId.get(eid);
            if (invId != null && !invIdsWithSessions.contains(invId)) {
                newEvents.add(eid);
            } else {
                existingEvents.add(eid);
            }
        }
        List<String> orderedScope = new List<String>();
        orderedScope.addAll(newEvents);
        orderedScope.addAll(existingEvents);

        // Sort orderedScope by Swoogo created_at descending — newest
        // events processed first in Pass 2 so recently created events
        // get their sessions/registrants/attendance synced immediately.
        // created_at is cached in eventDataMap from Pass 1 API calls.
        orderedScope.sort();  // initial stable sort by event id as tiebreaker
        orderedScope = sortByCreatedAtDesc(orderedScope);

        System.debug('Chaining Pass 2 for '
            + orderedScope.size() + ' events ('
            + newEvents.size() + ' new, '
            + existingEvents.size() + ' existing) ordered newest first');

        Database.executeBatch(
            new SwoogoSessionSyncBatch(
                orderedScope,
                isFirstRun,
                syncSince,
                batchStartTime),
            1);
    }

    // Used by both start() (Pass 1 scope) and finish() (Pass 2 scope) to
    // keep newest-events-first ordering consistent end to end.
    private List<String> sortByCreatedAtDesc(List<String> eventIdList) {
        // Build list of (created_at, eventId) pairs, sort desc, return ids
        List<String[]> pairs = new List<String[]>();
        for (String eid : eventIdList) {
            SwoogoApiClient.SwoogoEvent ev = eventDataMap.get(eid);
            String createdAt = (ev != null && ev.created_at != null)
                ? ev.created_at : '0000-00-00 00:00:00';
            pairs.add(new String[]{ createdAt, eid });
        }
        // Bubble sort descending by created_at (small list, acceptable)
        for (Integer i = 0; i < pairs.size() - 1; i++) {
            for (Integer j = 0; j < pairs.size() - 1 - i; j++) {
                if (pairs[j][0] < pairs[j+1][0]) {
                    String[] tmp = pairs[j];
                    pairs[j]     = pairs[j+1];
                    pairs[j+1]   = tmp;
                }
            }
        }
        List<String> sorted = new List<String>();
        for (String[] p : pairs) sorted.add(p[1]);
        return sorted;
    }

    private void updateSyncState(Boolean hasErr) {
        try {
            Swoogo_Sync_State__c state = Swoogo_Sync_State__c.getOrgDefaults();
            state.Last_Sync_Time__c  = batchStartTime;
            state.Last_Error_Time__c = hasErr
                ? Datetime.now() : state.Last_Error_Time__c;
            upsert state;
        } catch (Exception e) {
            System.debug('Sync state update failed: ' + e.getMessage());
        }
    }

    // ── Static helpers ────────────────────────────────────────

    public static Id run() {
        return Database.executeBatch(new SwoogoSyncBatch(), 1);
    }

    public static Id run(String eventIdsCsv) {
        return Database.executeBatch(new SwoogoSyncBatch(eventIdsCsv), 1);
    }

    public static Id runFull() {
        Swoogo_Sync_State__c state = Swoogo_Sync_State__c.getOrgDefaults();
        state.Last_Sync_Time__c = null;
        upsert state;
        return Database.executeBatch(new SwoogoSyncBatch(), 1);
    }
}