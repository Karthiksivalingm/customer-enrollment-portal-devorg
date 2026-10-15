public with sharing class SwoogoEventSyncService {

    // ── Full sync — all events from Swoogo ────────────────────
    // Used on first run (Last_Sync_Time__c is null)

    public static void syncAllEvents() {
        List<SwoogoApiClient.SwoogoEvent> swoEvents = SwoogoApiClient.getAllEvents();
        upsertEvents(swoEvents, 'FULL');
    }

    // ── Delta sync — only events updated after last sync time ─
    // Used on subsequent runs

    public static void syncDeltaEvents(Datetime since) {
        List<SwoogoApiClient.SwoogoEvent> swoEvents =
            SwoogoApiClient.getEventsUpdatedAfter(since);
        if (swoEvents.isEmpty()) {
            System.debug('EventSync DELTA: no events updated after ' + since);
            return;
        }
        upsertEvents(swoEvents, 'DELTA');
    }

    // ── Sync a specific set of event IDs (used by batch) ─────

    public static void syncEventIds(Set<String> eventIds) {
        List<SwoogoApiClient.SwoogoEvent> swoEvents =
            new List<SwoogoApiClient.SwoogoEvent>();
        for (String eid : eventIds) {
            try {
                SwoogoApiClient.SwoogoEvent e = SwoogoApiClient.getEventById(eid.trim());
                if (e != null && e.id != null) swoEvents.add(e);
            } catch (Exception ex) {
                System.debug('EventSync fetch error ' + eid + ': ' + ex.getMessage());
            }
        }
        upsertEvents(swoEvents, 'SPECIFIC');
    }

    // ── Core upsert logic ─────────────────────────────────────

    public static void upsertEvents(
        List<SwoogoApiClient.SwoogoEvent> swoEvents, String mode)
    {
        if (swoEvents == null || swoEvents.isEmpty()) return;

        // Build set of external IDs to query existing records
        Set<String> extIds = new Set<String>();
        for (SwoogoApiClient.SwoogoEvent e : swoEvents)
            if (e.id != null) extIds.add(String.valueOf(e.id));

        Map<String, Invitation__c> existing = new Map<String, Invitation__c>();
        for (Invitation__c inv : [
            SELECT Id, External_Event_Id__c, Name,
                   Event_Start_Date__c, Event_End_Date__c,
                   Location__c, Status__c, Swoogo_Updated_At__c
            FROM Invitation__c
            WHERE External_Event_Id__c IN :extIds
        ]) existing.put(inv.External_Event_Id__c, inv);

        List<Invitation__c> toInsert = new List<Invitation__c>();
        List<Invitation__c> toUpdate = new List<Invitation__c>();

        for (SwoogoApiClient.SwoogoEvent e : swoEvents) {
            if (e.id == null) continue;

            String  extId     = String.valueOf(e.id);
            String  name      = String.isBlank(e.name) ? 'Swoogo Event ' + e.id : e.name;
            Boolean isDeleted = (e.status == 'deleted' || e.status == 'archived'
                              || e.status == 'closed');
            String  sfStatus  = mapStatus(e.status);

            if (existing.containsKey(extId)) {
                Invitation__c inv = existing.get(extId);
                Boolean changed   = false;

                if (e.name != null && inv.Name != name)
                    { inv.Name = name; changed = true; }
                if (e.start_date != null) {
                    Date d = Date.valueOf(e.start_date);
                    if (inv.Event_Start_Date__c != d)
                        { inv.Event_Start_Date__c = d; changed = true; }
                }
                if (e.end_date != null) {
                    Date d = Date.valueOf(e.end_date);
                    if (inv.Event_End_Date__c != d)
                        { inv.Event_End_Date__c = d; changed = true; }
                }
                String newLoc = String.isNotBlank(e.location)
                    ? e.location : e.event_venue_type;
                if (String.isNotBlank(newLoc) && inv.Location__c != newLoc)
                    { inv.Location__c = newLoc; changed = true; }
                if (isDeleted && inv.Status__c != 'Cancelled')
                    { inv.Status__c = 'Cancelled'; changed = true; }
                else if (!isDeleted && sfStatus != null && inv.Status__c != sfStatus)
                    { inv.Status__c = sfStatus; changed = true; }
                if (e.updated_at != null && inv.Swoogo_Updated_At__c != e.updated_at)
                    { inv.Swoogo_Updated_At__c = e.updated_at; changed = true; }

                if (changed) toUpdate.add(inv);

            } else if (!isDeleted) {
                toInsert.add(new Invitation__c(
                    External_Event_Id__c = extId,
                    Name                 = name,
                    Event_Start_Date__c  = e.start_date != null
                                          ? Date.valueOf(e.start_date) : null,
                    Event_End_Date__c    = e.end_date   != null
                                          ? Date.valueOf(e.end_date)   : null,
                    Location__c          = String.isNotBlank(e.location)
                                          ? e.location : e.event_venue_type,
                    Status__c            = sfStatus,
                    Swoogo_Updated_At__c = e.updated_at
                ));
            }
        }

        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, false);
            System.debug('EventSync [' + mode + '] inserted=' + toInsert.size());
        }
        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
            System.debug('EventSync [' + mode + '] updated=' + toUpdate.size());
        }
    }

    // ── Status mapping ────────────────────────────────────────

    public static String mapStatus(String s) {
        if (s == null)        return null;
        if (s == 'draft')     return 'Draft';
        if (s == 'active')    return 'Active';
        if (s == 'published') return 'Active';
        if (s == 'live')      return 'Active';
        if (s == 'deleted')   return 'Cancelled';
        if (s == 'archived')  return 'Cancelled';
        if (s == 'closed')    return 'Cancelled';
        return s;
    }
}