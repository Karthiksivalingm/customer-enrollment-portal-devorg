public with sharing class SwoogoSubEventSyncService {

    // ── Full sync — all sessions for one event ────────────────
    // Used on first run

    public static void syncAllSubEvents(String eventId, Id invitationId) {
        List<SwoogoApiClient.SwoogoSession> sessions =
            SwoogoApiClient.getSessionsForEvent(eventId);
        upsertSubEvents(eventId, invitationId, sessions, 'FULL');
    }

    // ── Delta sync — sessions updated after last sync time ────
    // Used on subsequent runs

    public static void syncDeltaSubEvents(
        String eventId, Id invitationId, Datetime since)
    {
        List<SwoogoApiClient.SwoogoSession> sessions =
            SwoogoApiClient.getSessionsUpdatedAfter(eventId, since);
        if (sessions.isEmpty()) {
            System.debug('SubEventSync DELTA: no sessions updated after '
                + since + ' for event=' + eventId);
            return;
        }
        upsertSubEvents(eventId, invitationId, sessions, 'DELTA');
    }

    // ── Core upsert logic ─────────────────────────────────────

    public static void upsertSubEvents(
        String eventId,
        Id invitationId,
        List<SwoogoApiClient.SwoogoSession> sessions,
        String mode)
    {
        if (sessions == null || sessions.isEmpty()) return;
        if (invitationId == null) {
            System.debug('SubEventSync: null invitationId for event=' + eventId);
            return;
        }

        // Build set of Swoogo session IDs from this batch
        Set<String> swoIds = new Set<String>();
        for (SwoogoApiClient.SwoogoSession s : sessions)
            if (s.id != null) swoIds.add(String.valueOf(s.id));

        // Query existing Sub_Event__c records for this invitation
        Map<String, Sub_Event__c> existing = new Map<String, Sub_Event__c>();
        for (Sub_Event__c se : [
            SELECT Id, Sub_Event_ID__c, Name, Sub_Event_Name__c,
                   Date__c, Start_DateTime__c, End_DateTime__c,
                   Description__c, Swoogo_Updated_At__c
            FROM Sub_Event__c
            WHERE Invitation__c = :invitationId
              AND Sub_Event_ID__c IN :swoIds
        ]) existing.put(se.Sub_Event_ID__c, se);

        List<Sub_Event__c> toInsert = new List<Sub_Event__c>();
        List<Sub_Event__c> toUpdate = new List<Sub_Event__c>();

        for (SwoogoApiClient.SwoogoSession s : sessions) {
            if (s.id == null) continue;

            String sk    = String.valueOf(s.id);
            String sName = String.isBlank(s.name) ? 'Session ' + s.id : s.name;
            String cleanDesc = stripHtml(s.description);

            if (existing.containsKey(sk)) {
                Sub_Event__c se = existing.get(sk);
                Boolean changed = false;

                if (se.Sub_Event_Name__c != sName)
                    { se.Sub_Event_Name__c = sName; changed = true; }
                if (String.isNotBlank(s.session_date)) {
                    Date d = Date.valueOf(s.session_date);
                    if (se.Date__c != d)
                        { se.Date__c = d; changed = true; }
                }
                if (String.isNotBlank(s.session_date) && String.isNotBlank(s.start_time)) {
                    Datetime dt = buildDT(s.session_date, s.start_time);
                    if (dt != null && se.Start_DateTime__c != dt)
                        { se.Start_DateTime__c = dt; changed = true; }
                }
                if (String.isNotBlank(s.session_date) && String.isNotBlank(s.end_time)) {
                    Datetime dt = buildDT(s.session_date, s.end_time);
                    if (dt != null && se.End_DateTime__c != dt)
                        { se.End_DateTime__c = dt; changed = true; }
                }
                if (cleanDesc != null && se.Description__c != cleanDesc)
                    { se.Description__c = cleanDesc; changed = true; }
                if (s.updated_at != null && se.Swoogo_Updated_At__c != s.updated_at)
                    { se.Swoogo_Updated_At__c = s.updated_at; changed = true; }

                if (changed) toUpdate.add(se);

            } else {
                Datetime startDT = buildDT(s.session_date, s.start_time);
                Datetime endDT   = buildDT(s.session_date, s.end_time);

                toInsert.add(new Sub_Event__c(
                    Sub_Event_ID__c      = sk,
                    Invitation__c        = invitationId,
                    Sub_Event_Name__c    = sName,
                    Date__c              = String.isNotBlank(s.session_date)
                                          ? Date.valueOf(s.session_date) : null,
                    Start_DateTime__c    = startDT,
                    End_DateTime__c      = endDT,
                    Description__c       = cleanDesc,
                    Swoogo_Updated_At__c = s.updated_at
                ));
            }
        }

        if (!toInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(toInsert, false);
            Integer ok = 0;
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) { ok++; }
                else System.debug('SubEvent INSERT FAILED event=' + eventId
                    + ' id=' + toInsert[i].Sub_Event_ID__c
                    + ' error=' + results[i].getErrors()[0].getMessage());
            }
            System.debug('SubEventSync [' + mode + '] event=' + eventId
                + ' inserted OK=' + ok + ' failed=' + (toInsert.size() - ok));
        }

        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            Integer ok = 0;
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) { ok++; }
                else System.debug('SubEvent UPDATE FAILED event=' + eventId
                    + ' id=' + toUpdate[i].Sub_Event_ID__c
                    + ' error=' + results[i].getErrors()[0].getMessage());
            }
            System.debug('SubEventSync [' + mode + '] event=' + eventId
                + ' updated OK=' + ok + ' failed=' + (toUpdate.size() - ok));
        }
    }

    // ── Strip HTML tags from description ──────────────────────

    private static String stripHtml(String html) {
        if (String.isBlank(html)) return null;
        String clean = html.replaceAll('<[^>]+>', ' ');
        clean = clean.replace('&amp;',  '&')
                     .replace('&lt;',   '<')
                     .replace('&gt;',   '>')
                     .replace('&nbsp;', ' ')
                     .replace('&quot;', '"')
                     .replace('&#39;',  '\'');
        clean = clean.replaceAll('\\s+', ' ').trim();
        return String.isBlank(clean) ? null : clean;
    }

    // ── Combine date + time string into Datetime ──────────────
    // session_date = "2026-06-01", start_time = "09:00:00"

    private static Datetime buildDT(String datePart, String timePart) {
        if (String.isBlank(datePart) || String.isBlank(timePart)) return null;
        try {
            return Datetime.valueOf(datePart + ' ' + timePart);
        } catch (Exception e) {
            System.debug('buildDT failed: ' + datePart + ' ' + timePart
                + ' | ' + e.getMessage());
            return null;
        }
    }
}