/*
 * Set ReminderDateTime__c to ReminderDateTime to use in reports
 */
trigger TaskSetReminder on Task (before insert, before update) {

    // Get all insert/update tasks
    List<Task> change_tasks = Trigger.new;
    
    // Loop through change tasks
    for (Task change_task: change_tasks){
        change_task.ReminderDateTime__c = change_task.ReminderDateTime;
    }

}