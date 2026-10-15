/**
 * PersonalInformationController
 * ------------------------------
 * Powers the "My Personal Information" LWC tab in Experience Cloud.
 * Always resolves to the CURRENT logged-in Experience user's own Contact
 * (via User.ContactId) so one portal user can never read/write another
 * user's record, regardless of what gets passed from the client.
 */
public with sharing class ExperienceUserProfileController {

    // ---- EDIT THIS LIST IF YOUR ORG USES DIFFERENT API NAMES ----
    // Keep this single source of truth in sync with the LWC's FIELDS list.
   private static final List<String> FIELD_API_NAMES = new List<String>{
    'Id',
    'FirstName',
    'MiddleName',
    'LastName',
    'Name',
    'Preferred_Contact_Method__c',
    'Preferred_Language__c',
    'Division__c',
    'Driving_Status__c',    // CORRECT
    'Contract_Type__c',
    'Living_Status__c',
    'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode', 'MailingCountry', 'MobilePhone', 'Email', 'Birthdate','Service__c'
};

    /**
     * Returns the running user's own Contact record with only the
     * whitelisted fields above, respecting FLS/CRUD/sharing (WITH USER_MODE).
     */
   @AuraEnabled(cacheable=true)
public static Contact getMyContact() {

    Id contactId = getRunningUserContactId();

    if(contactId == null){
        throw new AuraHandledException(
            'No Contact is associated with the current user.'
        );
    }

    String fieldList = String.join(FIELD_API_NAMES, ', ');

    String query =
        'SELECT ' + fieldList +
        ' FROM Contact ' +
        'WHERE Id = :contactId ' +
        'LIMIT 1';

    List<Contact> results =
        Database.query(query, AccessLevel.USER_MODE);

    if(results.isEmpty()){
        throw new AuraHandledException(
            'Contact record not found or not accessible.'
        );
    }

    return results[0];
}

    /**
     * Updates the running user's own Contact. The incoming record's Id is
     * ignored/overwritten with the running user's actual ContactId so the
     * update can never target a different record.
     */
    @AuraEnabled
    public static Contact updateMyContact(Contact contactData) {
        Id contactId = getRunningUserContactId();
        if (contactId == null) {
            throw new AuraHandledException('No Contact is associated with the current user.');
        }

        // Force the Id to the running user's own contact - never trust client input here.
        contactData.Id = contactId;

        try {
            Database.update(contactData, AccessLevel.USER_MODE);
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to save your information: ' + e.getDmlMessage(0));
        } catch (System.NoAccessException e) {
            throw new AuraHandledException('You do not have permission to update one or more of these fields.');
        }

        return getMyContact();
    }

    /**
     * Resolves ContactId from the running User record. Works for both
     * Experience Cloud customer/partner community users (who have a
     * ContactId) and is safely null for internal users without one.
     */
    private static Id getRunningUserContactId() {
        List<User> currentUser = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        if (currentUser.isEmpty()) {
            return null;
        }
        return currentUser[0].ContactId;
    }
}