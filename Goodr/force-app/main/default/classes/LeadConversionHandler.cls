public with sharing class LeadConversionHandler {
    public static void handleConversion(
        List<Lead> newList,
        Map<Id,Lead> oldMap
    ) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> oppIds     = new Set<Id>();

        for (Lead l : newList) {
            if (oldMap != null &&
                !oldMap.get(l.Id).IsConverted &&
                l.IsConverted) {
                if (l.ConvertedAccountId  != null) accountIds.add(l.ConvertedAccountId);
                if (l.ConvertedContactId  != null) contactIds.add(l.ConvertedContactId);
                if (l.ConvertedOpportunityId != null) oppIds.add(l.ConvertedOpportunityId);
            }
        }

        if (!accountIds.isEmpty()) {
            List<Account> accs = [
                SELECT Id, Cluster__c, Sales_Channel__c, Sector__c
                FROM Account
                WHERE Id IN :accountIds
            ];
            ClusterTeamEngine.assignTeams('Account', accs);

            // No Opp created during conversion — find existing open Opps
            // on the converted Account and assign teams based on Account values
            // CHANGED: Sector__c is synced together with Sales Channel (keeps the dependent
            // picklist valid on the Opportunity)
            List<Opportunity> existingOpps = [
                SELECT Id, Cluster__c, Sales_Channel__c, Sector__c, AccountId
                FROM Opportunity
                WHERE AccountId IN :accountIds
                AND IsClosed = false
            ];
            if (!existingOpps.isEmpty()) {
                Map<Id, Account> accMap = new Map<Id, Account>(accs);
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                for (Opportunity opp : existingOpps) {
                    Account acc = accMap.get(opp.AccountId);
                    if (acc == null) continue;
                    if (opp.Cluster__c       != acc.Cluster__c ||
                        opp.Sales_Channel__c != acc.Sales_Channel__c ||
                        opp.Sector__c        != acc.Sector__c) {
                        opp.Cluster__c       = acc.Cluster__c;
                        opp.Sales_Channel__c = acc.Sales_Channel__c;
                        opp.Sector__c        = acc.Sector__c;
                        oppsToUpdate.add(opp);
                    }
                }
                if (!oppsToUpdate.isEmpty()) {
                    update oppsToUpdate;
                }
                ClusterTeamEngine.assignTeams('Opportunity', existingOpps);
            }
        }

        if (!oppIds.isEmpty()) {
            List<Opportunity> opps = [
                SELECT Id, Cluster__c, Sales_Channel__c
                FROM Opportunity
                WHERE Id IN :oppIds
            ];
            ClusterTeamEngine.assignTeams('Opportunity', opps);
        }

        if (!contactIds.isEmpty()) {
            List<Contact> cons = [
                SELECT Id, Cluster__c, Sales_Channel__c
                FROM Contact
                WHERE Id IN :contactIds
            ];
            ClusterTeamEngine.assignTeams('Contact', cons);
        }
    }
}