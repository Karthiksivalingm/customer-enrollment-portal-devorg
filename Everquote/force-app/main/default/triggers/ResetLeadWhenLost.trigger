trigger ResetLeadWhenLost on Lead (before update) {
	List<Lead> change_leads = Trigger.new;
    for (Lead change_lead: change_leads){
        if(change_lead.Status == 'Lost') {
            change_lead.GateKeeperCallCount__c = null;
            change_lead.DMCallCount__c = null;
            change_lead.LastCallDispo__c = null;
        }
    }
}