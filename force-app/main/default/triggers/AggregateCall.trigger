/* Trigger fires on insert/update/delete Task
 * 1. Last call time of Lead
 * 2. Gatekeeper dispo and call count
 * 3. Call count, duration
 * 4. Next due date
 * 5. DM dispo and call count
*/

trigger AggregateCall on Task (after insert, after update, after delete) {
    // Get all insert/update/delete tasks
    List<Task> change_tasks = null;
    if(Trigger.isDelete)
        change_tasks = Trigger.old;
    else
        change_tasks = Trigger.new;
    
    // Loop through change tasks
    for (Task change_task: change_tasks){
        // Check if from lead conversion
        if(Trigger.isUpdate){
            Task old_task = Trigger.oldMap.get(change_task.Id);
            if(change_task.WhoId != old_task.WhoId){
                continue;
            }
        }
        
        // Query the associated lead
        List<Lead> leads = [SELECT Id, GateKeeperCallCount__c, LastCallDispo__c, Assigned_Date__c FROM Lead WHERE Id = :change_task.WhoId];
        if(leads.size() == 0)
            continue;
        Lead lead = leads[0];        
        
        // Query call tasks 
        List<Task> call_tasks = [SELECT Id, CallType, CallDurationInSeconds, CreatedDate, Status, CallDisposition 
                                 FROM Task WHERE WhoID = :lead.Id AND (CallType = 'Inbound' OR CallType = 'Outbound' OR (Subject = 'Inbound Call' AND CallDisposition != 'Transferred') OR Subject = 'Outbound Call')
                                 ORDER BY CreatedDate];
        
        // Last call time
        if(call_tasks.size() > 0) {
            lead.Last_Call_Time__c = call_tasks[call_tasks.size() - 1].CreatedDate;
        }
        
        // Gatekeeper call count, dispo
        // Call count, duration
        Integer call_count = 0;
        Integer call_duration_sec = 0;
        Integer gk_call_count = 0;
        Boolean gk_dispo = false;
        Integer dm_call_count = 0;
        Boolean dm_dispo = false;
        
        for (Task call_task: call_tasks){
            Date created_date = call_task.CreatedDate.Date();
            if(created_date >= lead.Assigned_Date__c || lead.Assigned_Date__c == null) {
                call_count += 1;
                if(call_task.CallDurationInSeconds != null) {
                    call_duration_sec += call_task.CallDurationInSeconds;
                }
                
                if(gk_dispo) {
                    gk_call_count += 1;
                }
                else if(call_task.CallDisposition == 'Live Message' || call_task.CallDisposition == 'Spoke to Decision Maker' || call_task.CallDisposition == 'Spoke to Non Decision Maker') {
                    gk_call_count = 1;
                    gk_dispo = true;
                }
                
                if(dm_dispo) {
                    dm_call_count += 1;
                }
                else if(call_task.CallDisposition == 'Spoke to Decision Maker') {
                    dm_call_count = 1;
                    dm_dispo = true;
                }
            }
        }
        Decimal minutes = call_duration_sec / 60.0;
        String call_duration_min = String.valueOf(minutes.setScale(2));
        
        lead.Call_Count__c = call_count;
        lead.Call_Duration_Seconds__c = call_duration_sec;
        lead.Call_Duration_Minutes__c = call_duration_min;
        lead.GateKeeperCallCount__c = gk_call_count;
        lead.DMCallCount__c = dm_call_count;
        
        if(dm_dispo){
            lead.LastCallDispo__c = 'Spoke to DM';
        }
        else if(gk_dispo){
            lead.LastCallDispo__c = 'Gatekeeper';
        }
        else {
            lead.LastCallDispo__c = null;
        }
        
        // Next due date
        Datetime next_due_date = null;

        // Query due tasks 
        List<Task> due_tasks = [SELECT Id, ActivityDate 
                                FROM Task WHERE WhoID = :lead.Id AND Subject != 'Inbound Call' AND Subject != 'Outbound Call' AND Status != 'Completed' AND ActivityDate != null
                                ORDER BY ActivityDate];
        
        // Update next due date
        if(due_tasks.size() > 0){
            Task due_task = due_tasks[0];
            next_due_date = datetime.newInstance(due_task.ActivityDate.year(), due_task.ActivityDate.month(), due_task.ActivityDate.day(), 0, 0, 0);
        }
        
        // Query due events
        List<Event> events = [SELECT Id, ActivityDateTime
                              FROM Event WHERE WhoID = :lead.Id AND ActivityDateTime >= TODAY
                              ORDER BY ActivityDateTime];
        
        // Update next due date
        if(events.size() > 0){
            if(next_due_date == null)
                next_due_date = events[0].ActivityDateTime;
            else if (events[0].ActivityDateTime < next_due_date)
                next_due_date = events[0].ActivityDateTime;
        }        
        lead.Next_Due_Date__c = next_due_date;
        
        update lead;
    }
}