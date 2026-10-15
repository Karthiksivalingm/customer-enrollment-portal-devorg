/**
 * DocumentStatusUpdateEventTrigger
 *
 * ============================================================================
 * WHY THIS EXISTS
 * ============================================================================
 * The portal users in this org have a High-Volume Customer Portal license
 * (UserInfo.getUserType() == 'CspLitePortal'). That license type is
 * platform-restricted from directly performing DML (insert/update/delete)
 * on core standard objects - Contact included - no matter what the Apex
 * code does (without sharing, system-mode DML, permission sets - none of
 * it matters, confirmed by hitting "DML operation UPDATE not allowed on
 * Contact" even after removing every other security layer).
 *
 * The one thing a High-Volume Portal user CAN do is PUBLISH A PLATFORM
 * EVENT (it isn't a standard-object DML, so the restriction doesn't apply
 * to it). A trigger subscribed to that event runs as Salesforce's
 * internal "Automated Process" user - a different execution context
 * entirely - which is NOT subject to the CspLitePortal restriction, so
 * the Contact update can happen there instead.
 *
 * ============================================================================
 * SETUP REQUIRED BEFORE THIS TRIGGER WILL COMPILE
 * ============================================================================
 * Create a Platform Event via Setup > Platform Events > New Platform
 * Event, named exactly:
 *
 *   Label: Document Status Update Event
 *   API Name: Document_Status_Update_Event   (becomes
 *             Document_Status_Update_Event__e automatically)
 *
 * Add these two custom fields on it:
 *   Field Label: Contact Id      | API Name: Contact_Id__c    | Type: Text(18)
 *   Field Label: Field Api Name  | API Name: Field_Api_Name__c | Type: Text(255)
 *
 * Then create this trigger on that Platform Event object (Object:
 * Document_Status_Update_Event__e, Event: after insert).
 *
 * ============================================================================
 * SECURITY
 * ============================================================================
 * Same two checks as before, just re-implemented here since this trigger
 * doesn't have access to the controller's private allow-list:
 *   1. fieldApiName must be in the fixed ALLOWED_FIELDS set below.
 *   2. contactId must match the ContactId of the User who PUBLISHED the
 *      event (event.CreatedById), not just any Id the client sent - this
 *      is what stops one portal user from updating someone else's Contact.
 */
trigger DocumentStatusUpdateEventTrigger on Document_Status_Update_Event__e (after insert) {

    Set<String> allowedFields = new Set<String>{
        // Auto Documents
        'Age_Verification_Back__c', 'Age_Verification_Front__c', 'CBC_Annual__c',
        'Fingerprint_Clearance_Card_Back__c', 'Fingerprint_Clearance_Card_Front__c',
        'Notarized_Criminal_History__c', 'Social_Security_Card_Back__c', 'Social_Security_Card_Front__c',
        // Certifications
        'StatusArticle9__c', 'CPR_Certification_Card__c', 'First_Aid_Certification_Card__c',
        // Driver Documents
        'Driver_s_License__c', 'Liability_Insurance__c', 'Vehicle_Registration__c',
        // Driver Forms / Non-Driver Forms
        'Employee_Vehicle_Checklist_Eng__c', 'Motor_Vehicle_Release_English__c',
        'Transportation_Policy_English__c', 'Employee_Vehicle_Checklist_Spanish__c',
        'Motor_Vehicle_Release_Spanish__c', 'Transportation_Policy_Spanish__c',
        'Non_Driver_Agreement__c', 'Non_Driver_Agreement_Spanish__c',
        // Service Forms
        'DCW_1_Certificate_Status__c', 'DCW_2_Certificate_Status__c', 'HAH_Certificate__c'
    };

    // Look up ContactId for every event publisher in this batch, so we
    // can confirm each event's contactId actually belongs to whoever
    // published it (mirrors validateContactOwnership() from the
    // controller, re-implemented here for the same reason as the
    // allow-list above).
    Set<Id> publisherUserIds = new Set<Id>();
    for (Document_Status_Update_Event__e evt : Trigger.new) {
        publisherUserIds.add(evt.CreatedById);
    }

    Map<Id, Id> userIdToContactId = new Map<Id, Id>();
    for (User u : [SELECT Id, ContactId FROM User WHERE Id IN :publisherUserIds]) {
        userIdToContactId.put(u.Id, u.ContactId);
    }

    List<Contact> contactsToUpdate = new List<Contact>();

    for (Document_Status_Update_Event__e evt : Trigger.new) {
        String contactId = evt.Contact_Id_c__c;
        String fieldApiName = evt.Field_Api_Name__c;

        if (String.isBlank(contactId) || String.isBlank(fieldApiName)) {
            continue;
        }
        if (!allowedFields.contains(fieldApiName)) {
            continue;
        }

        Id ownContactId = userIdToContactId.get(evt.CreatedById);
        if (ownContactId == null || String.valueOf(ownContactId) != contactId) {
            continue;
        }

        Contact con = new Contact(Id = contactId);
        con.put(fieldApiName, 'Pending');
        contactsToUpdate.add(con);
    }

    if (!contactsToUpdate.isEmpty()) {
        // This runs as the Automated Process user (this trigger's own
        // execution context), not as the CspLitePortal publisher - that's
        // what avoids the license restriction.
        update contactsToUpdate;
    }
}