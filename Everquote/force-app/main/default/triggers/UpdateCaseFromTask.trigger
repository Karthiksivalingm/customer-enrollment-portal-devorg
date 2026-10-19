/* Trigger fires on insert/update/delete Task
 * 1. Last call time of Opp
 * 2. Next due date of Opp
 */

trigger UpdateCaseFromTask on Task (after insert) {
    // Get all insert/update/delete tasks
    List<Task> change_tasks = Trigger.new;
    
    // Loop through change tasks
    for (Task change_task: change_tasks){
        // Query the associated lead
        List<Case> cases = [SELECT Id FROM Case WHERE Id = :change_task.WhatId];
        if(cases.size() == 0)
            continue;
        Case the_case = cases[0];        
        
        // Query call tasks 
        List<Task> call_tasks = [SELECT Id, CallType, CallDurationInSeconds, CreatedDate, Status, CallDisposition 
                                 FROM Task WHERE WhatId = :the_case.Id AND (CallType = 'Inbound' OR CallType = 'Outbound' OR (Subject = 'Inbound Call' AND CallDisposition != 'Transferred') OR Subject = 'Outbound Call')
                                 ORDER BY CreatedDate DESC LIMIT 1];
        
        // Last call time
        if(call_tasks.size() > 0) {
            the_case.Last_Call_Time__c  = call_tasks[0].CreatedDate;
            update the_case;
        }
    }
}