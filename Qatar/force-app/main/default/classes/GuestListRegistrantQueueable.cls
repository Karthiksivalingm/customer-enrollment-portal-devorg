public with sharing class GuestListRegistrantQueueable
implements Queueable, Database.AllowsCallouts {

    private Set<Id> guestIds;

    public GuestListRegistrantQueueable(Set<Id> guestIds) {
        this.guestIds = guestIds;
    }

    public void execute(QueueableContext context) {
        List<Guest_List__c> guests = [
            SELECT Id,
                   Approval__c,
                   Company__c,
                   Title__c,
                   Swoogo_Registrant_Id__c,
                   Swoogo_Push_Status__c,
                   Contact__c,
                   Contact__r.FirstName,
                   Contact__r.LastName,
                   Contact__r.Email,
                   Contact__r.MobilePhone,
                   Contact__r.contact_external_id__c,
                   Invitation__c,
                   Invitation__r.External_Event_Id__c,
                   Guest_Tiers__c,
                   Main_Guest__c,
                   Main_Guest__r.Swoogo_Registrant_Id__c
            FROM Guest_List__c
            WHERE Id IN :guestIds
        ];

        List<Guest_List__c> updates          = new List<Guest_List__c>();
        List<Contact>       contactsToUpdate = new List<Contact>();

        // Guests that hit a 429 from Swoogo this run — these are NOT
        // permanent failures. The Approval__c → Approved trigger fires
        // this queueable immediately, and if that happens to land while
        // SwoogoSessionSyncBatch (the 15-min background sync) is also
        // mid-run and consuming Swoogo's rate-limit window, this queueable's
        // callouts can get 429'd. Previously these were written to
        // Swoogo_Push_Status__c as a generic 'Failed' and never retried,
        // so the guest silently never made it into Swoogo. Instead, collect
        // them here and reschedule a follow-up run once the rate-limit
        // window resets.
        Set<Id> retryGuestIds = new Set<Id>();

        // Cache invitation lists per event so a batch of guests for the
        // same event only triggers one Swoogo callout for the list lookup.
        Map<String, List<SwoogoApiClient.SwoogoInvitationList>> invitationListsByEvent =
            new Map<String, List<SwoogoApiClient.SwoogoInvitationList>>();

        for (Guest_List__c guest : guests) {
            try {
                if (guest.Approval__c != 'Approved') {
                    continue;
                }

                // Skip if this guest was already successfully processed
                // (idempotency guard). Covers both the invitation-list path
                // and the direct-registration path added for child guests.
                if (guest.Swoogo_Push_Status__c != null
                        && (guest.Swoogo_Push_Status__c.startsWith('Success - Added to invitation list')
                            || guest.Swoogo_Push_Status__c.startsWith('Success - Registered and added to group'))) {
                    continue;
                }

                // Event ID comes from the Invitation lookup
                String rawEventId = guest.Invitation__r.External_Event_Id__c;
                if (String.isBlank(rawEventId)) {
                    guest.Swoogo_Push_Status__c = 'Failed - No event ID found';
                    updates.add(guest);
                    continue;
                }

                if (guest.Contact__c == null || String.isBlank(guest.Contact__r.Email)) {
                    guest.Swoogo_Push_Status__c = 'Failed - No contact/email found';
                    updates.add(guest);
                    continue;
                }

                if (String.isBlank(guest.Guest_Tiers__c)) {
                    guest.Swoogo_Push_Status__c = 'Failed - No Guest Tier set';
                    updates.add(guest);
                    continue;
                }

                // ── Step 1: Resolve Swoogo contact_id ──────────────────
                // Use the SF Contact's stored external id if present;
                // otherwise look the contact up in Swoogo by email; if
                // still not found, create a new Swoogo contact.
                String contactIdStr = guest.Contact__r.contact_external_id__c;
                Long   swoContactId = String.isNotBlank(contactIdStr)
                    ? Long.valueOf(contactIdStr) : null;
                Boolean resolvedFromSF = (swoContactId != null);

                if (swoContactId == null) {
                    swoContactId = SwoogoApiClient.findContactIdByEmail(guest.Contact__r.Email);
                    if (swoContactId != null) {
                        // Found an existing Swoogo contact rather than creating
                        // one fresh — createContact() (which stamps c_8598114
                        // automatically) never runs in this branch, so this
                        // stamps it explicitly here instead. Non-blocking: a
                        // failure here shouldn't stop the guest from still
                        // being added to the invitation list below.
                        try {
                            SwoogoApiClient.updateContactExternalId(swoContactId, guest.Contact__c);
                        } catch (Exception ex) {
                            System.debug('Failed to backfill c_8598114 on found contact '
                                + swoContactId + ' for guest=' + guest.Id + ': ' + ex.getMessage());
                        }
                    }
                }

                if (swoContactId == null) {
                    swoContactId = SwoogoApiClient.createContact(
                        guest.Contact__r.Email,
                        guest.Contact__r.FirstName,
                        guest.Contact__r.LastName,
                        guest.Contact__c);
                }

                if (swoContactId == null) {
                    guest.Swoogo_Push_Status__c = 'Failed - Could not resolve/create Swoogo contact';
                    updates.add(guest);
                    continue;
                }

                // Backfill SF Contact external id if it wasn't already set
                if (!resolvedFromSF && guest.Contact__c != null) {
                    contactsToUpdate.add(new Contact(
                        Id                     = guest.Contact__c,
                        contact_external_id__c = String.valueOf(swoContactId)
                    ));
                }

                // ── NEW: Child guest branch ─────────────────────────────
                // If Main_Guest__c is populated, this guest belongs to
                // another guest's registration (a child/+1). Instead of
                // being added to an invitation list, they get registered
                // directly, then added to the main guest's group — using
                // the main guest's own Swoogo_Registrant_Id__c as the
                // group id.
                if (guest.Main_Guest__c != null) {
                    String mainGuestRegIdStr = guest.Main_Guest__r != null
                        ? guest.Main_Guest__r.Swoogo_Registrant_Id__c : null;

                    if (String.isBlank(mainGuestRegIdStr)) {
                        guest.Swoogo_Push_Status__c =
                            'Failed - Main guest has no Swoogo_Registrant_Id__c yet (not registered in Swoogo)';
                        updates.add(guest);
                        continue;
                    }

                    try {
                        Long swoEventId = Long.valueOf(rawEventId);
                        Long groupId    = Long.valueOf(mainGuestRegIdStr);

                        Long registrantId = SwoogoApiClient.createRegistrant(
                            swoEventId,
                            null, // sessionId — not applicable here
                            guest.Contact__r.FirstName,
                            guest.Contact__r.LastName,
                            guest.Contact__r.Email,
                            guest.Company__c,
                            guest.Title__c,
                            guest.Contact__r.MobilePhone,
                            guest.Contact__c,
                            guest.Guest_Tiers__c
                        );

                        SwoogoApiClient.addRegistrantToGroup(registrantId, groupId);

                        guest.Swoogo_Registrant_Id__c = String.valueOf(registrantId);
                        guest.Swoogo_Push_Status__c = 'Success - Registered and added to group '
                            + groupId;
                    } catch (Exception ex) {
                        if (isRateLimitError(ex)) {
                            retryGuestIds.add(guest.Id);
                            guest.Swoogo_Push_Status__c =
                                'Retry Pending - Swoogo rate limited (429), will automatically retry '
                                + 'in couple of mins — don\'t worry, this will automatically sync '
                                + 'with the particular invitation tier';
                            System.debug('Swoogo 429 on child guest registration guest=' + guest.Id
                                + ' — queued for retry');
                        } else {
                            guest.Swoogo_Push_Status__c =
                                'Failed - direct registration/group error: ' + ex.getMessage().left(160);
                            System.debug('Swoogo Direct Registration/Group Error guest=' + guest.Id
                                + ': ' + ex.getMessage());
                        }
                    }
                    updates.add(guest);
                    continue;
                }

                // ── Step 2: Match Guest_Tiers__c to an invitation list ──
                List<SwoogoApiClient.SwoogoInvitationList> lists =
                    invitationListsByEvent.get(rawEventId);
                if (lists == null) {
                    lists = SwoogoApiClient.getInvitationListsForEvent(rawEventId);
                    invitationListsByEvent.put(rawEventId, lists);
                }

                String tierName       = guest.Guest_Tiers__c.trim();
                Long   matchedListId   = null;
                String matchedListName = null;
                for (SwoogoApiClient.SwoogoInvitationList il : lists) {
                    if (il.name != null && il.name.trim().equalsIgnoreCase(tierName)) {
                        matchedListId   = il.id;
                        matchedListName = il.name;
                        break;
                    }
                }

                if (matchedListId == null) {
                    guest.Swoogo_Push_Status__c = 'Failed - WARNING: no invitation list '
                        + 'matches Guest Tier "' + tierName + '" for event ' + rawEventId;
                    System.debug('No invitation list match for tier="' + tierName
                        + '" event=' + rawEventId + ' guest=' + guest.Id);
                    updates.add(guest);
                    continue;
                }

                // ── Step 3: Add the contact to the matched invitation list ──
                SwoogoApiClient.addContactToInvitationList(matchedListId, swoContactId);
                guest.Swoogo_Push_Status__c = 'Success - Added to invitation list "'
                    + matchedListName + '"';

            } catch (Exception ex) {
                if (isRateLimitError(ex)) {
                    // Rate limited by Swoogo — most likely the 15-min
                    // background sync (SwoogoSyncBatch/SwoogoSessionSyncBatch)
                    // was mid-run and consuming the callout window. This is
                    // not a real failure, so don't burn the guest's
                    // Swoogo_Push_Status__c on a permanent 'Failed'. Queue
                    // it for a retry once the rate-limit window resets.
                    retryGuestIds.add(guest.Id);
                    guest.Swoogo_Push_Status__c =
                        'Retry Pending - Swoogo rate limited (429), will automatically retry '
                        + 'in couple of mins — don\'t worry, this will automatically sync '
                        + 'with the particular invitation tier';
                    System.debug('Swoogo 429 for guest=' + guest.Id + ' — queued for retry');
                } else {
                    guest.Swoogo_Push_Status__c =
                        'Failed - ' + ex.getMessage().left(200);
                    System.debug('Swoogo Invitation List Error guest=' + guest.Id
                        + ': ' + ex.getMessage());
                }
            }

            updates.add(guest);
        }

        if (!updates.isEmpty())          update updates;
        if (!contactsToUpdate.isEmpty()) Database.update(contactsToUpdate, false);

        // ── Reschedule rate-limited guests ─────────────────────────────
        // Wait for Swoogo's own reported reset window (captured by
        // SwoogoApiClient off the 429 response headers) when available,
        // otherwise fall back to a fixed short delay.
        if (!retryGuestIds.isEmpty() && !System.isFuture() && !System.isBatch()) {
            Integer delaySeconds = SwoogoApiClient.lastRateLimitResetSeconds != null
                ? SwoogoApiClient.lastRateLimitResetSeconds : 120;
            // Small buffer on top of Swoogo's own reset time so we don't
            // fire right at the edge of the window and get 429'd again.
            Integer delayMinutes = Math.max(1, (Integer) Math.ceil((delaySeconds + 15) / 60.0));

            Datetime runAt = Datetime.now().addMinutes(delayMinutes);
            String cronExp = runAt.second() + ' ' + runAt.minute() + ' '
                + runAt.hour() + ' ' + runAt.day() + ' ' + runAt.month()
                + ' ? ' + runAt.year();
            try {
                System.schedule(
                    'GuestListRetry-' + Datetime.now().getTime(),
                    cronExp,
                    new GuestListRegistrantRetryScheduler(retryGuestIds));
                System.debug('Rescheduled ' + retryGuestIds.size()
                    + ' rate-limited guest(s) for retry in ' + delayMinutes + ' min at ' + runAt);
            } catch (Exception schedEx) {
                System.debug('Failed to schedule GuestListRegistrantQueueable retry: '
                    + schedEx.getMessage());
            }
        }
    }

    // Detects a Swoogo 429 (Too Many Requests) response. SwoogoApiClient
    // wraps these as a SwoogoException whose message contains '[429]'.
    private static Boolean isRateLimitError(Exception ex) {
        return ex.getMessage() != null && ex.getMessage().contains('[429]');
    }
}