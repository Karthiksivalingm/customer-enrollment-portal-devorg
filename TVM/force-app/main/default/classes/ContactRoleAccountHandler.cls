public class ContactRoleAccountHandler {

    public static void syncContacts(
        List<Contact> newList,
        List<Contact> oldList,
        Boolean isDelete
    ) {

        Set<Id> accountIds = new Set<Id>();

        if (isDelete) {
            for (Contact c : oldList) {
                if (c.AccountId != null)
                    accountIds.add(c.AccountId);
            }
        } 
        else {
            if (newList != null) {
                for (Contact c : newList) {
                    if (c.AccountId != null)
                        accountIds.add(c.AccountId);
                }
            }

            if (oldList != null) {
                for (Contact c : oldList) {
                    if (c.AccountId != null)
                        accountIds.add(c.AccountId);
                }
            }
        }

        if (accountIds.isEmpty()) return;

        List<Contact> contacts = [
            SELECT Id, AccountId, Contact_Role__c
            FROM Contact
            WHERE AccountId IN :accountIds
            AND Contact_Role__c INCLUDES ('Foundation Primary', 'Foundation Secondary')
        ];

        Map<Id, Id> primaryMap = new Map<Id, Id>();
        Map<Id, Id> secondaryMap = new Map<Id, Id>();

        for (Contact c : contacts) {

            if (c.Contact_Role__c != null) {

                if (c.Contact_Role__c.contains('Foundation Primary')) {
                    primaryMap.put(c.AccountId, c.Id);
                }

                if (c.Contact_Role__c.contains('Foundation Secondary')) {
                    secondaryMap.put(c.AccountId, c.Id);
                }
            }
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Id accId : accountIds) {

            accountsToUpdate.add(new Account(
                Id = accId,
                Primary_Contact__c =
                    primaryMap.containsKey(accId) ? primaryMap.get(accId) : null,
                Secondary_Contact__c =
                    secondaryMap.containsKey(accId) ? secondaryMap.get(accId) : null
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}