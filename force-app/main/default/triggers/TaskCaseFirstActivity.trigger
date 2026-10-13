/*
 * Compute the number of hours between when the case is created 
 * and the first activity (event or task)
 */ 

trigger TaskCaseFirstActivity on Task (after insert) {
    List<Task> change_tasks = Trigger.new;
    
    // Loop through change tasks
    for (Task change_task: change_tasks){
        // Query the associated case if exist
        List<Case> cases = [SELECT Id, CreatedDate FROM Case WHERE Id = :change_task.WhatId];
        if(cases.size() == 0)
            continue;
        Case the_case = cases[0];
        
        Datetime first_activity = null;
        
        // Query the earliest task
        List<Task> tasks = [SELECT Id, CreatedDate
                            FROM Task WHERE WhatId = :the_case.Id
                            ORDER BY CreatedDate];
        if(tasks.size() > 0)
            first_activity = tasks[0].CreatedDate;
        
        // Query the earliest event
        List<Event> events = [SELECT Id, CreatedDate
                              FROM Event WHERE WhatId = :the_case.Id
                              ORDER BY CreatedDate];
        if(events.size() > 0){
            if(first_activity == null)
                first_activity = events[0].CreatedDate;
            else if (events[0].CreatedDate < first_activity)
                first_activity = events[0].CreatedDate;
        }
        
        // Calculate the number of hours between created and first activity
        Decimal delta_hours = (first_activity.getTime() - the_case.CreatedDate.getTime()) / 1000.0 / 3600;
        the_case.Time_to_First_Response__c = delta_hours;
        update the_case;
    }
}