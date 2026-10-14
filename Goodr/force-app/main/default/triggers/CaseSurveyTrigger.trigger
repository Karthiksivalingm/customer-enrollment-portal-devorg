trigger CaseSurveyTrigger on Case (after update) {

    Set<String> closedStatuses = new Set<String>{'Closed','Resolved'};
    Set<Id> caseIds = new Set<Id>();

    for (Case c : Trigger.new) {
        Case oldC = Trigger.oldMap.get(c.Id);

        if (
            closedStatuses.contains(c.Status) &&
            !closedStatuses.contains(oldC.Status) &&
            c.ContactId != null
        ) {
            caseIds.add(c.Id);
        }
    }

    if (!caseIds.isEmpty()) {
        System.enqueueJob(new CaseSurveyQueueable(caseIds));
    }
}