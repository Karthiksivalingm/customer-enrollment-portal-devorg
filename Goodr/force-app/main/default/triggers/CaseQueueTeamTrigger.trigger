trigger CaseQueueTeamTrigger on Case (after insert, after update) {
    
    List<Case> casesToProcess = new List<Case>();
    
    if (Trigger.isInsert) {
        casesToProcess.addAll(Trigger.new);
    }
    
    if (Trigger.isUpdate) {
        for (Case c : Trigger.new) {
            
            Case oldC = Trigger.oldMap.get(c.Id);
            
            if (
                c.OwnerId != oldC.OwnerId ||
                c.Priority != oldC.Priority ||
                c.Email_To_Case_Address__c != oldC.Email_To_Case_Address__c ||
                c.Status != oldC.Status ||
                c.First_Response_Date__c != oldC.First_Response_Date__c   
            ) {
                casesToProcess.add(c);
            }
        }
    }
    
    if (!casesToProcess.isEmpty()) {
        // NEW: Guard against Too Many Queueable Jobs error
        // When trigger fires inside an existing queueable chain,
        // enqueueJob is not allowed — execute directly instead
        if (System.isFuture() || System.isQueueable()) {
            new CaseOrchestratorQueueable(
                casesToProcess,
                Trigger.isInsert ? null : Trigger.oldMap
            ).execute(null);
        } else {
            System.enqueueJob(
                new CaseOrchestratorQueueable(
                    casesToProcess,
                    Trigger.isInsert ? null : Trigger.oldMap
                )
            );
        }
    }
}