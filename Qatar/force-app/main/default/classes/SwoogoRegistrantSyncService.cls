public with sharing class SwoogoRegistrantSyncService {

    // ── Entry point — called from batch per event ─────────────
    // Syncs: Contact fields + Guest_List__c RSVP__c

    public static void syncRegistrants(
        List<SwoogoApiClient.SwoogoRegistrant> registrants,
        Id invitationId)
    {
        syncRegistrants(registrants, invitationId, null, null);
    }

    public static void syncRegistrants(
        List<SwoogoApiClient.SwoogoRegistrant> registrants,
        Id invitationId,
        SwoogoQuestionMapService.EventQuestionMap questionMap,
        List<Map<String,Object>> rawRegistrantMaps)
    {
        if (registrants == null || registrants.isEmpty()) return;

        // Filter out deleted registrants
        List<SwoogoApiClient.SwoogoRegistrant> active =
            new List<SwoogoApiClient.SwoogoRegistrant>();
        for (SwoogoApiClient.SwoogoRegistrant r : registrants)
            if (r.deleted != true) active.add(r);
        if (active.isEmpty()) return;

        // ── Step 1: Build Contact lookup sets ─────────────────

        Set<String> extIds = new Set<String>();
        Set<String> emails = new Set<String>();
        for (SwoogoApiClient.SwoogoRegistrant r : active) {
            if (String.isNotBlank(r.contact_id)) extIds.add(r.contact_id);
            if (String.isNotBlank(r.email))      emails.add(r.email.toLowerCase());
        }

        // Primary lookup: SF contact external id
        Map<String, Contact> byExtId = new Map<String, Contact>();
        if (!extIds.isEmpty()) {
            for (Contact c : [
                SELECT Id, contact_external_id__c,
                       FirstName, LastName, Email, Email_Office__c,
                       Title, MobilePhone, Phone
                FROM Contact
                WHERE contact_external_id__c IN :extIds
            ]) byExtId.put(c.contact_external_id__c, c);
        }

        // Fallback lookup: email — only for registrants not found by ext id
        Set<String> emailsToSearch = new Set<String>();
        for (SwoogoApiClient.SwoogoRegistrant r : active) {
            String ek = String.isNotBlank(r.contact_id) ? r.contact_id : null;
            if ((ek == null || !byExtId.containsKey(ek)) && String.isNotBlank(r.email))
                emailsToSearch.add(r.email.toLowerCase());
        }

        Map<String, Contact> byEmail = new Map<String, Contact>();
        if (!emailsToSearch.isEmpty()) {
            for (Contact c : [
                SELECT Id, contact_external_id__c,
                       FirstName, LastName, Email, Email_Office__c,
                       Admin_Email__c, Email_2__c, Private_Email__c,
                       Title, MobilePhone, Phone
                FROM Contact
                WHERE Email            IN :emailsToSearch
                   OR Email_Office__c  IN :emailsToSearch
                   OR Admin_Email__c   IN :emailsToSearch
                   OR Email_2__c       IN :emailsToSearch
                   OR Private_Email__c IN :emailsToSearch
            ]) {
                if (String.isNotBlank(c.Email))
                    byEmail.put(c.Email.toLowerCase(), c);
                if (String.isNotBlank(c.Email_Office__c))
                    byEmail.put(c.Email_Office__c.toLowerCase(), c);
                if (String.isNotBlank(c.Admin_Email__c))
                    byEmail.put(c.Admin_Email__c.toLowerCase(), c);
                if (String.isNotBlank(c.Email_2__c))
                    byEmail.put(c.Email_2__c.toLowerCase(), c);
                if (String.isNotBlank(c.Private_Email__c))
                    byEmail.put(c.Private_Email__c.toLowerCase(), c);
            }
        }

        // ── Step 2: Update Contact fields from Swoogo ─────────

        List<Contact> contactsToUpdate = new List<Contact>();
        Set<Id>       contactProcessed = new Set<Id>();

        // registrant_id (as string) → registration_status
        Map<String, String> regIdToStatus = new Map<String, String>();

        for (SwoogoApiClient.SwoogoRegistrant r : active) {
            if (r.id != null && String.isNotBlank(r.registration_status))
                regIdToStatus.put(String.valueOf(r.id), r.registration_status);

            Contact c = resolveContact(r, byExtId, byEmail);
            if (c == null || contactProcessed.contains(c.Id)) continue;

            Boolean changed = false;
            String extKey = String.isNotBlank(r.contact_id) ? r.contact_id : null;
            if (extKey != null && String.isBlank(c.contact_external_id__c))
                { c.contact_external_id__c = extKey; changed = true; }
            if (String.isNotBlank(r.first_name) && c.FirstName != r.first_name)
                { c.FirstName = r.first_name.length() > 40
                    ? r.first_name.left(40) : r.first_name; changed = true; }
            if (String.isNotBlank(r.last_name)    && c.LastName    != r.last_name)
                { c.LastName    = r.last_name;    changed = true; }
            if (String.isNotBlank(r.job_title)    && c.Title       != r.job_title)
                { c.Title       = r.job_title;    changed = true; }
            if (String.isNotBlank(r.mobile_phone) && c.MobilePhone != r.mobile_phone)
                { c.MobilePhone = r.mobile_phone; changed = true; }
            if (String.isNotBlank(r.work_phone)   && c.Phone       != r.work_phone)
                { c.Phone       = r.work_phone;   changed = true; }
            if (String.isNotBlank(r.email)        && c.Email_Office__c != r.email)
                { c.Email_Office__c = r.email;    changed = true; }

            if (changed) contactsToUpdate.add(c);
            contactProcessed.add(c.Id);
        }

        if (!contactsToUpdate.isEmpty()) {
            Database.update(contactsToUpdate, false);
            System.debug('RegistrantSync contacts updated=' + contactsToUpdate.size());
        }

        // ── Step 2b: Link/backfill Guest_List__c.Swoogo_Registrant_Id__c ──
        // For registrants created directly in Swoogo (not via the SF
        // approval → GuestListRegistrantQueueable flow), Guest_List__c
        // may already exist (matched by Contact + Invitation) but never
        // had Swoogo_Registrant_Id__c populated. Without this, attendance
        // sync can never match these guests (SwoogoAttendanceSyncService
        // looks up Guest_List__c strictly by Swoogo_Registrant_Id__c).
        // This step finds those guests and stamps the id so future
        // attendance/registrant syncs resolve correctly.

        Map<Id, String> contactIdToRegId = new Map<Id, String>();
        for (SwoogoApiClient.SwoogoRegistrant r : active) {
            if (r.id == null) continue;
            Contact c = resolveContact(r, byExtId, byEmail);
            if (c == null) continue;
            contactIdToRegId.put(c.Id, String.valueOf(r.id));
        }

        if (!contactIdToRegId.isEmpty()) {
            List<Guest_List__c> guestsToLink = new List<Guest_List__c>();
            for (Guest_List__c g : [
                SELECT Id, Contact__c, Swoogo_Registrant_Id__c
                FROM Guest_List__c
                WHERE Contact__c    IN :contactIdToRegId.keySet()
                  AND Invitation__c = :invitationId
            ]) {
                String regId = contactIdToRegId.get(g.Contact__c);
                if (regId != null && g.Swoogo_Registrant_Id__c != regId) {
                    g.Swoogo_Registrant_Id__c = regId;
                    guestsToLink.add(g);
                }
            }
            if (!guestsToLink.isEmpty()) {
                Database.update(guestsToLink, false);
                System.debug('RegistrantSync Guest_List__c linked to Swoogo_Registrant_Id__c: '
                    + guestsToLink.size());
            }
        }

        // ── Step 3: Update Guest_List__c RSVP__c ──────────────
        // Match directly on Swoogo_Registrant_Id__c for accuracy

        if (regIdToStatus.isEmpty()) return;

        List<Guest_List__c> guestsToUpdate = new List<Guest_List__c>();
        for (Guest_List__c g : [
            SELECT Id, Swoogo_Registrant_Id__c, RSVP__c
            FROM Guest_List__c
            WHERE Swoogo_Registrant_Id__c IN :regIdToStatus.keySet()
              AND Invitation__c            = :invitationId
        ]) {
            String rawStatus = regIdToStatus.get(g.Swoogo_Registrant_Id__c);
            if (String.isBlank(rawStatus)) continue;
            // Capitalise first letter to match SF picklist convention
            String newRsvp = rawStatus.substring(0, 1).toUpperCase()
                           + rawStatus.substring(1).toLowerCase();
            if (g.RSVP__c != newRsvp) {
                g.RSVP__c = newRsvp;
                guestsToUpdate.add(g);
            }
        }

        if (!guestsToUpdate.isEmpty()) {
            Database.update(guestsToUpdate, false);
            System.debug('RegistrantSync RSVP updated=' + guestsToUpdate.size());
        }

        // ── Step 4: Update Guest_List__c custom fields ─────────
        // Only runs if questionMap and rawRegistrantMaps are provided
        if (questionMap == null || !questionMap.hasAnyMapping
            || rawRegistrantMaps == null || rawRegistrantMaps.isEmpty()) return;

        // Build map: swoogo registrant_id → raw field map
        Map<String, Map<String,Object>> rawByRegId =
            new Map<String, Map<String,Object>>();
        for (Map<String,Object> raw : rawRegistrantMaps) {
            Object rid = raw.get('id');
            if (rid != null) rawByRegId.put(String.valueOf(rid), raw);
        }
        if (rawByRegId.isEmpty()) return;

        // Query Guest_List__c records to update custom fields
        // NOTE: Reason_for_Inviting__c intentionally excluded — no longer
        // mapped by SwoogoQuestionMapService, removed per explicit request.
        List<Guest_List__c> customFieldUpdates = new List<Guest_List__c>();
        for (Guest_List__c g : [
            SELECT Id, Swoogo_Registrant_Id__c,
                   Hotel_Name__c, Relationship_to__c,
                   X1_of_invited_guest__c,
                   Inbound_Date_Time__c, Outbound_Date_Time__c
            FROM Guest_List__c
            WHERE Swoogo_Registrant_Id__c IN :rawByRegId.keySet()
              AND Invitation__c = :invitationId
        ]) {
            Map<String,Object> raw = rawByRegId.get(g.Swoogo_Registrant_Id__c);
            if (raw == null) continue;

            // Snapshot before
            String beforeHotel    = g.Hotel_Name__c;
            String beforeRelation = g.Relationship_to__c;
            String beforePlus1    = g.X1_of_invited_guest__c;
            Datetime beforeInbound  = g.Inbound_Date_Time__c;
            Datetime beforeOutbound = g.Outbound_Date_Time__c;

            // Apply custom field values from question map
            questionMap.applyToGuestList(g, raw);

            // Only add to update list if something changed
            if (g.Hotel_Name__c         != beforeHotel
                || g.Relationship_to__c != beforeRelation
                || g.X1_of_invited_guest__c != beforePlus1
                || g.Inbound_Date_Time__c   != beforeInbound
                || g.Outbound_Date_Time__c  != beforeOutbound) {
                customFieldUpdates.add(g);
            }
        }

        if (!customFieldUpdates.isEmpty()) {
            Database.update(customFieldUpdates, false);
            System.debug('RegistrantSync custom fields updated='
                + customFieldUpdates.size());
        }
    }

    // ── Contact resolution helper ─────────────────────────────

    private static Contact resolveContact(
        SwoogoApiClient.SwoogoRegistrant r,
        Map<String, Contact> byExtId,
        Map<String, Contact> byEmail)
    {
        String extKey   = String.isNotBlank(r.contact_id) ? r.contact_id : null;
        String emailKey = String.isNotBlank(r.email) ? r.email.toLowerCase() : null;
        if (extKey   != null && byExtId.containsKey(extKey))   return byExtId.get(extKey);
        if (emailKey != null && byEmail.containsKey(emailKey)) return byEmail.get(emailKey);
        System.debug('RegistrantSync: no contact found ext='
            + r.contact_id + ' email=' + r.email);
        return null;
    }
}