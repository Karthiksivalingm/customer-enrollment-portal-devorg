trigger ContentVersionTrigger on ContentVersion (after update) {
    ContentVersionHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}