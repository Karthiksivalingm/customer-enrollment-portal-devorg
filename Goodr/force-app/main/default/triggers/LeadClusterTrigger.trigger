trigger LeadClusterTrigger on Lead (
    before insert, before update,
    after insert, after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ClusterRuleEngine.evaluate('Lead', Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            ClusterRuleEngine.evaluate('Lead', Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        // Only reassign team when Cluster or Sales Channel changed
        List<Lead> changed = new List<Lead>();
        for (Lead ld : Trigger.new) {
            if (Trigger.isInsert) {
                changed.add(ld);
            } else {
                Lead old = Trigger.oldMap.get(ld.Id);
                if (ld.Cluster__c       != old.Cluster__c ||
                    ld.Sales_Channel__c != old.Sales_Channel__c) {
                    changed.add(ld);
                }
            }
        }
        if (!changed.isEmpty()) {
            ClusterTeamEngine.assignTeams('Lead', changed);
        }
        LeadConversionHandler.handleConversion(
            Trigger.new,
            Trigger.oldMap
        );
    }
}