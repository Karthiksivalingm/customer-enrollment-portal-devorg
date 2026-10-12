public with sharing class AccountCascadeHandler {
    public static void handle(
        List<Account> newList,
        Map<Id, Account> oldMap
    ) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newList) {
            if (oldMap == null ||
                acc.Cluster__c       != oldMap.get(acc.Id).Cluster__c ||
                acc.Sales_Channel__c != oldMap.get(acc.Id).Sales_Channel__c) {
                accountIds.add(acc.Id);
            }
        }
        if (accountIds.isEmpty()) return;
        List<Account> accounts = [
            SELECT Id, Cluster__c, Sales_Channel__c
            FROM Account
            WHERE Id IN :accountIds
        ];
        // Reassign Account Team
        ClusterTeamEngine.assignTeams('Account', accounts);
        // Sync Opportunities and Contacts
        syncOpportunities(accountIds, accounts);
        syncContacts(accountIds, accounts);
    }

    // EXISTING — completely unchanged
    private static void syncOpportunities(
        Set<Id> accountIds,
        List<Account> accounts
    ) {
        if (accountIds.isEmpty()) return;
        List<Opportunity> opps = [
            SELECT Id, AccountId, IsClosed, Cluster__c, Sales_Channel__c
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
        ];
        if (opps.isEmpty()) return;
        Map<Id, Account> accMap = new Map<Id, Account>(accounts);
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : opps) {
            Account acc = accMap.get(opp.AccountId);
            if (acc == null) continue;
            if (opp.Cluster__c       != acc.Cluster__c ||
                opp.Sales_Channel__c != acc.Sales_Channel__c) {
                opp.Cluster__c       = acc.Cluster__c;
                opp.Sales_Channel__c = acc.Sales_Channel__c;
                oppsToUpdate.add(opp);
            }
        }
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
            ClusterTeamEngine.assignTeams('Opportunity', oppsToUpdate);
        }
    }

    private static void syncContacts(
        Set<Id> accountIds,
        List<Account> accounts
    ) {
        if (accountIds.isEmpty()) return;
        // NOTE: Contact.Cluster__c is a formula field (TEXT(Account.Cluster__c))
        // It is read-only and auto-reflects the Account's Cluster__c.
        // We only sync Sales_Channel__c here — never write Cluster__c on Contact.
        List<Contact> contacts = [
            SELECT Id, AccountId, Sales_Channel__c
            FROM Contact
            WHERE AccountId IN :accountIds
        ];
        if (contacts.isEmpty()) return;
        Map<Id, Account> accMap = new Map<Id, Account>(accounts);
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact con : contacts) {
            Account acc = accMap.get(con.AccountId);
            if (acc == null) continue;
            if (con.Sales_Channel__c != acc.Sales_Channel__c) {
               // con.Sales_Channel__c = acc.Sales_Channel__c;
                contactsToUpdate.add(con);
            }
        }
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
        // Re-query after DML so formula Cluster__c reflects committed Account value
        Set<Id> contactIds = new Map<Id, Contact>(contacts).keySet();
        List<Contact> freshContacts = [
            SELECT Id, AccountId, Sales_Channel__c, Cluster__c
            FROM Contact
            WHERE Id IN :contactIds
        ];
        ClusterTeamEngine.assignTeams('Contact', freshContacts);

        // NEW: Also enqueue Queueable to catch manual Cluster 2/3/4 changes
        // where formula may not have resolved yet in this transaction
        System.enqueueJob(new ContactTeamReassignQueueable(contactIds));
    }
}