/*
 * Single trigger for the Event object (Salesforce one-trigger-per-object best practice).
 * All logic lives in EventHandler; each former standalone trigger is now one handler method.
 *
 */
trigger EventTrigger on Event (before insert, after insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        EventHandler.handleUpdateUserRole(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        EventHandler.handleCaseFirstActivity(Trigger.new);
        EventHandler.handleLeadFirstActivity(Trigger.new);
        EventHandler.handleConvertLead(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        EventHandler.handleConvertLead(Trigger.new);
    }


}