global class ContactRoleAccountBatch 
implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, AccountId, Contact_Role__c
            FROM Contact
            WHERE Contact_Role__c INCLUDES ('Foundation Primary', 'Foundation Secondary')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Contact> scope) {

        Set<Id> accountIds = new Set<Id>();

        for (Contact c : scope) {
            if (c.AccountId != null)
                accountIds.add(c.AccountId);
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

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch completed');
    }
}