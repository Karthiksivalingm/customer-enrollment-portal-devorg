/**
 * PolicyYearIncrementBatch
 * ------------------------------------------------------------------
 * Daily job: for every Active Upline_Policy__c, count Commission_Record__c
 * where Status__c = 'Paid', and bump Policy_Year__c once 12 NEW paid
 * records have accumulated since the last time this ran for that policy.
 *
 * RESOLVED (previous version flagged this as needing client input):
 * Upline_Policy__c.Last_Paid_Count_Snapshot__c exists in the schema and
 * is exactly the rolling-window tracking field this needed. Logic now:
 *   newPaidSinceSnapshot = currentPaidCount - Last_Paid_Count_Snapshot__c
 *   yearsToAdd = newPaidSinceSnapshot / 12 (integer division)
 *   if yearsToAdd > 0: Policy_Year__c += yearsToAdd
 *                       Last_Paid_Count_Snapshot__c += yearsToAdd * 12
 * This only advances the snapshot by whole 12-record chunks actually
 * consumed, so partial progress toward the next year isn't lost or
 * double-counted, and running the batch daily is safe/idempotent.
 */
public with sharing class PolicyYearIncrementBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Policy_Year__c, Last_Paid_Count_Snapshot__c
            FROM Upline_Policy__c
            WHERE Status__c = 'Active'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Upline_Policy__c> scope) {
        Set<Id> policyIds = new Set<Id>();
        for (Upline_Policy__c p : scope) policyIds.add(p.Id);

        Map<Id, Integer> paidCountByPolicy = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Upline_Policy__c pol, COUNT(Id) cnt
            FROM Commission_Record__c
            WHERE Upline_Policy__c IN :policyIds
              AND Status__c = 'Paid'
            GROUP BY Upline_Policy__c
        ]) {
            paidCountByPolicy.put((Id) ar.get('pol'), (Integer) ar.get('cnt'));
        }

        List<Upline_Policy__c> toUpdate = new List<Upline_Policy__c>();
        for (Upline_Policy__c p : scope) {
            Integer currentPaidCount = paidCountByPolicy.containsKey(p.Id) ? paidCountByPolicy.get(p.Id) : 0;
            Integer snapshot = p.Last_Paid_Count_Snapshot__c != null ? Integer.valueOf(p.Last_Paid_Count_Snapshot__c) : 0;

            Integer newSinceSnapshot = currentPaidCount - snapshot;
            Integer yearsToAdd = newSinceSnapshot / 12; // integer division = floor

            if (yearsToAdd > 0) {
                Integer currentYear = p.Policy_Year__c != null ? Integer.valueOf(p.Policy_Year__c) : 0;
                toUpdate.add(new Upline_Policy__c(
                    Id = p.Id,
                    Policy_Year__c = currentYear + yearsToAdd,
                    Last_Paid_Count_Snapshot__c = snapshot + (yearsToAdd * 12)
                ));
            }
        }

        if (!toUpdate.isEmpty()) update toUpdate;
    }

    public void finish(Database.BatchableContext bc) {}
}