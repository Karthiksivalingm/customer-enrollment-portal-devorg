// After the lead is converted, 
// update all its referrals to new account, contact, opp

trigger UpdateReferral on Lead (after update) {
	List<Lead> change_leads = Trigger.new;
    
    for (Lead change_lead: change_leads){
    	if(change_lead.isConverted) {
            List<Referral__c> related_referrals = [SELECT Id, Referral_Account__c, Referral_Contact__c, Referral_Opportunity__c FROM Referral__c WHERE Referral__c = :change_lead.Id];
            for (Referral__c referral: related_referrals) {
                referral.Referral_Account__c = change_lead.ConvertedAccountId;
                referral.Referral_Contact__c = change_lead.ConvertedContactId;
                referral.Referral_Opportunity__c = change_lead.ConvertedOpportunityId;
                update referral;
            }
        }    
    }
}