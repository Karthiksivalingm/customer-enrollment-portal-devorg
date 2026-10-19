// Update Lead fields when there is a Initial Meeting with correct contact

trigger ConvertLead on Event (after insert, after update) {
    List<Event> change_events = Trigger.new;
    
    for (Event change_event: change_events){
    	if(change_event.Subject == 'Initial Meeting' && change_event.Meeting_Result__c == 'Held - Correct Contact') {
            List<Lead> leads = [SELECT Id FROM Lead WHERE Id = :change_event.WhoId LIMIT 1];
            if(leads.size() == 0)
                continue;
            
            Lead lead = leads[0];                       
            lead.IMHeld__c = true;
            lead.InitialMeetingDate__c = change_event.ActivityDate;
            lead.OwnerId = change_event.OwnerId;
            update lead;
        }   
    }
}