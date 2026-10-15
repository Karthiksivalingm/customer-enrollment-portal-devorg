trigger OnboardingStepSubscriber on Onboarding_Step__e (after insert) {

    // Last event per Contact (idempotency)
    Map<Id, Onboarding_Step__e> contactEventMap = new Map<Id, Onboarding_Step__e>();

    // Valid onboarding steps received from GO AMS
    Set<String> validSteps = new Set<String>{
        'Email Validated',
        'Password Created',
        'EPA Pending',
        'Checklist Pending'
    };

    for (Onboarding_Step__e event : Trigger.new) {
        if (event.Contact_ID__c != null &&
            validSteps.contains(event.New_Step__c)) {

            contactEventMap.put((Id)event.Contact_ID__c, event);
        }
    }

    if (contactEventMap.isEmpty()) {
        return;
    }

    // Query existing contacts to preserve Onboarding_Started__c
    Map<Id, Contact> existingContacts = new Map<Id, Contact>([
        SELECT Id,
               Onboarding_Started__c,
               Onboarding_Step__c
        FROM Contact
        WHERE Id IN :contactEventMap.keySet()
    ]);

    List<Contact> contactsToUpdate = new List<Contact>();

    for (Id contactId : contactEventMap.keySet()) {

        Contact existing = existingContacts.get(contactId);
        Onboarding_Step__e event = contactEventMap.get(contactId);

        Contact c = new Contact(
            Id = contactId,
            Onboarding_Step__c = event.New_Step__c
        );

        // Set onboarding started only once
        if (event.New_Step__c == 'Email Validated'
            && existing.Onboarding_Started__c == null) {

            c.Onboarding_Started__c = Date.today();
        }

        contactsToUpdate.add(c);
    }

    if (!contactsToUpdate.isEmpty()) {

        Database.SaveResult[] results = Database.update(contactsToUpdate, false);

        for (Integer i = 0; i < results.size(); i++) {

            if (!results[i].isSuccess()) {

                for (Database.Error err : results[i].getErrors()) {

                    System.debug(
                        'Failed to update Contact ' +
                        contactsToUpdate[i].Id +
                        ' : ' +
                        err.getMessage()
                    );
                }
            }
        }
    }
}