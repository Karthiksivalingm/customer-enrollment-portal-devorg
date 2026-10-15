trigger AppointmentRequestedSubscriber on Appointment_Requested__e (after insert) {

    // Collect Contact IDs and Carrier IDs
    Set<Id> contactIds = new Set<Id>();
    Set<Id> carrierIds = new Set<Id>();

    for (Appointment_Requested__e event : Trigger.new) {
        if (event.Contact_ID__c != null) {
            contactIds.add((Id)event.Contact_ID__c);
        }
        if (event.Carrier_ID__c != null) {
            carrierIds.add((Id)event.Carrier_ID__c);
        }
    }

    // Query Contacts
    Map<Id, Contact> contactMap = new Map<Id, Contact>(
        [
            SELECT Id, AccountId, Desired_Carriers__c
            FROM Contact
            WHERE Id IN :contactIds
        ]
    );

    // Query Carriers
    Map<Id, Carrier__c> carrierMap = new Map<Id, Carrier__c>(
        [
            SELECT Id, Name
            FROM Carrier__c
            WHERE Id IN :carrierIds
        ]
    );

    List<Appointment__c> appointmentsToCreate = new List<Appointment__c>();

    // Stores JSON data for each Contact
    Map<Id, List<Map<String, Object>>> contactCarrierMap = new Map<Id, List<Map<String, Object>>>();

    // Prevent duplicate Appointment creation in same transaction
    Set<String> processed = new Set<String>();

    for (Appointment_Requested__e event : Trigger.new) {

        if (event.Contact_ID__c == null || event.Carrier_ID__c == null) {
            continue;
        }

        Id contactId = (Id)event.Contact_ID__c;
        Id carrierId = (Id)event.Carrier_ID__c;

        Contact con = contactMap.get(contactId);
        Carrier__c carrier = carrierMap.get(carrierId);

        if (con == null || carrier == null) {
            continue;
        }

        // -------------------------------
        // Requirement 1
        // Build Desired_Carriers__c JSON
        // -------------------------------
        if (!contactCarrierMap.containsKey(contactId)) {
            contactCarrierMap.put(contactId, new List<Map<String, Object>>());
        }

        List<Map<String, Object>> carriers = contactCarrierMap.get(contactId);

        Boolean exists = false;
        for (Map<String, Object> c : carriers) {
            if ((String)c.get('carrierId') == String.valueOf(carrierId)) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            carriers.add(new Map<String, Object>{
                'carrierId' => carrier.Id,
                'carrierName' => carrier.Name
            });
        }

        // -------------------------------
        // Requirement 2
        // Create Appointment
        // -------------------------------
        String key = contactId + '_' + carrierId;

        if (processed.contains(key)) {
            continue;
        }

        processed.add(key);

        appointmentsToCreate.add(new Appointment__c(
            Agent__c            = contactId,
            Agency__c           = con.AccountId,
            Carrier__c          = carrierId,
            Line_of_Business__c = event.LOB__c,
            State_s__c          = event.States__c,
            Status__c           = 'Requested',
            Requested_Date__c   = Date.today()
        ));
    }

    // Update Desired_Carriers__c
    List<Contact> contactsToUpdate = new List<Contact>();

    for (Id contactId : contactCarrierMap.keySet()) {
        Contact c = contactMap.get(contactId);

        c.Desired_Carriers__c =
            JSON.serialize(contactCarrierMap.get(contactId));

        contactsToUpdate.add(c);
    }

    if (!contactsToUpdate.isEmpty()) {
        update contactsToUpdate;
    }

    if (!appointmentsToCreate.isEmpty()) {
        insert appointmentsToCreate;
    }
}