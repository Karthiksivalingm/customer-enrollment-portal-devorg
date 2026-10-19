// Convert Lead when the field IMHeld updated to True

trigger ConvertLeadWhenIMHeld on Lead (after update) {
    List<Lead> change_leads = Trigger.new;
    
    for (Lead change_lead: change_leads){
        if(!change_lead.isConverted && change_lead.IMHeld__c == true) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(change_lead.id);
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.convertLead(lc);
        }    
    }
}