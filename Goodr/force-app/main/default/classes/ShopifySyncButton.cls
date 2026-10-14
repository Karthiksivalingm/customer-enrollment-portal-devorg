public class ShopifySyncButton {
    
    @AuraEnabled
    public static void recreateRecords(Id accountId) {

        // NEW: Validate Sales_Channel__c on Account, Store Locations and Contacts
        // before starting the async chain — error surfaces cleanly to LWC toast
        List<Account> accountsToCheck = [
            SELECT Id, Name, Sales_Channel__c, RecordType.DeveloperName
            FROM Account
            WHERE Id = :accountId
            OR (ParentId = :accountId AND RecordType.DeveloperName = 'Store_Location')
        ];

        List<Contact> contactsToCheck = [
            SELECT Id, FirstName, LastName, Sales_Channel__c
            FROM Contact
            WHERE AccountId = :accountId
        ];

        List<String> missingChannelNames = new List<String>();

        // Check Account and Store Locations
        for (Account acc : accountsToCheck) {
            if (String.isBlank(acc.Sales_Channel__c)) {
                missingChannelNames.add(acc.Name + ' (Account)');
            }
        }

        // Check Contacts
        for (Contact con : contactsToCheck) {
            if (String.isBlank(con.Sales_Channel__c)) {
                missingChannelNames.add(
                    con.FirstName + ' ' + con.LastName + ' (Contact)'
                );
            }
        }

        if (!missingChannelNames.isEmpty()) {
            throw new AuraHandledException(
                'Please fill in the Sales Channel field before syncing. ' +
                'Missing on: ' + String.join(missingChannelNames, ', ')
            );
        }

        System.enqueueJob(new ShopifyCompanyManualSyncQueueable(accountId));
    }
}