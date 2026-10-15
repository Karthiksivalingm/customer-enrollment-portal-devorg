public class EventAttendeeHandler {

    public static void processAttendees(List<Event> events) {

        // ── Step 1: Collect event IDs ──────────────────────────
        Set<Id> eventIds = new Set<Id>();
        for(Event evt : events) {
            if(evt.Id != null) eventIds.add(evt.Id);
        }
        if(eventIds.isEmpty()) return;

        // ── Step 2: Query ALL existing EventRelation records ───
        Map<String, List<EventRelation>> relationsByKey =
            new Map<String, List<EventRelation>>();

        for(EventRelation er : [
            SELECT Id, EventId, RelationId, IsInvitee
            FROM EventRelation
            WHERE EventId IN :eventIds
            AND RelationId != null
        ]) {
            String key = er.EventId + '_' + er.RelationId;
            if(!relationsByKey.containsKey(key)) {
                relationsByKey.put(
                    key, new List<EventRelation>()
                );
            }
            relationsByKey.get(key).add(er);
        }

        // ── Step 3: Deduplicate EventRelation records ──────────
        List<EventRelation> toDelete = new List<EventRelation>();
        List<EventRelation> toUpdate = new List<EventRelation>();
        Map<String, EventRelation> cleanRelationByKey =
            new Map<String, EventRelation>();

        for(String key : relationsByKey.keySet()) {
            List<EventRelation> erGroup = relationsByKey.get(key);

            if(erGroup.size() == 1) {
                EventRelation er = erGroup[0];
                if(er.IsInvitee == false) {
                    toUpdate.add(new EventRelation(
                        Id        = er.Id,
                        IsInvitee = true
                    ));
                    er.IsInvitee = true;
                }
                cleanRelationByKey.put(key, er);

            } else {
                EventRelation keepRecord = null;
                for(EventRelation er : erGroup) {
                    if(er.IsInvitee == true
                       && keepRecord == null) {
                        keepRecord = er;
                    }
                }
                if(keepRecord == null) {
                    keepRecord = erGroup[0];
                    toUpdate.add(new EventRelation(
                        Id        = keepRecord.Id,
                        IsInvitee = true
                    ));
                    keepRecord.IsInvitee = true;
                }
                for(EventRelation er : erGroup) {
                    if(er.Id != keepRecord.Id) {
                        toDelete.add(er);
                    }
                }
                cleanRelationByKey.put(key, keepRecord);
            }
        }

        // ── Step 4: Extract emails from descriptions ───────────
        // CRITICAL: Strip SafeLinks URLs BEFORE extracting emails
        // SafeLinks wraps URLs in angle brackets and contains
        // encoded emails (%40 = @) that corrupt our extraction
        Set<String> allDescriptionEmails = new Set<String>();
        for(Event evt : events) {
            if(String.isNotBlank(evt.Description)) {
                String cleanDesc = stripUrlsFromText(
                    evt.Description
                );
                allDescriptionEmails.addAll(
                    extractEmails(cleanDesc)
                );
            }
        }

        // ── Step 5: Query contacts matching description emails ─
        Map<String, Id> emailToContactId = new Map<String, Id>();
        if(!allDescriptionEmails.isEmpty()) {
            for(Contact c : [
                SELECT Id, Email
                FROM Contact
                WHERE Email IN :allDescriptionEmails
                AND Email != null
            ]) {
                emailToContactId.put(
                    c.Email.toLowerCase().trim(), c.Id
                );
            }
        }

        // ── Step 6: Query ALL contact emails in Salesforce ────
        // Used to decide: is an email external or a known contact?
        Set<String> allSalesforceContactEmails =
            new Set<String>();
        for(Contact c : [
            SELECT Email
            FROM Contact
            WHERE Email != null
        ]) {
            allSalesforceContactEmails.add(
                c.Email.toLowerCase().trim()
            );
        }

        // ── Step 7: Process each event ────────────────────────
        List<EventRelation> toInsert = new List<EventRelation>();
        List<Event> eventsToUpdate   = new List<Event>();

        Set<String> usedKeys = new Set<String>();
        usedKeys.addAll(cleanRelationByKey.keySet());

        for(Event evt : events) {

            if(String.isBlank(evt.Description)) {
                eventsToUpdate.add(new Event(
                    Id                    = evt.Id,
                    External_Attendees__c = null
                ));
                continue;
            }

            // CRITICAL: Strip URLs before extracting emails
            // so SafeLinks encoded emails don't contaminate
            // our attendee list
            String cleanDescription = stripUrlsFromText(
                evt.Description
            );

            List<String> extractedEmails =
                extractEmails(cleanDescription);

            if(extractedEmails.isEmpty()) {
                eventsToUpdate.add(new Event(
                    Id                    = evt.Id,
                    External_Attendees__c = null
                ));
                continue;
            }

            // Build excluded: organizer + optional
            Set<String> excludedEmails = new Set<String>();

            String organizerName =
                extractOrganizerName(evt.Description);
            if(organizerName != null) {
                String orgEmail = findOrganizerEmail(
                    organizerName, extractedEmails
                );
                if(orgEmail != null) {
                    excludedEmails.add(
                        orgEmail.toLowerCase().trim()
                    );
                }
            }
            excludedEmails.addAll(
                extractOptionalEmails(cleanDescription)
            );

            List<String> externalEmails = new List<String>();

            for(String email : extractedEmails) {
                String normalized = email.toLowerCase().trim();

                // 1. Skip organizer and optional
                if(excludedEmails.contains(normalized)) continue;

                // 2. Skip internal org domain
                if(normalized.endsWith('@qm.org.qa')) continue;

                // 3. Matches a Contact → EventRelation invitee
                if(emailToContactId.containsKey(normalized)) {
                    Id contactId =
                        emailToContactId.get(normalized);
                    String relKey = evt.Id + '_' + contactId;
                    if(!usedKeys.contains(relKey)) {
                        toInsert.add(new EventRelation(
                            EventId    = evt.Id,
                            RelationId = contactId,
                            IsInvitee  = true
                        ));
                        usedKeys.add(relKey);
                    }
                    continue;
                }

                // 4. Email belongs to a contact in Salesforce
                //    but wasn't in description match → skip
                if(allSalesforceContactEmails.contains(
                    normalized)) continue;

                // 5. Truly external email
                if(!externalEmails.contains(normalized)) {
                    externalEmails.add(normalized);
                }
            }

            String newExternal = externalEmails.isEmpty()
                ? null
                : String.join(externalEmails, '; ');

            eventsToUpdate.add(new Event(
                Id                    = evt.Id,
                External_Attendees__c = newExternal
            ));
        }

        // ── Step 8: DML ───────────────────────────────────────

        // 8a: DELETE duplicate EventRelation records
        if(!toDelete.isEmpty()) {
            try {
                delete toDelete;
            } catch(DmlException e) {
                System.debug('ER delete error: '
                    + e.getMessage());
            }
        }

        // 8b: UPDATE IsInvitee=false → true
        if(!toUpdate.isEmpty()) {
            List<Database.SaveResult> ur =
                Database.update(toUpdate, false);
            for(Integer i = 0; i < ur.size(); i++) {
                if(!ur.get(i).isSuccess()) {
                    System.debug('ER update error: '
                        + ur.get(i).getErrors());
                }
            }
        }

        // 8c: INSERT new EventRelations from description
        if(!toInsert.isEmpty()) {
            List<Database.SaveResult> ir =
                Database.insert(toInsert, false);
            for(Integer i = 0; i < ir.size(); i++) {
                if(!ir.get(i).isSuccess()) {
                    System.debug('ER insert error: '
                        + ir.get(i).getErrors());
                }
            }
        }

        // 8d: UPDATE External_Attendees__c
        // FIXED: Reset isRunning flag before this update
        // so the guard doesn't block it
        if(!eventsToUpdate.isEmpty()) {
            EventTriggerHelper.isRunning = true;
            try {
                update eventsToUpdate;
            } catch(DmlException e) {
                System.debug('Event update error: '
                    + e.getMessage());
            } finally {
                EventTriggerHelper.isRunning = false;
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    // CRITICAL: Strip all URLs from text before email extraction
    // Handles:
    //   - SafeLinks: <https://eur04.safelinks...>
    //   - Plain URLs: https://... or http://...
    //   - Angle-bracket wrapped URLs: <https://...>
    // This prevents encoded emails in URLs (%40 = @) from
    // being decoded and extracted as false attendee emails
    // ─────────────────────────────────────────────────────────
    private static String stripUrlsFromText(String text) {
        if(text == null) return '';

        // Step 1: Remove angle-bracket wrapped URLs
        // Pattern: <http...> or <https...>
        text = text.replaceAll('<https?://[^>]*>', ' ');

        // Step 2: Remove remaining plain URLs
        // Pattern: http:// or https:// followed by non-space chars
        text = text.replaceAll(
            'https?://[^\\s<>\"\']+', ' '
        );

        // Step 3: Remove any leftover URL-encoded sequences
        // that might contain %40 (encoded @)
        text = text.replaceAll('%[0-9A-Fa-f]{2}', ' ');

        return text;
    }

    // ─────────────────────────────────────────────────────────
    // Extract organizer name from "invited by <Name>"
    // ─────────────────────────────────────────────────────────
    private static String extractOrganizerName(String text) {
        if(text == null) return null;
        Pattern p = Pattern.compile(
            '(?i)invited by\\s+([A-Za-z]+(?:\\s+[A-Za-z]+)*)'
        );
        Matcher m = p.matcher(text);
        if(m.find()) return m.group(1).trim();
        return null;
    }

    // ─────────────────────────────────────────────────────────
    // Match organizer name to email
    // ─────────────────────────────────────────────────────────
    private static String findOrganizerEmail(
        String organizerName,
        List<String> emails
    ) {
        if(organizerName == null || emails == null) return null;
        String[] parts   =
            organizerName.toLowerCase().split('\\s+');
        String firstName = parts[0];
        String lastName  =
            parts.size() > 1 ? parts[parts.size()-1] : '';

        for(String email : emails) {
            String uname = email.toLowerCase().split('@')[0];
            if(uname.startsWith(firstName)
               || uname.contains(firstName + '.')
               || uname.contains('.' + firstName)
               || (lastName != '' &&
                   uname.startsWith(lastName))
               || (lastName != '' && uname.contains(
                       firstName.substring(0,1) + lastName))
               || (lastName != '' && uname.contains(
                       firstName + lastName.substring(0,1)))
            ) {
                return email;
            }
        }
        return null;
    }

    // ─────────────────────────────────────────────────────────
    // Extract optional attendee emails
    // ─────────────────────────────────────────────────────────
    private static Set<String> extractOptionalEmails(
        String text
    ) {
        Set<String> emails = new Set<String>();
        if(text == null) return emails;
        String[] lines     = text.split('\n');
        Boolean inOptional = false;

        for(String line : lines) {
            String l = line.toLowerCase().trim();
            if(l.startsWith('optional:')
               || l.contains('(optional)')
               || l.contains('optional attendee')) {
                inOptional = true;
            } else if(l.startsWith('attendees:')
                      || l.startsWith('attendee:')
                      || l.startsWith('guest:')
                      || l.startsWith('guests:')) {
                inOptional = false;
            }
            if(inOptional) emails.addAll(extractEmails(line));
        }
        return emails;
    }

    // ─────────────────────────────────────────────────────────
    // Extract all emails from text
    // ─────────────────────────────────────────────────────────
    private static List<String> extractEmails(String text) {
        List<String> emails = new List<String>();
        if(text == null) return emails;
        Pattern p = Pattern.compile(
            '[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}'
        );
        Matcher m = p.matcher(text);
        while(m.find()) {
            String email = m.group().toLowerCase().trim();
            if(!emails.contains(email)) emails.add(email);
        }
        return emails;
    }
}