/**
 * Recalculates Active_Start_Date__c for all Program Association records of the given Accounts.
 * Rule: records are processed in the order they were created (oldest first).
 * A record that overlaps an earlier record waits until the day after that record ends.
 * Called from RewardAssociationTrigger after update (dates changed), after delete and after undelete.
 */
public with sharing class MRAActiveStartDateHelper {

    public static void recalculate(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        List<Marketing_Reward_Association__c> recs = [
            SELECT Id, Company__c, Effective_Date__c, End_Date__c, Active_Start_Date__c
            FROM Marketing_Reward_Association__c
            WHERE Company__c IN :accountIds
              AND RecordType.DeveloperName = 'Program_Association'
              AND Effective_Date__c != null
              AND End_Date__c != null
            ORDER BY Company__c, CreatedDate ASC, Id ASC];

        Map<Id, List<Marketing_Reward_Association__c>> placedByAccount =
            new Map<Id, List<Marketing_Reward_Association__c>>();
        Set<Id> changedAccounts = new Set<Id>();

        for (Marketing_Reward_Association__c r : recs) {
            if (!placedByAccount.containsKey(r.Company__c)) {
                placedByAccount.put(r.Company__c, new List<Marketing_Reward_Association__c>());
            }
            List<Marketing_Reward_Association__c> placed = placedByAccount.get(r.Company__c);

            Date startDt = r.Effective_Date__c;
            Boolean moved = true;
            while (moved && startDt <= r.End_Date__c) {
                moved = false;
                for (Marketing_Reward_Association__c ex : placed) {
                    if (ex.Active_Start_Date__c > ex.End_Date__c) {
                        continue; // that record is never active, ignore it
                    }
                    if (startDt <= ex.End_Date__c && r.End_Date__c >= ex.Active_Start_Date__c) {
                        startDt = ex.End_Date__c.addDays(1);
                        moved = true;
                    }
                }
            }

            if (r.Active_Start_Date__c != startDt) {
                changedAccounts.add(r.Company__c);
            }
            r.Active_Start_Date__c = startDt;
            placed.add(r);
        }

        if (changedAccounts.isEmpty()) {
            return;
        }

        // Save ALL records of a changed Account together, so the existing
        // "already active" validation doesn't compare them against each other.
        List<Marketing_Reward_Association__c> toUpdate = new List<Marketing_Reward_Association__c>();
        for (Marketing_Reward_Association__c r : recs) {
            if (changedAccounts.contains(r.Company__c)) {
                toUpdate.add(new Marketing_Reward_Association__c(
                    Id = r.Id,
                    Active_Start_Date__c = r.Active_Start_Date__c));
            }
        }
        update toUpdate;
    }
}