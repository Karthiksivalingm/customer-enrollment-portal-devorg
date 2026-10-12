trigger OpportunityClusterTrigger on Opportunity (
    before insert, before update,
    after insert, after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ClusterRuleEngine.evaluate('Opportunity', Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            ClusterRuleEngine.evaluate('Opportunity', Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        List<Opportunity> changed = new List<Opportunity>();
        for (Opportunity opp : Trigger.new) {
            if (Trigger.isInsert) {
                changed.add(opp);
            } else {
                Opportunity old = Trigger.oldMap.get(opp.Id);
                if (opp.Sales_Channel__c != old.Sales_Channel__c ||
                    opp.Cluster__c       != old.Cluster__c) {
                    changed.add(opp);
                }
            }
        }
        if (!changed.isEmpty()) {
            ClusterTeamEngine.assignTeams('Opportunity', changed);
        }
    }
}