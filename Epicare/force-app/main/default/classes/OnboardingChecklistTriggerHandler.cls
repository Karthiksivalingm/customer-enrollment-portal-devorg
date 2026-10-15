public class OnboardingChecklistTriggerHandler {

    public static void updateContactChecklistStatus(List<Onboarding_Checklist__c> records) {

        Set<Id> contactIds = new Set<Id>();

        for (Onboarding_Checklist__c rec : records) {
            if (rec.Agent__c != null) {
                contactIds.add(rec.Agent__c);
            }
        }

        if (contactIds.isEmpty()) {
            return;
        }

        Map<Id, Set<String>> verifiedItemsByContact = new Map<Id, Set<String>>();

        for (Onboarding_Checklist__c rec : [
            SELECT Agent__c,
                   Item_Type__c,
                   Status__c
            FROM Onboarding_Checklist__c
            WHERE Agent__c IN :contactIds
        ]) {

            if (rec.Status__c != 'Verified') {
                continue;
            }

            if (!verifiedItemsByContact.containsKey(rec.Agent__c)) {
                verifiedItemsByContact.put(rec.Agent__c, new Set<String>());
            }

            verifiedItemsByContact.get(rec.Agent__c).add(rec.Item_Type__c);
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Id contactId : contactIds) {

            Set<String> items = verifiedItemsByContact.containsKey(contactId)
                ? verifiedItemsByContact.get(contactId)
                : new Set<String>();

            Contact c = new Contact();
            c.Id = contactId;

            // Base Documents
            c.Base_Documents_Complete__c =
                items.contains('W9') &&
                items.contains('ID Front') &&
                items.contains('ID Back') &&
                items.contains('SSN');

            // Banking
            c.Banking_Complete__c =
                items.contains('Banking Info');

            // License
            c.License_Complete__c =
                items.contains('License Verification');

            // E&O
            c.EO_Complete__c =
                items.contains('E O Insurance');

            // Background
            c.Background_Complete__c =
                items.contains('Background Check');

            // Certifications
            c.Certification_Complete__c =
                items.contains('AML Cert')
                || items.contains('FFM Cert')
                || items.contains('AHIP Cert')
                || items.contains('Carrier Cert');

            contactsToUpdate.add(c);
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}