public class CaseTeamAssignmentQueueable implements Queueable {

    private Set<Id> caseIds;

    public CaseTeamAssignmentQueueable(Set<Id> caseIds){
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext ctx){
        List<Case> cases = [SELECT Id, OwnerId, Priority, Email_To_Case_Address__c
                            FROM Case
                            WHERE Id IN :caseIds];
        CaseTeamAssignmentService.assignTeamsAndOwner(cases, null);
    }
}