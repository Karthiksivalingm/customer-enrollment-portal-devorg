trigger TaskTrigger on Task (before insert, before update, after insert, after update) {


    if (Trigger.isBefore) {

        if (Trigger.isInsert) {
            // Formerly: TaskUpdateUserRole trigger (before insert)
            TaskHandler.updateUserRoleAndProfile(Trigger.new);
        }

        if (Trigger.isInsert || Trigger.isUpdate) {
            // Formerly: TaskSetReminder trigger (before insert, before update)
            TaskHandler.setReminderDateTime(Trigger.new);
        }
    }

    if (Trigger.isAfter) {

        if (Trigger.isInsert) {
            // Formerly: TaskLead trigger (after insert)
            TaskHandler.assignLeadOwnerOnFirstCall(Trigger.new);
        }

        if (Trigger.isInsert || Trigger.isUpdate) {
            // Formerly: TaskNotifyCTI trigger (after insert, after update)
            TaskHandler.notifyCTI();
        }
    } 

}