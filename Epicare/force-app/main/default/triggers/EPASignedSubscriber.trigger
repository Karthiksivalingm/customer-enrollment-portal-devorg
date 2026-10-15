trigger EPASignedSubscriber on EPA_Signed__e (after insert) {
    Map<Id, EPA_Signed__e> contactEventMap = new Map<Id, EPA_Signed__e>();
    
    for (EPA_Signed__e event : Trigger.new) {
        if (event.Contact_ID__c != null) {
            // Idempotency — last event per contact wins
            contactEventMap.put((Id)event.Contact_ID__c, event);
        }
    }
    
    List<Contact> contactsToUpdate = new List<Contact>();
    
    for (Id contactId : contactEventMap.keySet()) {
        EPA_Signed__e event = contactEventMap.get(contactId);
        contactsToUpdate.add(new Contact(
            Id                    = contactId,
            EPA_Signed_Date__c    = event.Signed_Date__c,
            EPA_Document_URL__c   = event.Document_URL__c
        ));
    }
    
    if (!contactsToUpdate.isEmpty()) {
        try {
            update contactsToUpdate;
        } catch (Exception e) {
            System.debug('EPASigned update error: ' + e.getMessage());
        }
    }
}