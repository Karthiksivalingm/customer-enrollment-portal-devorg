/* Trigger fires on insert/update/delete Task
 * 1. Last call time of Opp
 * 2. Next due date of Opp
 */

trigger UpdateOppFromTask on Task (after insert, after update, after delete) {
    // Get all insert/update/delete tasks
    List<Task> change_tasks = null;
    if(Trigger.isDelete)
        change_tasks = Trigger.old;
    else
        change_tasks = Trigger.new;
    
    // Loop through change tasks
    for (Integer i = 0; i < change_tasks.size(); i++){
        Task change_task = change_tasks[i];
        if(Trigger.isUpdate & i != change_tasks.size() - 1){
            Task old_task = Trigger.oldMap.get(change_task.Id);
            if(old_task.WhatId != change_task.WhatId){
                continue;
            }
        }
        // Query the associated opp
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id = :change_task.WhatId];
        if(opps.size() == 0)
            continue;
        Opportunity opp = opps[0];        
        
        // Query call tasks 
        List<Task> call_tasks = [SELECT Id, CallType, CallDurationInSeconds, CreatedDate, Status, CallDisposition 
                                 FROM Task WHERE WhatId = :opp.Id AND (CallType = 'Inbound' OR CallType = 'Outbound' OR (Subject = 'Inbound Call' AND CallDisposition != 'Transferred') OR Subject = 'Outbound Call')
                                 ORDER BY CreatedDate];
        
        // Last call time
        if(call_tasks.size() > 0) {
            opp.last_call_time__c = call_tasks[call_tasks.size() - 1].CreatedDate;
            opp.Call_Count__c = call_tasks.size();
        }
                
        // Next due date
        Datetime next_due_date = null;

        // Query due tasks 
        List<Task> due_tasks = [SELECT Id, ActivityDate 
                                FROM Task WHERE WhatId = :opp.Id AND Subject != 'Inbound Call' AND Subject != 'Outbound Call' AND Status != 'Completed' AND ActivityDate != null
                                ORDER BY ActivityDate];
        
        // Update next due date
        if(due_tasks.size() > 0){
            Task due_task = due_tasks[0];
            next_due_date = datetime.newInstance(due_task.ActivityDate.year(), due_task.ActivityDate.month(), due_task.ActivityDate.day(), 0, 0, 0);
        }
        
        // Query due events
        List<Event> events = [SELECT Id, ActivityDateTime
                              FROM Event WHERE WhatId = :opp.Id AND ActivityDateTime >= TODAY
                              ORDER BY ActivityDateTime];
        
        // Update next due date
        if(events.size() > 0){
            if(next_due_date == null)
                next_due_date = events[0].ActivityDateTime;
            else if (events[0].ActivityDateTime < next_due_date)
                next_due_date = events[0].ActivityDateTime;
        }        
        opp.next_due_date__c = next_due_date;
        
        // update opp;           
    }
}