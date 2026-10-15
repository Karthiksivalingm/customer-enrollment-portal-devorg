public with sharing class SwoogoInvitationTierSyncService {

    // Wraps the two pieces of membership data we need per contact: which
    // invitation list they're on, and their raw Swoogo invitation status.
    // Carrying both together (instead of two parallel maps) keeps the
    // "most recent membership wins" resolution in fetchInvitationTierMap()
    // simple — one map, one winner per contact.
    public class InvitationMembership {
        public String listName;
        public String rawStatus;
    }

    // Pulls current invitation-list membership from Swoogo for an event and
    // returns a map of Swoogo contact_id -> InvitationMembership (list name +
    // raw status), so that Guest_List__c.Invitation_Tier__c and
    // Guest_List__c.Invitation_Status__c can be stamped to match — covering
    // the case where a contact is moved between lists / their status changes
    // directly in Swoogo, outside the SF approval flow.
    //
    // CALLOUTS ONLY — no DML. Must be called during a batch's Phase 1
    // (callout) step; see applyInvitationTiers() for the DML half.
    //
    // If a contact appears on more than one invitation list for the event
    // (e.g. moved from one list to another and Swoogo hasn't cleaned up the
    // old membership yet), the membership with the most recent
    // updated_at/created_at wins — same "last in, first out by recency"
    // approach used for deduplicating attendance rows in
    // SwoogoAttendanceSyncService, just done via an explicit timestamp
    // comparison here (rather than relying on iteration order) since
    // membership rows carry real timestamps to sort by.
    public static Map<String, InvitationMembership> fetchInvitationTierMap(String eventId) {
        Map<String, InvitationMembership> contactIdToMembership =
            new Map<String, InvitationMembership>();
        Map<String, Datetime> contactIdToTimestamp = new Map<String, Datetime>();

        List<SwoogoApiClient.SwoogoInvitationList> lists =
            SwoogoApiClient.getInvitationListsForEvent(eventId);

        for (SwoogoApiClient.SwoogoInvitationList il : lists) {
            if (il.id == null) continue;

            for (SwoogoApiClient.SwoogoInvitationListMember m :
                    SwoogoApiClient.getInvitationListMembers(il.id)) {
                if (m.contact_id == null) continue;

                String   key   = String.valueOf(m.contact_id);
                Datetime stamp = parseTimestamp(
                    String.isNotBlank(m.updated_at) ? m.updated_at : m.created_at);

                Datetime existingStamp = contactIdToTimestamp.get(key);
                // Most recent timestamp wins. If either timestamp is
                // unparseable/missing, fall back to "last processed wins"
                // so we still make a decision rather than dropping the
                // contact entirely.
                if (existingStamp == null || stamp == null
                        || stamp >= existingStamp) {
                    InvitationMembership mem = new InvitationMembership();
                    mem.listName  = il.name;
                    mem.rawStatus = m.status;
                    contactIdToMembership.put(key, mem);
                    contactIdToTimestamp.put(key, stamp);
                }
            }
        }
        return contactIdToMembership;
    }

    // Stamps Guest_List__c.Invitation_Tier__c and Guest_List__c.Invitation_Status__c
    // for the given event's guests based on the contact_id -> membership map
    // fetched above.
    //
    // DML ONLY — no callouts. Safe to call during a batch's Phase 2 step.
    public static void applyInvitationTiers(
        Id invId, Map<String, InvitationMembership> contactIdToMembership)
    {
        if (contactIdToMembership == null || contactIdToMembership.isEmpty()) return;

        List<Guest_List__c> guests = [
            SELECT Id, Invitation_Tier__c, Invitation_Status__c,
                   Contact__r.contact_external_id__c
            FROM Guest_List__c
            WHERE Invitation__c = :invId
              AND Contact__r.contact_external_id__c != null
        ];

        List<Guest_List__c> updates = new List<Guest_List__c>();
        for (Guest_List__c g : guests) {
            InvitationMembership mem =
                contactIdToMembership.get(g.Contact__r.contact_external_id__c);
            if (mem == null) continue;

            Boolean changed = false;
            Guest_List__c upd = new Guest_List__c(Id = g.Id);

            if (mem.listName != null && mem.listName != g.Invitation_Tier__c) {
                upd.Invitation_Tier__c = mem.listName;
                changed = true;
            }

            String mappedStatus = mapInvitationStatus(mem.rawStatus);
            if (mappedStatus != null && mappedStatus != g.Invitation_Status__c) {
                upd.Invitation_Status__c = mappedStatus;
                changed = true;
            }

            if (changed) updates.add(upd);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    // ── Raw Swoogo status → SF Invitation_Status__c picklist ──────────
    //
    // SF picklist values: Bounced Email / No Response / Visited / Accepted / Declined
    //
    // Confirmed raw Swoogo values (via debug run against a live event):
    //   "visited"  -> Visited
    //   "accepted" -> Accepted
    // The remaining three (not-yet-sent / sent-no-response / declined) follow
    // the same lowercase, single/two-word pattern, so this is matched
    // defensively: the raw string is normalized (lowercased, trimmed,
    // spaces/hyphens collapsed to underscores) and checked against known
    // variants for each bucket, rather than a single exact string per bucket.
    // Anything unrecognized is logged and left unmapped (returns null),
    // so Invitation_Status__c is never blanked or set incorrectly on a
    // value we haven't seen before — it just doesn't change until the
    // mapping is extended.
    public static String mapInvitationStatus(String rawStatus) {
        if (String.isBlank(rawStatus)) return null;

        String norm = rawStatus.toLowerCase().trim()
            .replace('-', '_')
            .replace(' ', '_');

        if (norm == 'not_sent' || norm == 'notsent' || norm == 'unsent'
            || norm == 'pending' || norm == 'no_email_sent') {
            return 'Bounced Email';
        }
        if (norm == 'sent' || norm == 'invited' || norm == 'no_response') {
            return 'No Response';
        }
        if (norm == 'visited' || norm == 'viewed' || norm == 'opened') {
            return 'Visited';
        }
        if (norm == 'accepted' || norm == 'confirmed' || norm == 'registered') {
            return 'Accepted';
        }
        if (norm == 'declined' || norm == 'rejected' || norm == 'denied') {
            return 'Declined';
        }

        System.debug('SwoogoInvitationTierSyncService.mapInvitationStatus: '
            + 'unrecognized raw status "' + rawStatus + '" — '
            + 'Invitation_Status__c left unchanged for this guest. '
            + 'Extend mapInvitationStatus() once the correct bucket is confirmed.');
        return null;
    }

    // Swoogo timestamps come back as "yyyy-MM-dd HH:mm:ss", which
    // Datetime.valueOf() parses directly. Returns null if blank/unparseable
    // rather than throwing, so a bad timestamp doesn't break the whole sync.
    private static Datetime parseTimestamp(String raw) {
        if (String.isBlank(raw)) return null;
        try {
            return Datetime.valueOf(raw);
        } catch (Exception ex) {
            System.debug('parseTimestamp error for "' + raw + '": ' + ex.getMessage());
            return null;
        }
    }
}