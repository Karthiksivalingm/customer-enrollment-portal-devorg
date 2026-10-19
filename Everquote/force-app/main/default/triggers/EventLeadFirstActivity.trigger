/*
 * Compute the number of hours between when the lead is created 
 * and the first activity (event or task)
 */ 
trigger EventLeadFirstActivity on Event (after insert) {
	List<Event> change_events = Trigger.new;
    
    // Loop through change events
    for (Event change_event: change_events){
        // Query the associated case if exist
        List<Lead> leads = [SELECT Id, CreatedDate, Assigned_Date__c FROM Lead WHERE Id = :change_event.WhoId];
        if(leads.size() == 0)
            continue;
        Lead the_lead = leads[0];
        
        // Start date
        Datetime start_date = the_lead.CreatedDate;
        if(the_lead.Assigned_Date__c > start_date)
            start_date = the_lead.Assigned_Date__c;
        
        Datetime first_activity = null;
        
        // Query the earliest task
        List<Task> tasks = [SELECT Id, CreatedDate
                            FROM Task WHERE WhoId = :the_lead.Id
                            AND CreatedDate > :start_date
                            AND Subject != 'Lead On Pro. Please Contact!'
                            AND Subject != 'New Lead! Please contact'
                            ORDER BY CreatedDate];
        if(tasks.size() > 0)
            first_activity = tasks[0].CreatedDate;
        
        // Query the earliest event
        List<Event> events = [SELECT Id, CreatedDate
                              FROM Event WHERE WhoId = :the_lead.Id
                              AND CreatedDate > :start_date
                              ORDER BY CreatedDate];
        if(events.size() > 0){
            if(first_activity == null)
                first_activity = events[0].CreatedDate;
            else if (events[0].CreatedDate < first_activity)
                first_activity = events[0].CreatedDate;
        }
		
        if(first_activity == null){
            the_lead.Time_to_First_Response__c = null;
        }
        else {
            // Calculate the number of hours between created and first activity
            Decimal delta_hours = (first_activity.getTime() - start_date.getTime()) / 1000.0 / 3600;
            the_lead.Time_to_First_Response__c = delta_hours;
        }
        update the_lead;
    }
}