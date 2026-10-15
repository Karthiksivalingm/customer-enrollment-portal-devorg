/**
 * UplinePolicyTriggerHandler
 * ------------------------------------------------------------------
 * When a new Upline_Policy__c is inserted with Reactivated_From__c
 * populated, it inherits Policy_Year__c from the referenced policy
 * instead of starting at 0/1.
 *
 * ASSUMPTION: Reactivated_From__c is a self-lookup on Upline_Policy__c
 * (points to another Upline_Policy__c record).
 */
public with sharing class UplinePolicyTriggerHandler {
    public static void beforeInsert(List<Upline_Policy__c> newList) {
        Set<Id> sourceIds = new Set<Id>();
        for (Upline_Policy__c p : newList) {
            if (p.Reactivated_From__c != null) sourceIds.add(p.Reactivated_From__c);
        }
        if (sourceIds.isEmpty()) return;
        Map<Id, Upline_Policy__c> sourceById = new Map<Id, Upline_Policy__c>([
            SELECT Id, Policy_Year__c
            FROM Upline_Policy__c
            WHERE Id IN :sourceIds
        ]);
        for (Upline_Policy__c p : newList) {
            if (p.Reactivated_From__c != null && sourceById.containsKey(p.Reactivated_From__c)) {
                p.Policy_Year__c = sourceById.get(p.Reactivated_From__c).Policy_Year__c;
            }
        }
    }
}