public without sharing class ContactDeleteService {
    @AuraEnabled
    public static void deleteContact(Id contactId) {
        try {
            if (contactId == null) {
                throw new AuraHandledException('Contact Id cannot be null.');
            }

            Contact contactToDelete = [
                SELECT Id 
                FROM Contact 
                WHERE Id = :contactId 
                LIMIT 1
            ];
            delete contactToDelete;

        } catch (QueryException e) {
            throw new AuraHandledException('No contact found with the provided Id.');
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting contact: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
}