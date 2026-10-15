/*
//  backup code
trigger GuestListTrigger on Guest_List__c (after update) {

  Set<Id> approvedIds = new Set<Id>();
    Set<Id> mainGuestsJustAccepted = new Set<Id>();
    Set<Id> parentGuestIds = new Set<Id>();

    List<Guest_List__c> pendingGuests = new List<Guest_List__c>();

    // Collect parent IDs for newly approved child guests
    for (Guest_List__c guest : Trigger.new) {
        Guest_List__c oldGuest = Trigger.oldMap.get(guest.Id);

        if (guest.Approval__c == 'Approved'
            && oldGuest.Approval__c != 'Approved'
            && guest.Main_Guest__c != null) {

            parentGuestIds.add(guest.Main_Guest__c);
        }
    }

    // Query parent guests
    Map<Id, Guest_List__c> parentGuestMap = new Map<Id, Guest_List__c>();

    if (!parentGuestIds.isEmpty()) {
        parentGuestMap = new Map<Id, Guest_List__c>([
            SELECT Id, Invitation_Status__c
            FROM Guest_List__c
            WHERE Id IN :parentGuestIds
        ]);
    }

    // Process updated records
    for (Guest_List__c guest : Trigger.new) {

        Guest_List__c oldGuest = Trigger.oldMap.get(guest.Id);

        // Approval changed to Approved
        if (guest.Approval__c == 'Approved'
            && oldGuest.Approval__c != 'Approved') {

            // Main Guest
            if (guest.Main_Guest__c == null) {

                approvedIds.add(guest.Id);

            } else {

                // Child Guest
                Guest_List__c parent = parentGuestMap.get(guest.Main_Guest__c);

                if (parent != null &&
                    parent.Invitation_Status__c == 'Accepted') {

                    approvedIds.add(guest.Id);

                } else {

                    pendingGuests.add(new Guest_List__c(
                        Id = guest.Id,
                        Swoogo_Push_Status__c = 'Pending - waiting for main guest invitation acceptance'
                    ));
                }
            }
        }

        // Main Guest invitation accepted
        if (guest.Invitation_Status__c == 'Accepted'
            && oldGuest.Invitation_Status__c != 'Accepted') {

            mainGuestsJustAccepted.add(guest.Id);
        }
    }

    Set<Id> idsToProcess = new Set<Id>();
    idsToProcess.addAll(approvedIds);

    // When main guest accepts, process waiting child guests
    if (!mainGuestsJustAccepted.isEmpty()) {

        for (Guest_List__c child : [
            SELECT Id, Swoogo_Push_Status__c
            FROM Guest_List__c
            WHERE Main_Guest__c IN :mainGuestsJustAccepted
            AND Approval__c = 'Approved'
        ]) {

            if (child.Swoogo_Push_Status__c == null
                || !child.Swoogo_Push_Status__c.startsWith('Success')) {

                idsToProcess.add(child.Id);
            }
        }
    }

    // Update pending status for child guests
    if (!pendingGuests.isEmpty()) {
        update pendingGuests;
    }

    // Push to Swoogo
    if (!idsToProcess.isEmpty()) {
        System.enqueueJob(new GuestListRegistrantQueueable(idsToProcess));
    } 
}*/


trigger GuestListTrigger on Guest_List__c (after update) {

    // Kill switch: skip everything unless enabled in Swoogo Settings
    Swoogo_Settings__c settings = Swoogo_Settings__c.getInstance();
    if (settings == null || settings.Enable_Guest_List_Trigger__c != true) {
        return;
    }

    Set<Id> approvedIds = new Set<Id>();
    Set<Id> mainGuestsJustAccepted = new Set<Id>();
    Set<Id> parentGuestIds = new Set<Id>();

    List<Guest_List__c> pendingGuests = new List<Guest_List__c>();

    // Collect parent IDs for newly approved child guests
    for (Guest_List__c guest : Trigger.new) {
        Guest_List__c oldGuest = Trigger.oldMap.get(guest.Id);

        if (guest.Approval__c == 'Approved'
            && oldGuest.Approval__c != 'Approved'
            && guest.Main_Guest__c != null) {

            parentGuestIds.add(guest.Main_Guest__c);
        }
    }

    // Query parent guests
    Map<Id, Guest_List__c> parentGuestMap = new Map<Id, Guest_List__c>();

    if (!parentGuestIds.isEmpty()) {
        parentGuestMap = new Map<Id, Guest_List__c>([
            SELECT Id, Invitation_Status__c
            FROM Guest_List__c
            WHERE Id IN :parentGuestIds
        ]);
    }

    // Process updated records
    for (Guest_List__c guest : Trigger.new) {

        Guest_List__c oldGuest = Trigger.oldMap.get(guest.Id);

        // Approval changed to Approved
        if (guest.Approval__c == 'Approved'
            && oldGuest.Approval__c != 'Approved') {

            // Main Guest (skip if imported from Swoogo)
            if (guest.Main_Guest__c == null) {

                if (guest.Import_from_Swoogo__c == false) {
                    approvedIds.add(guest.Id);
                }

            } else {

                // Child Guest
                Guest_List__c parent = parentGuestMap.get(guest.Main_Guest__c);

                if (parent != null &&
                    parent.Invitation_Status__c == 'Accepted') {

                    approvedIds.add(guest.Id);

                } else {

                    pendingGuests.add(new Guest_List__c(
                        Id = guest.Id,
                        Swoogo_Push_Status__c = 'Pending - waiting for main guest invitation acceptance'
                    ));
                }
            }
        }

        // Main Guest invitation accepted
        if (guest.Invitation_Status__c == 'Accepted'
            && oldGuest.Invitation_Status__c != 'Accepted') {

            mainGuestsJustAccepted.add(guest.Id);
        }
    }

    Set<Id> idsToProcess = new Set<Id>();
    idsToProcess.addAll(approvedIds);

    // When main guest accepts, process waiting child guests
    if (!mainGuestsJustAccepted.isEmpty()) {

        for (Guest_List__c child : [
            SELECT Id, Swoogo_Push_Status__c
            FROM Guest_List__c
            WHERE Main_Guest__c IN :mainGuestsJustAccepted
            AND Approval__c = 'Approved'
        ]) {

            if (child.Swoogo_Push_Status__c == null
                || !child.Swoogo_Push_Status__c.startsWith('Success')) {

                idsToProcess.add(child.Id);
            }
        }
    }

    // Update pending status for child guests
    if (!pendingGuests.isEmpty()) {
        update pendingGuests;
    }

    // Push to Swoogo
    if (!idsToProcess.isEmpty()) {
        System.enqueueJob(new GuestListRegistrantQueueable(idsToProcess));
    }
}