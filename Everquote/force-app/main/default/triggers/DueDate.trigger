trigger DueDate on Event (after insert, after update, after delete) {
    // Get all insert/update/delte events
    List<Event> change_events = null;
    if(Trigger.isDelete)
        change_events = Trigger.old;
    else
        change_events = Trigger.new;
    // Loop through change events
    for (Event change_event: change_events){
        // Query the associated lead
        List<Lead> leads = [SELECT Id FROM Lead WHERE Id = :change_event.WhoId];
        if(leads.size() == 0)
            continue;
        Lead lead = leads[0];
        // Init values
        Datetime next_due_date = null;
        // Query due tasks 
        List<Task> tasks = [SELECT Id, ActivityDate 
                            FROM Task WHERE WhoID = :lead.Id AND Subject != 'Call' AND Status != 'Completed' AND ActivityDate != null
                            ORDER BY ActivityDate];
        // Update next due date
        if(tasks.size() > 0){
            Task task = tasks[0];
            next_due_date = datetime.newInstance(task.ActivityDate.year(), task.ActivityDate.month(), task.ActivityDate.day(), 0, 0, 0);
        }
        // Query due events
        List<Event> events = [SELECT Id, ActivityDateTime
                              FROM  Event WHERE WhoID = :lead.Id AND ActivityDateTime >= TODAY
                              ORDER BY ActivityDateTime];
        // Update next due date
        if(events.size() > 0){
            Event nextEvent = events[0];
            if(next_due_date == null)
                next_due_date = nextEvent.ActivityDateTime;
            else if (nextEvent.ActivityDateTime < next_due_date)
                next_due_date = nextEvent.ActivityDateTime;
        }
        // Update lead
        lead.Next_Due_Date__c = next_due_date;
        update lead;
    }       
}